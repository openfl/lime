import os
import subprocess
import sys


env = os.environ.copy()
env.pop("DISPLAY", None)
env.pop("WAYLAND_DISPLAY", None)
result = subprocess.run(
    sys.argv[1:], capture_output=True, text=True, env=env, timeout=30
)
sys.stdout.write(result.stdout)
sys.stderr.write(result.stderr)
if result.returncode != 1:
    raise SystemExit(f"Expected startup exit code 1, got {result.returncode}")
if "Could not create a window: lime-test-invalid not available" not in result.stderr:
    raise SystemExit("Startup did not report the window creation error")
