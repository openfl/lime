#!/usr/bin/env python3
"""Builds the frame loop bench against several Limes and prints what each measured, side by side.

    python run.py --build 8.3.2=C:\\haxelib-8.3.2 --build develop=C:\\haxelib-develop,bench_84 \\
        --build branch=C:\\haxelib-branch,bench_84,bench_request --targets neko,hl,windows --runs 5

Each --build is a name, the haxelib repository whose `lime` is the one to measure, and the defines
that Lime's API allows: `bench_84` where it has frame profiles, `bench_request` where it has
Application.requestFrame(). The builds are run in turn, round after round, so that whatever else
the machine is doing falls on all of them alike. Each figure is the median of the runs, with the
least and the most.
"""

import argparse
import json
import os
import shutil
import statistics
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def build(name, repository, defines, target, work):
    folder = os.path.join(work, name)
    os.makedirs(folder, exist_ok=True)
    shutil.copy(os.path.join(HERE, "project.xml"), folder)
    if os.path.isdir(os.path.join(folder, "src")):
        shutil.rmtree(os.path.join(folder, "src"))
    shutil.copytree(os.path.join(HERE, "src"), os.path.join(folder, "src"))

    environment = dict(os.environ, HAXELIB_PATH=repository)
    command = ["haxelib", "run", "lime", "build", target, "-release", "-nocolor"] + ["-D" + define for define in defines]
    result = subprocess.run(command, cwd=folder, env=environment, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

    if result.returncode != 0 and os.path.isdir(os.path.join(folder, "bin", target)):
        # What an earlier build left can stop the link on C++, so it is made again from nothing
        sys.stderr.write("building %s for %s again from nothing\n" % (name, target))
        shutil.rmtree(os.path.join(folder, "bin", target))
        result = subprocess.run(command, cwd=folder, env=environment, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

    if result.returncode != 0:
        sys.stderr.write(result.stdout[-3000:])
        raise SystemExit("building %s for %s failed" % (name, target))

    return os.path.join(folder, "bin", target, "bin")


def run(folder, timeout):
    executable = os.path.join(folder, "FrameLoopBench.exe" if os.name == "nt" else "FrameLoopBench")

    try:
        result = subprocess.run([executable], cwd=folder, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=timeout)
    except subprocess.TimeoutExpired:
        return None

    measures = {}
    finished = False

    for line in result.stdout.splitlines():
        parts = line.split()
        if line.strip() == "BENCH done":
            finished = True
        elif len(parts) == 3 and parts[0] == "BENCH":
            try:
                measures[parts[1]] = float(parts[2])
            except ValueError:
                pass

    return measures if finished else None


def number(value):
    if abs(value) >= 100:
        return "%.0f" % value
    if abs(value) >= 10:
        return "%.1f" % value
    return "%.2f" % value


def cell(values):
    if not values:
        return ""
    return "%s (%s to %s)" % (number(statistics.median(values)), number(min(values)), number(max(values)))


def table(target, names, results):
    keys = []
    for name in names:
        for measures in results[target][name]:
            for key in measures:
                if key not in keys:
                    keys.append(key)

    lines = ["### %s" % target, "", "| Measure | " + " | ".join(names) + " |", "| --- |" + " --- |" * len(names)]

    for key in keys:
        cells = [cell([measures[key] for measures in results[target][name] if key in measures]) for name in names]
        lines.append("| `%s` | %s |" % (key, " | ".join(cells)))

    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--build", action="append", required=True, metavar="NAME=HAXELIB[,DEFINE...]")
    parser.add_argument("--targets", default="neko,hl,windows")
    parser.add_argument("--runs", type=int, default=5)
    parser.add_argument("--work", default=os.path.join(HERE, "bin"), help="where each build is made")
    parser.add_argument("--out", default=None, help="a JSON file for every run's figures")
    parser.add_argument("--timeout", type=int, default=400)
    arguments = parser.parse_args()

    builds = []
    for value in arguments.build:
        name, rest = value.split("=", 1)
        parts = rest.split(",")
        builds.append((name, parts[0], parts[1:]))

    names = [name for name, _, _ in builds]
    targets = arguments.targets.split(",")
    results = {target: {name: [] for name in names} for target in targets}

    for target in targets:
        folders = {}
        for name, repository, defines in builds:
            sys.stderr.write("building %s for %s\n" % (name, target))
            folders[name] = build(name, repository, defines, target, arguments.work)

        for round_number in range(arguments.runs):
            for name in names:
                sys.stderr.write("%s, %s, run %d of %d\n" % (target, name, round_number + 1, arguments.runs))
                measures = run(folders[name], arguments.timeout)

                if measures is None:
                    sys.stderr.write("  did not finish, so the run is left out\n")
                else:
                    results[target][name].append(measures)

            if arguments.out:
                with open(arguments.out, "w") as output:
                    json.dump(results, output, indent=1)

    for target in targets:
        print(table(target, names, results))


if __name__ == "__main__":
    main()
