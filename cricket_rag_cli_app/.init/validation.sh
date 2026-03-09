#!/usr/bin/env bash
set -euo pipefail
# validation - verify imports, run tests and run start script (STOP N/A for CLI)
WORKSPACE="${WORKSPACE:-/home/kavia/workspace/code-generation/cricket-data-insights-242797-242806/cricket_rag_cli_app}"
cd "${WORKSPACE}"
VENV_PY="${WORKSPACE}/.venv/bin/python"
if [ ! -x "${VENV_PY}" ]; then echo 'venv python missing; run deps-001' >&2; exit 2; fi
# Import checks
echo "---import-check-start---"
"${VENV_PY}" - <<'PY'
import importlib.util as u
mods = ['openai','pandas','numpy','typer']
for m in mods:
    spec = u.find_spec(m)
    print(f"import_ok:{m}" if spec else f"import_fail:{m}")
try:
    importlib_dotenv = u.find_spec('dotenv')
    print('import_ok:python-dotenv' if importlib_dotenv else 'import_skip:python-dotenv')
except Exception:
    print('import_skip:python-dotenv')
PY
echo "---import-check-end---"
# Run pytest
echo "---pytest-start---"
"${VENV_PY}" -m pytest -q || { echo 'pytest failed' >&2; exit 3; }
echo "---pytest-end---"
# Run start.sh (CLI) and capture output
if [ ! -x ./start.sh ]; then
  # Make start.sh executable if present but not executable
  if [ -f ./start.sh ]; then chmod +x ./start.sh; fi
fi
if [ ! -x ./start.sh ]; then
  echo 'start.sh missing or not executable' >&2
  exit 4
fi
echo "---start-sh-output-start---"
./start.sh 2>&1 | sed -n '1,200p'
echo "---start-sh-output-end---"
# No long-running service started by this CLI; STOP step is N/A for CLI-only validation
echo "Validation complete: CLI executed and exited; no long-running process to stop."
exit 0
