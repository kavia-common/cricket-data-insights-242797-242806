#!/usr/bin/env bash
set -euo pipefail

# Workspace from container info, allow override via env
WORKSPACE="${WORKSPACE:-/home/kavia/workspace/code-generation/cricket-data-insights-242797-242806/cricket_rag_cli_app}"
mkdir -p "${WORKSPACE}" && cd "${WORKSPACE}"

# minimal env example
[ -f .env.example ] || cat > .env.example <<'EOF'
# Copy to .env and set your key
# OPENAI_API_KEY=sk-...
EOF

# minimal build metadata
[ -f pyproject.toml ] || cat > pyproject.toml <<'EOF'
[build-system]
requires = ["setuptools", "wheel"]
build-backend = "setuptools.build_meta"
EOF

# package
mkdir -p cricket_rag
if [ ! -f cricket_rag/__main__.py ]; then
  cat > cricket_rag/__main__.py <<'PY'
import os
import typer

# Optional dotenv loading when explicitly enabled by env or marker file
if os.environ.get('CRICKET_RAG_LOAD_ENV') == 'true' or os.path.exists(os.path.join(os.getcwd(), '.env.enable')):
    try:
        from dotenv import load_dotenv
        load_dotenv()
    except Exception:
        pass

app = typer.Typer()

@app.command()
def info():
    openai_set = 'set' if os.environ.get('OPENAI_API_KEY') else 'unset'
    typer.echo(f'WORKSPACE={os.environ.get("WORKSPACE") or "<unset>"}')
    typer.echo(f'OPENAI_API_KEY={openai_set}')

if __name__ == '__main__':
    app()
PY
fi

# start.sh: discover workspace at runtime and exec venv python correctly
[ -f start.sh ] || cat > start.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="${WORKSPACE:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
cd "${WORKSPACE}"
PYBIN="${WORKSPACE}/.venv/bin/python"
if [ ! -x "${PYBIN}" ]; then
  echo "Error: .venv missing or incomplete. Run './install.sh' to install dependencies." >&2
  exit 2
fi
exec "${PYBIN}" -m cricket_rag info
SH
chmod +x start.sh

# Makefile
[ -f Makefile ] || cat > Makefile <<'MK'
.PHONY: install run test
install:
	./install.sh
run:
	./start.sh
test:
	./test.sh
MK

# install shim (dependencies step will replace with real installer)
[ -f install.sh ] || cat > install.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
echo "Run './install' via dependencies step: ./deps-install.sh or follow README" >&2
exit 2
SH
chmod +x install.sh

# test runner
[ -f test.sh ] || cat > test.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="${WORKSPACE:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
cd "${WORKSPACE}"
if [ ! -x ".venv/bin/python" ]; then
  echo "Error: .venv not found; run ./install.sh" >&2
  exit 2
fi
# Activate if present for convenience; pytest will run under venv
. .venv/bin/activate
pytest -q
SH
chmod +x test.sh

# lightweight README marker
[ -f README.md ] || cat > README.md <<'EOF'
Minimal cricket_rag CLI. Use './install.sh' to install dependencies (created by dependency step). Run './start.sh' to run the info command.
EOF

# ensure package dir is a package for older tools
touch cricket_rag/__init__.py

# Success message minimal (kept quiet per optimization guidance)
