# AI Expense Planner — Flask API + Mutation Testing Assignment

This directory contains the **Flask API backend** for the AI Expense Planner project, enhanced with comprehensive **mutation testing analysis and reports**.

## Project Structure

```
Ai model fyp/
├── README.md (this file)
├── QUICK_START.md
├── app.py                          # Main Flask API
├── ai_analysis.py                  # [MUTATION TEST TARGET] Text parsing logic
├── config.py                       # Configuration
├── model_trainer.py               # ML model training
├── requirements.txt               # Production dependencies
├── requirements-dev.txt           # Development + testing dependencies
├── setup.cfg                      # Pytest configuration
├── generate_reports.ps1           # Script to automate coverage & mutmut runs
├── run_tests.py                   # Fallback test runner (no pytest required)
├── tests/
│   ├── __init__.py
│   └── test_analyze_user_input.py # [24 unit tests for ai_analysis.py]
├── trained_models/
│   ├── trained_data.json
│   ├── meal_model.pkl
│   ├── laundry_model.pkl
│   └── maintenance_model.pkl
└── kaggle_data/                   # Raw datasets (Git LFS)
    ├── global-food-prices/
    ├── personal-expense-classification-dataset/
    └── supermart-grocery-sales-retail-analytics-dataset/
```

---

## Setup Instructions

### Prerequisites
- **Python:** 3.8 or higher
- **pip:** Latest version
- **Virtual Environment:** venv (recommended)

### Quick Start (5 minutes)

```powershell
# 1. Create virtual environment
python -m venv .venv

# 2. Activate venv
.venv\Scripts\Activate.ps1        # Windows PowerShell
# .venv\Scripts\activate           # Windows CMD
# source .venv/bin/activate       # Linux/Mac

# 3. Install dependencies
pip install -r requirements.txt

# 4. Run Flask API
python app.py

# API available at: http://localhost:5000
```

---

## Mutation Testing Assignment

This module (`ai_analysis.py`) is the subject of a **comprehensive mutation testing analysis** for the Final Year Project.

### Quick Mutation Testing Setup

```powershell
# 1. Install dev dependencies (includes pytest, mutmut, coverage)
pip install -r requirements-dev.txt

# 2. Run unit tests (21 baseline + 3 improved = 24 total)
pytest

# 3. Generate coverage report (HTML)
pytest --cov=ai_analysis --cov-report=html:../reports/baseline_coverage

# 4. Run mutation testing (baseline)
mutmut run --paths ai_analysis.py
mutmut results
mutmut html
# Output: .mutmut-cache/html → copy to ../reports/mutation_baseline

# 5. Run mutation testing (final, after improvements)
mutmut run --paths ai_analysis.py
mutmut html
# Output: .mutmut-cache/html → copy to ../reports/mutation_final
```

### Using PowerShell Automation Script

```powershell
# Execute the automated report generation script
.\generate_reports.ps1

# This will:
# - Create venv if needed
# - Install all dependencies
# - Run pytest with coverage
# - Run mutmut baseline & final
# - Copy reports to ../reports/
```

### Fallback: No pytest/venv Required

```powershell
# If pytest installation fails, use fallback runner
python run_tests.py

# Runs 21 unit tests without external dependencies
# Output: Pass/fail summary for each test
```

---

## Module Under Test: `ai_analysis.py`

### Overview

**Purpose:** Parses free-text user input to extract:
- **Budget** (currency + amount)
- **Duration** (days, weeks, months)
- **Category** (meal, laundry, maintenance)
- **Success Flag** (both budget and duration present)

**Business Criticality:**
- Directly influences expense recommendations
- Incorrect parsing → wrong service category suggestions
- Silent failures (parsing fails but no error raised)

**Lines of Code:** ~80  
**Functions:** 1 primary (`analyze_user_input`)  
**Complexity:** Moderate (regex, string parsing, logic)  

### Key Functions

#### `analyze_user_input(text: str) -> Dict`

Parses user input using regex patterns and keyword matching.

**Input Example:**
```
"I have 3000 rupees for 2 weeks for meal planning"
```

**Output:**
```python
{
    'budget': 3000.0,
    'days': 14,
    'category': 'meal',
    'original_text': '...',
    'success': True
}
```

**Mutation Testing Findings:**

| Component | Coverage | Mutation Score | Risk Level |
|-----------|----------|-----------------|-----------|
| Budget parsing (regex) | 100% | 60% (SDL mutations) | 🟡 Medium |
| Duration calculation | 100% | 50% (AOR mutations) | 🔴 High |
| Category detection | 100% | 67% (LCR mutations) | 🟡 Medium |
| Success flag logic | 98% | 75% (ROR mutations) | 🟡 Medium |

---

## Test Suite (24 tests)

### Baseline Tests (21 tests)

Organized by mutation operator:

- **Basic Functional (1 test)**
  - `test_analyze_user_input_currency_and_days_simple`

- **ROR Tests (2 tests)** — Relational Operator Replacement
  - `test_success_flag_requires_both_budget_and_days`
  - `test_days_must_be_nonzero_integer`

- **LCR Tests (4 tests)** — Logical Connector Replacement
  - `test_category_detection_meal_keyword`
  - `test_category_detection_laundry_keyword`
  - `test_category_detection_maintenance_keyword`
  - `test_category_default_when_no_keywords`

- **AOR Tests (3 tests)** — Arithmetic Operator Replacement
  - `test_week_multiplier_exact`
  - `test_month_multiplier_exact`
  - `test_day_multiplier_is_one`

- **SDL Tests (6 tests)** — String/Literal Replacement
  - `test_budget_with_comma_separator`
  - `test_budget_without_comma`
  - `test_rupees_keyword_variations`
  - `test_day_keyword_variations`
  - `test_week_keyword_variations`
  - `test_month_keyword_variations`

- **Boundary & Edge Cases (3 tests)**
  - `test_large_budget`
  - `test_zero_days_boundary`
  - `test_currency_order_currency_first`

- **Integration (2 tests)**
  - `test_case_insensitivity`
  - `test_category_first_match_wins`

### Improved Tests (3 tests added in Task 3)

- `test_success_flag_requires_both_budget_and_days` (comprehensive)
- `test_category_keyword_matching_requires_single_match` (LCR targeting)
- `test_multiplier_boundaries_detailed` (AOR targeting)

---

## Mutation Testing Results

### Baseline Scores (Task 2)

**Mutation Score:** 63.8%

| Operator | Killed | Survived | Score |
|----------|--------|----------|-------|
| **AOR** (Arithmetic) | 5 | 5 | 50% |
| **ROR** (Relational) | 6 | 2 | 75% |
| **LCR** (Logical) | 4 | 2 | 67% |
| **SDL** (String) | 9 | 6 | 60% |
| **LVR** (Literal) | 6 | 2 | 75% |

### Final Scores (Task 4 — After Improvements)

**Mutation Score:** 74.5% (baseline) → **78.7%** (with stretch tests)

**Improvement:** +14.9 percentage points

---

## Mutation Test Operators

### ROR (Relational Operator Replacement)

**Examples:** `>` ↔ `<`, `==` ↔ `!=`, `and` ↔ `or`

**Vulnerable Patterns in Code:**
```python
success = budget is not None and days is not None
```

**Mutation:** `and` → `or`  
**Impact:** Success flag returns True if EITHER budget OR days present (instead of BOTH)

### AOR (Arithmetic Operator Replacement)

**Examples:** `+` ↔ `-`, `*` ↔ `/`

**Vulnerable Patterns in Code:**
```python
days = int(match.group(1)) * multiplier  # multiplier = 1, 7, 30
```

**Mutation:** `7` → `6` or `8`  
**Impact:** Week calculation off (2 weeks = 12 or 16 days instead of 14)

### LCR (Logical Connector Replacement)

**Examples:** `and` ↔ `or`, `any()` ↔ `all()`

**Vulnerable Patterns in Code:**
```python
if any(keyword in text_lower for keyword in keywords):
    category = cat
    break
```

**Mutation:** `any()` → `all()`  
**Impact:** Requires ALL keywords to match (instead of ANY single keyword)

### SDL (String/Literal Replacement)

**Examples:** Regex patterns, string values, constants

**Vulnerable Patterns in Code:**
```python
r'([\d,]+)\s*(?:rupees?|rs\.?|pkr)'  # regex pattern
category = 'meal'  # default string
```

**Mutations:** 
- `rupees?` → `rupee` (missing '?' quantifier)
- `'meal'` → `'laundry'` (different default)

### LVR (Literal Value Replacement)

**Examples:** Numeric constants, string defaults

**Vulnerable Patterns in Code:**
```python
(r'(\d+)\s*(?:weeks?|hafte)', 7),    # multiplier = 7
EXCHANGE_RATES = {'INR_TO_PKR': 3.3}  # constant
```

**Mutations:**
- `7` → `6` or `8`
- `3.3` → `3.2` or `3.4`

---

## Configuration Files

### `setup.cfg` — Pytest Configuration

```ini
[tool:pytest]
testpaths = tests
addopts = --maxfail=1 -q --cov=ai_analysis --cov-report=html:../../reports/baseline_coverage
```

**Settings:**
- Discover tests in `tests/` directory
- Stop after first failure (`--maxfail=1`)
- Generate coverage report in HTML format
- Report output to `../reports/baseline_coverage/`

### `requirements-dev.txt` — Development Dependencies

```
pytest
pytest-cov
mutmut
```

### `requirements.txt` — Production Dependencies

Core Flask API dependencies (see file for full list)

---

## Reports & Artifacts

### Generated During Mutation Testing

| Report | Location | Generated By |
|--------|----------|--------------|
| **Coverage HTML** | `../reports/baseline_coverage/` | `pytest --cov-report=html` |
| **Mutation Baseline** | `../reports/mutation_baseline/` | `mutmut html` (Task 2) |
| **Mutation Final** | `../reports/mutation_final/` | `mutmut html` (Task 4) |
| **Mutation Results** | Console output + `.mutmut-cache/` | `mutmut results` |

### How to View Reports

1. **Coverage Report:** Open `../reports/baseline_coverage/index.html` in browser
   - Shows line, branch, and function coverage
   - Highlights untested code

2. **Mutation Reports:** Open `../reports/mutation_baseline/index.html` or `mutation_final/index.html`
   - Lists all generated mutants
   - Shows status (KILLED, SURVIVED, EQUIVALENT)
   - Links to mutated code snippets

---

## Troubleshooting

### Issue: `pytest` command not found

**Solution 1 — Use Fallback Runner**
```powershell
python run_tests.py
```

**Solution 2 — Install with pip**
```powershell
pip install pytest pytest-cov
```

**Solution 3 — Use venv correctly**
```powershell
.venv\Scripts\Activate.ps1  # Windows
python -m pytest            # Use module form
```

### Issue: `mutmut` not found

**Solution:**
```powershell
pip install mutmut
# or
python -m mutmut run --paths ai_analysis.py
```

### Issue: Venv creation fails (large file names)

**Problem:** Directory path has spaces; venv launcher fails  
**Solution:** Use short directory path or move to root

---

## FAQ

**Q: What is mutation testing?**  
A: Automated testing technique that intentionally inserts code bugs ("mutants") to verify test suite can detect them. Weak tests fail to catch bugs.

**Q: Why 74.5% mutation score?**  
A: ~12 of 47 mutants survive baseline tests, indicating gaps in test coverage/precision. With improved tests (Task 3), score rises to 78.7%.

**Q: What does "survived mutant" mean?**  
A: A mutated version of code that all tests still pass on. Indicates test suite has a gap (e.g., doesn't check exact value, boundary condition).

**Q: How to improve mutation score?**  
A: Write targeted tests that:
- Check exact values (not just presence/type)
- Test boundary conditions (e.g., 0, 1, max values)
- Exercise all combinations of compound logic (and/or)
- Cover all regex/string variations

**Q: Why focus on `ai_analysis.py` and not `app.py`?**  
A: `ai_analysis.py` has business-critical, deterministic logic (parsing, calculations) suitable for unit testing and mutation analysis. Flask routes are better tested with integration/e2e tests.

---

## Additional Resources

- **Mutation Testing Basics:** See `../mutation_assignment/README.md`
- **Task-by-Task Breakdown:** See `../mutation_assignment/Task{1-4}/`
- **Mutant Analysis Examples:** See `../mutation_assignment/Task3_MutantAnalysis/Task3_DetailedMutantAnalyses.md`
- **Coverage & Mutation Reports:** See `../reports/` directory

---

## License & Attribution

**Assignment:** Final Year Project — Mutation Testing  
**Course:** Software Testing (CS-ST)  
**Institution:** FAST NUCES  
**Submission Date:** May 2026  

**Created by:** [Student Names]  
**Group ID:** [Group ID]  

---

## Version History

| Date | Version | Changes |
|------|---------|---------|
| 2026-05-01 | 1.0 | Initial setup, 21 baseline tests, mutation analysis |
| 2026-05-01 | 1.1 | Added 3 improved tests, final mutation score 78.7% |

---

**Last Updated:** 2026-05-01  
**Status:** ✓ READY FOR ASSIGNMENT SUBMISSION

