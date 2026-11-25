"""Run some of the unit tests many times and count the failures of each test.

Timing tests that fail now and then on CI runners rarely fail twice in a row,
so a single run says little. This builds the tests once, runs them over and
over, and prints how often each test failed, with the first few messages.

    python soak.py --runs 20
    python soak.py --runs 20 --busy 32
    python soak.py --runs 20 --stall-process 300
    python soak.py --runs 20 --stall-thread 60 --no-build

--busy starts that many processes that spin, as other jobs do on a shared
runner. --stall-process stops the whole test process for that many
milliseconds every 1 to 3 s, as the macOS runners do now and then.
--stall-thread (Windows only) stops one of the test process's threads at a
time, chosen at random, which delays a mixer or decoder thread on its own
while the rest of the process runs on.

ALSOFT_DRIVERS is set to "null", as on CI, unless it is set already.
"""

import argparse
import collections
import os
import random
import re
import signal
import subprocess
import sys
import threading
import time

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_PATTERN = r"media\.(AudioSourceTest|VideoSourceTest|OpenALTest)"


def find_executable(target):
    names = ["TestMain.exe", "TestMain"]
    root = os.path.join(HERE, "bin")

    for top, dirs, files in os.walk(root):
        # A macOS bundle keeps its executable in Contents/MacOS
        for name in names:
            if name in files:
                path = os.path.join(top, name)
                if os.access(path, os.X_OK) and target in os.path.relpath(path, root).split(os.sep)[0]:
                    return path

    return None


def build(target, pattern, extra):
    command = ["lime", "build", target, "-release", "-nocolor", "-DUTEST_PATTERN=" + pattern] + extra
    print("Building: " + " ".join(command), flush=True)

    if sys.platform == "win32":
        # lime is a batch file, run by cmd, which would take the | in a pattern
        # as a pipe unless it is quoted
        line = " ".join('"%s"' % part if re.search(r'[|&<>^()\s]', part) else part for part in command)
        subprocess.run(line, cwd=HERE, check=True, shell=True)
    else:
        subprocess.run(command, cwd=HERE, check=True)


def busy_loop():
    while True:
        pass


class Staller:
    """Stops the test process, or one of its threads, now and then."""

    def __init__(self, pid, process_ms, thread_ms):
        self.pid = pid
        self.process_ms = process_ms
        self.thread_ms = thread_ms
        self.stopped = threading.Event()
        self.count = 0
        self.thread = threading.Thread(target=self.run, daemon=True)

    def start(self):
        self.thread.start()

    def stop(self):
        self.stopped.set()
        self.thread.join()

    def run(self):
        while not self.stopped.wait(random.uniform(1, 3) if self.process_ms else random.uniform(0.5, 1.5)):
            try:
                if self.process_ms:
                    self.stall_process(self.process_ms / 1000)
                if self.thread_ms:
                    self.stall_thread(self.thread_ms / 1000)
                self.count += 1
            except OSError:
                return

    def stall_process(self, seconds):
        if sys.platform == "win32":
            import ctypes
            ntdll = ctypes.WinDLL("ntdll")
            kernel32 = ctypes.WinDLL("kernel32")
            handle = kernel32.OpenProcess(0x0800, False, self.pid)  # PROCESS_SUSPEND_RESUME
            if not handle:
                raise OSError("cannot open the test process")
            try:
                ntdll.NtSuspendProcess(handle)
                time.sleep(seconds)
                ntdll.NtResumeProcess(handle)
            finally:
                kernel32.CloseHandle(handle)
        else:
            os.kill(self.pid, signal.SIGSTOP)
            time.sleep(seconds)
            os.kill(self.pid, signal.SIGCONT)

    def stall_thread(self, seconds):
        import ctypes
        from ctypes import wintypes

        kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)

        class THREADENTRY32(ctypes.Structure):
            _fields_ = [
                ("dwSize", wintypes.DWORD),
                ("cntUsage", wintypes.DWORD),
                ("th32ThreadID", wintypes.DWORD),
                ("th32OwnerProcessID", wintypes.DWORD),
                ("tpBasePri", wintypes.LONG),
                ("tpDeltaPri", wintypes.LONG),
                ("dwFlags", wintypes.DWORD),
            ]

        kernel32.CreateToolhelp32Snapshot.restype = wintypes.HANDLE
        snapshot = kernel32.CreateToolhelp32Snapshot(0x4, 0)  # TH32CS_SNAPTHREAD
        threads = []
        entry = THREADENTRY32()
        entry.dwSize = ctypes.sizeof(THREADENTRY32)

        try:
            more = kernel32.Thread32First(snapshot, ctypes.byref(entry))
            while more:
                if entry.th32OwnerProcessID == self.pid:
                    threads.append(entry.th32ThreadID)
                more = kernel32.Thread32Next(snapshot, ctypes.byref(entry))
        finally:
            kernel32.CloseHandle(snapshot)

        if not threads:
            raise OSError("the test process has no threads")

        kernel32.OpenThread.restype = wintypes.HANDLE
        handle = kernel32.OpenThread(0x0002, False, random.choice(threads))  # THREAD_SUSPEND_RESUME
        if not handle:
            return
        try:
            if kernel32.SuspendThread(handle) != 0xFFFFFFFF:
                time.sleep(seconds)
                kernel32.ResumeThread(handle)
        finally:
            kernel32.CloseHandle(handle)


def run_once(executable, timeout, process_ms, thread_ms):
    """Runs the tests, returning the output and whether they finished in time."""
    process = subprocess.Popen([executable], cwd=os.path.dirname(executable), stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT, text=True, errors="replace")
    staller = None
    if process_ms or thread_ms:
        staller = Staller(process.pid, process_ms, thread_ms)
        staller.start()

    lines = []
    reader = threading.Thread(target=lambda: lines.extend(process.stdout), daemon=True)
    reader.start()

    try:
        process.wait(timeout)
        finished = True
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait()
        finished = False

    if staller:
        staller.stop()
    reader.join(5)
    return "".join(lines), finished


def parse(output, finished):
    """The tests that failed in one run, each with its first message."""
    failed = {}

    if not finished:
        started = re.findall(r"^Running (\S+)", output, re.M)
        failed[(started[-1] if started else "?") + " (hung)"] = "timed out"
        return failed

    if "results:" not in output:
        failed["(crashed)"] = output.strip().splitlines()[-1] if output.strip() else "no output"
        return failed

    report = output[output.index("results:"):]
    suite = None
    test = None

    for line in report.splitlines():
        if re.match(r"^\S+\.\S+$", line.strip()) and not line.startswith(" "):
            suite = line.strip()
        else:
            match = re.match(r"^  (\w+): (FAILURE|ERROR|WARNING)", line)
            if match:
                test = suite + "." + match.group(1)
                failed.setdefault(test, match.group(2))
            elif test and line.startswith("    ") and failed.get(test) in ("FAILURE", "ERROR", "WARNING"):
                failed[test] = line.strip()

    return failed


def timing(output):
    """Per test, how many of its timing attempts were disturbed, and whether it measured nothing."""
    disturbed = collections.Counter()
    unmeasured = set()
    test = None

    for line in output.splitlines():
        match = re.match(r"^Running (\S+)", line)
        if match:
            test = match.group(1)
        elif line.startswith("Timing attempt ") and " was disturbed" in line:
            disturbed[test] += 1
        elif "Timing not measured" in line:
            unmeasured.add(test)

    return disturbed, unmeasured


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--target", default="neko", help="the Lime target to build and run (default neko)")
    parser.add_argument("--pattern", default=DEFAULT_PATTERN, help="UTEST_PATTERN, the tests to run")
    parser.add_argument("--runs", type=int, default=10)
    parser.add_argument("--busy", type=int, default=0, help="processes that spin while the tests run")
    parser.add_argument("--stall-process", type=int, default=0, metavar="MS")
    parser.add_argument("--stall-thread", type=int, default=0, metavar="MS")
    parser.add_argument("--timeout", type=float, default=900, help="seconds before a run counts as hung")
    parser.add_argument("--no-build", action="store_true", help="run what was built last")
    parser.add_argument("--exe", help="run this TestMain instead of building one")
    parser.add_argument("--define", action="append", default=[], help="another -D define for the build")
    parser.add_argument("--logs", metavar="DIR", help="keep the whole output of each failing run here")
    args = parser.parse_args()

    if args.stall_thread and sys.platform != "win32":
        parser.error("--stall-thread is only available on Windows")

    os.environ.setdefault("ALSOFT_DRIVERS", "null")

    if args.exe:
        executable = os.path.abspath(args.exe)
    else:
        if not args.no_build:
            build(args.target, args.pattern, ["-D" + define for define in args.define])
        executable = find_executable(args.target)

    if executable is None:
        sys.exit("No TestMain was found under bin/ for " + args.target)

    import multiprocessing
    spinners = [multiprocessing.Process(target=busy_loop, daemon=True) for i in range(args.busy)]
    for spinner in spinners:
        spinner.start()

    failures = collections.Counter()
    messages = collections.defaultdict(list)
    disturbances = collections.Counter()
    unmeasured = collections.Counter()
    clean = 0

    try:
        for run in range(args.runs):
            began = time.time()
            output, finished = run_once(executable, args.timeout, args.stall_process, args.stall_thread)
            failed = parse(output, finished)
            disturbed, missed = timing(output)
            disturbances.update(disturbed)
            unmeasured.update(missed)
            if not failed:
                clean += 1
            elif args.logs:
                os.makedirs(args.logs, exist_ok=True)
                with open(os.path.join(args.logs, "run-%d.txt" % (run + 1)), "w", encoding="utf-8") as log:
                    log.write(output)
            for test, message in failed.items():
                failures[test] += 1
                if len(messages[test]) < 3:
                    messages[test].append(message)
            summary = ", ".join(sorted(failed)) if failed else "passed"
            print("Run %d/%d (%.0f s): %s" % (run + 1, args.runs, time.time() - began, summary), flush=True)
    finally:
        for spinner in spinners:
            spinner.terminate()

    print()
    print("%d of %d runs passed" % (clean, args.runs))
    for test, count in failures.most_common():
        print("%3d  %s" % (count, test))
        for message in messages[test]:
            print("       " + message)

    if disturbances:
        # Undisturbed.hx repeats a timing measurement that a stall disturbed, and
        # reports one it could never take undisturbed as not measured
        print()
        print("Timing attempts disturbed, and runs where a test measured nothing:")
        for test, count in disturbances.most_common():
            print("%3d  %3d  %s" % (count, unmeasured[test], test))


if __name__ == "__main__":
    main()
