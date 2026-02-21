.PHONY: ci test-all lint lint-py lint-ui lint-misc lint-scripts build-ui watch-ui local-check-scripts check-scripts check-ts-rules check-non-ascii repomix loc

# -----------------------------------------------------------------------------
# Cross-platform development notes (Windows / macOS / Linux)
#
# This repository runs most Python tasks from a local virtual environment (venv).
# IMPORTANT: Do not rely on shell-specific "activate" scripts from Make targets.
# Instead, we call the venv Python executable directly, which works on both
# Unix-like systems and Windows.
#
# Quick setup (macOS/Linux):
#   python3.10 -m venv venv
#   ./venv/bin/python -m pip install -U pip
#   ./venv/bin/python -m pip install -r requirements.txt
#
# Quick setup (Windows PowerShell):
#   py -3.10 -m venv venv
#   .\venv\Scripts\python.exe -m pip install -U pip
#   .\venv\Scripts\python.exe -m pip install -r requirements.txt
# -----------------------------------------------------------------------------

ifeq ($(OS),Windows_NT)
VENV_PY := venv/Scripts/python.exe
else
VENV_PY := venv/bin/python
endif

# Prefer the local venv if present; otherwise fall back to system Python.
# You can always override explicitly, e.g.:
#   make ci PYTHON=python
#   make ci PYTHON=venv/bin/python
ifneq ("$(wildcard $(VENV_PY))","")
PYTHON ?= $(VENV_PY)
else
PYTHON ?= python
endif

# CI: Execution of all checks and tests via Python script
ci: lint

build-ui:
	npm run build

watch-ui:
	npm run dev

lint:
	@echo "Running linting (ruff)..."
	$(PYTHON) -m ruff format .
	$(PYTHON) -m ruff check . --fix

repomix:
	$(PYTHON) scripts/generate_repomix.py

repomix-%:
	$(PYTHON) scripts/generate_repomix.py repomix-$*
