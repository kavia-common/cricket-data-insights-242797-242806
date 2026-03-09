#!/usr/bin/env bash
set -euo pipefail
# Run pytest tests that validate imports and CLI behavior using the workspace venv python
WORKSPACE="${WORKSPACE:-/home/kavia/workspace/code-generation/cricket-data-insights-242797-242806/cricket_rag_cli_app}"
cd "${WORKSPACE}"
VENV_PY="${WORKSPACE}/.venv/bin/python"
if [ ! -x "${VENV_PY}" ]; then echo "venv missing; run deps step" >&2; exit 2; fi
mkdir -p tests
cat > tests/test_basic.py <<'EOF'
import importlib
import sys
import subprocess
import os
import pytest

def test_imports():
    for m in ('openai','pandas','numpy','typer'):
        importlib.import_module(m)
    try:
        importlib.import_module('dotenv')
    except Exception:
        pytest.skip('python-dotenv not installed')

def test_chromadb_optional():
    try:
        importlib.import_module('chromadb')
    except Exception:
        pytest.skip('chromadb not installed')

def test_cli_runs():
    # Ensure we don't leak any OPENAI_API_KEY into the child process env unless explicitly set
    env = {k: v for k, v in os.environ.items() if k not in ('OPENAI_API_KEY',)}
    # run the module using the same python interpreter; pytest under venv ensures sys.executable is the venv python
    r = subprocess.run([sys.executable, '-m', 'cricket_rag', 'info'], capture_output=True, text=True, timeout=10, env=env)
    assert r.returncode == 0
    assert 'WORKSPACE=' in r.stdout
    assert ('OPENAI_API_KEY=set' in r.stdout) or ('OPENAI_API_KEY=unset' in r.stdout)
EOF

# Run pytest using the venv python to ensure tests execute inside the same venv
"${VENV_PY}" -m pytest -q tests
