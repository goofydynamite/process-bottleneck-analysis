"""Run everything: generate data, run SQL, execute the notebook."""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
STEPS = ["src/generate_data.py", "src/run_sql.py", "src/make_notebook.py"]

for step in STEPS:
    print(f"\n=== {step} ===")
    subprocess.run([sys.executable, str(ROOT / step)], check=True, cwd=ROOT)
print("\nDone.")
