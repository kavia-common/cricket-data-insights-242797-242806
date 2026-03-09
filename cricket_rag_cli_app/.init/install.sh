#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="${WORKSPACE:-/home/kavia/workspace/code-generation/cricket-data-insights-242797-242806/cricket_rag_cli_app}"
mkdir -p "${WORKSPACE}/logs" && cd "${WORKSPACE}"
# Ensure python3-venv available; only install if import fails
if ! python3 -c "import venv" >/dev/null 2>&1; then
  sudo apt-get update -qq && sudo apt-get install -y --no-install-recommends python3-venv -qq
fi
# Create venv if missing
if [ ! -d .venv ]; then
  python3 -m venv .venv
fi
VENV_PY="${WORKSPACE}/.venv/bin/python"
VENV_PIP="${WORKSPACE}/.venv/bin/pip"
# Upgrade pip/setuptools/wheel and capture log
if ! "${VENV_PIP}" install --upgrade pip setuptools wheel >"${WORKSPACE}/logs/pip-upgrade.log" 2>&1; then
  echo "Failed to upgrade pip in venv; see ${WORKSPACE}/logs/pip-upgrade.log" >&2
  exit 3
fi
# Install required packages (prefer binary wheels) and capture log
if ! "${VENV_PIP}" install --prefer-binary chromadb openai pandas numpy python-dotenv typer pytest >"${WORKSPACE}/logs/pip-install.log" 2>&1; then
  echo "pip install failed. See ${WORKSPACE}/logs/pip-install.log for details" >&2
  if grep -qi chromadb "${WORKSPACE}/logs/pip-install.log" >/dev/null 2>&1; then
    echo "Note: chromadb build issues may require Rust or a compatible wheel; see pip log." >&2
  fi
  exit 4
fi
# Verify imports using portable python checks
MISSING=()
for mod in openai pandas numpy typer pytest python_dotenv; do
  PYCODE="import importlib,sys; import importlib.util as u; sys.exit(0) if u.find_spec('${mod//_/.}') else sys.exit(1)"
  if ! "${VENV_PY}" -c "$PYCODE" >/dev/null 2>&1; then
    MISSING+=("${mod}")
  fi
done
# chromadb optional check
if ! "${VENV_PY}" -c "import importlib.util as u,sys; sys.exit(0) if u.find_spec('chromadb') else sys.exit(2)" >/dev/null 2>&1; then
  echo "Warning: chromadb not importable in venv; optional features may be limited" >&2
fi
if [ ${#MISSING[@]} -ne 0 ]; then
  echo "Critical Python modules failed to import: ${MISSING[*]}. Check ${WORKSPACE}/logs/pip-install.log" >&2
  exit 5
fi
# Success marker
"${VENV_PY}" -c "print('deps_ok')"
