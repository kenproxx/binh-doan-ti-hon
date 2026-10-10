"""Run the complete offline suite, retaining logs and rejecting Godot script errors."""
import os
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
LOGS = ROOT / "build" / "test-results"
LOGS.mkdir(parents=True, exist_ok=True)
(ROOT / "build" / ".gdignore").touch()
GODOT = os.environ.get("GODOT_BIN", "godot")
commands = [("data", [sys.executable, "-m", "unittest", "discover", "-s", "tests", "-p", "test_*.py"])]
commands += [(name, [GODOT, "--headless", "--path", str(ROOT), "--script", f"tests/test_{name}.gd"])
             for name in ["audio", "profile", "battle", "objectives", "ui", "acceptance"]]
failed = []
for name, command in commands:
    try:
        result = subprocess.run(command, cwd=ROOT, text=True, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, timeout=600)
        output = result.stdout
        passed = result.returncode == 0 and not any(
            line.startswith(("SCRIPT ERROR:", "ERROR:", "FAIL:")) for line in output.splitlines())
    except (OSError, subprocess.TimeoutExpired) as error:
        output, passed = str(error), False
    (LOGS / f"{name}.log").write_text(output)
    print(f"{name}: {'PASS' if passed else 'FAIL'}", flush=True)
    if not passed:
        failed.append(name)
        print(output[-4000:], flush=True)
print(f"Suite: {len(commands)-len(failed)}/{len(commands)} passed", flush=True)
sys.exit(bool(failed))
