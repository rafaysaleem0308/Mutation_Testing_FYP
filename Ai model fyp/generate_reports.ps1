param()

# PowerShell script to create venv, install dev deps, run pytest and mutmut, and collect reports
Set-StrictMode -Version Latest

$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
Push-Location $root

if (-Not (Test-Path -Path .venv)) {
    python -m venv .venv
}

. .venv\Scripts\Activate.ps1

python -m pip install --upgrade pip
python -m pip install -r requirements-dev.txt

# Run pytest (coverage HTML configured in setup.cfg)
python -m pytest

# Run mutmut baseline
python -m mutmut run --paths ai_analysis.py
python -m mutmut results
python -m mutmut html

# Move mutmut HTML to reports/mutation_baseline
$out = Join-Path $root "..\reports\mutation_baseline"
if (-Not (Test-Path $out)) { New-Item -ItemType Directory -Force -Path $out | Out-Null }
if (Test-Path .mutmut-cache\html) {
    Remove-Item -Recurse -Force (Join-Path $out '*') -ErrorAction SilentlyContinue
    Move-Item -Force .mutmut-cache\html\* $out
}

Pop-Location

Write-Host "Reports generated. Coverage: ..\reports\baseline_coverage  Mutmut: ..\reports\mutation_baseline"
