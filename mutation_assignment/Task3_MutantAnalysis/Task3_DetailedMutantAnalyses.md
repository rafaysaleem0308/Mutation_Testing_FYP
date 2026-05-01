# Task 3: Mutant Analysis & Eradication

## Overview: Representative Survived Mutants from Baseline

This section analyzes 5 representative survived mutants (from the baseline 19 survived) covering diverse mutation operators. These represent the primary reasons mutants escaped the baseline test suite.

---

## Mutant M1: Week Multiplier Off-by-One (AOR)

### Mutant Identification

- **File:** `ai_analysis.py`
- **Line:** 41 (duration parsing logic)
- **Operator:** AOR (Arithmetic Operator Replacement)
- **Mutation Type:** `7 → 6` (week multiplier)
- **Status:** **SURVIVED** in baseline (21 tests)
- **Root Cause:** Boundary test for week multiplier not present; test uses only "2 weeks" → 14 days

### Original vs Mutated Code

**Original Code:**
```python
duration_patterns = [
    (r'(\d+)\s*(?:days?|din)', 1),
    (r'(\d+)\s*(?:weeks?|hafte)', 7),     # ← Correct: 7 days/week
    (r'(\d+)\s*(?:months?|mahine)', 30),
]
```

**Mutated Code:**
```python
duration_patterns = [
    (r'(\d+)\s*(?:days?|din)', 1),
    (r'(\d+)\s*(?:weeks?|hafte)', 6),     # ← WRONG: 6 days/week
    (r'(\d+)\s*(?:months?|mahine)', 30),
]
```

### Why It Survived

**Test Input:** `"I need service for 2 weeks"`
- **Original:** `2 * 7 = 14 days` ✓
- **Mutant:** `2 * 6 = 12 days` ✓ (test passes because input is hardcoded to "2 weeks")
- **Test Result:** Mutation NOT detected (test doesn't verify the exact multiplier value)

### Kill Strategy

**Test Required:**
```python
def test_week_multiplier_is_exactly_7():
    result = analyze_user_input("I need service for 1 week")
    assert result['days'] == 7, "Week should multiply by exactly 7, not 6"
```

**Reason:** Specific input value (1 week) makes the off-by-one mutation obvious: `1 * 7 = 7` vs `1 * 6 = 6`.

---

## Mutant M2: Month Multiplier Off-by-One (AOR)

### Mutant Identification

- **File:** `ai_analysis.py`
- **Line:** 41 (duration parsing logic)
- **Operator:** AOR (Arithmetic Operator Replacement)
- **Mutation Type:** `30 → 29` (month multiplier)
- **Status:** **SURVIVED** in baseline
- **Root Cause:** Month multiplier never tested with input "1 month"; baseline lacks boundary test

### Original vs Mutated Code

**Original:**
```python
(r'(\d+)\s*(?:months?|mahine)', 30),     # ← 30 days/month
```

**Mutated:**
```python
(r'(\d+)\s*(?:months?|mahine)', 29),     # ← 29 days/month (off-by-one)
```

### Why It Survived

No baseline test explicitly checks:
- Input: `"I need service for 1 month"`
- Expected: `days = 30`
- Mutant produces: `days = 29` (undetected)

### Kill Strategy

**Test Required:**
```python
def test_month_multiplier_is_exactly_30():
    result = analyze_user_input("I need service for 1 month")
    assert result['days'] == 30, "Month should multiply by exactly 30"
```

---

## Mutant M3: Regex Pattern Keyword Mutation (SDL)

### Mutant Identification

- **File:** `ai_analysis.py`
- **Line:** 18–22 (budget regex patterns)
- **Operator:** SDL (String Literal Replacement)
- **Mutation Type:** `rupees? → rupee` (missing quantifier '?')
- **Status:** **SURVIVED** in baseline
- **Root Cause:** Test uses only "rupees" plural; mutation to singular-only "rupee" still matches input

### Original vs Mutated Code

**Original Pattern:**
```python
budget_patterns = [
    r'([\d,]+)\s*(?:rupees?|rs\.?|pkr)',  # ← rupees? = "rupee" OR "rupees"
]
```

**Mutated Pattern:**
```python
budget_patterns = [
    r'([\d,]+)\s*(?:rupee|rs\.?|pkr)',   # ← rupee only = "rupee" (NOT "rupees")
]
```

### Why It Survived

**Test Input:** `"I need 5000 rupees"`
- **Original:** Matches "rupees" via `rupees?` ✓
- **Mutant:** Matches "rupees" via `rupee` prefix (still matches) ✓
- **Result:** Mutation NOT detected (regex partial match behavior)

### Kill Strategy

**Test Required:**
```python
def test_rupee_singular_keyword():
    result = analyze_user_input("I can spend 1000 rupee")  # singular
    assert result['budget'] == 1000.0, "Singular 'rupee' should be parsed"

def test_rupees_plural_keyword():
    result = analyze_user_input("I can spend 1000 rupees")  # plural
    assert result['budget'] == 1000.0, "Plural 'rupees' should be parsed"
```

**Reason:** Mutation removes the `?` quantifier, breaking singular form specifically.

---

## Mutant M4: Default Category Mutation (LVR)

### Mutant Identification

- **File:** `ai_analysis.py`
- **Line:** 65 (category default assignment)
- **Operator:** LVR (Literal Value Replacement)
- **Mutation Type:** `'meal' → 'laundry'`
- **Status:** **SURVIVED** in baseline
- **Root Cause:** No baseline test explicitly checks the default category when no keywords match

### Original vs Mutated Code

**Original:**
```python
category = 'meal'  # ← Default category if no keywords match
```

**Mutated:**
```python
category = 'laundry'  # ← WRONG default
```

### Why It Survived

**Test Input:** `"I need service"`  (no category keyword)
- **Original:** Returns `category = 'meal'` ✓
- **Mutant:** Returns `category = 'laundry'` (but baseline test doesn't check default)
- **Result:** Mutation NOT detected

### Kill Strategy

**Test Required:**
```python
def test_default_category_is_meal():
    result = analyze_user_input("I need service urgently")  # No category keyword
    assert result['category'] == 'meal', "Default should be 'meal'"
```

---

## Mutant M5: Success Flag Logic Mutation (ROR)

### Mutant Identification

- **File:** `ai_analysis.py`
- **Line:** 68 (success flag condition)
- **Operator:** ROR (Relational Operator Replacement)
- **Mutation Type:** `is not None → is None`
- **Status:** **SURVIVED** in baseline
- **Root Cause:** Baseline tests may not verify the AND logic comprehensively across all combinations (budget-only, days-only, both, neither)

### Original vs Mutated Code

**Original:**
```python
success = budget is not None and days is not None
# True only if BOTH budget AND days are present
```

**Mutated:**
```python
success = budget is None and days is None
# True only if BOTH budget AND days are ABSENT
```

### Why It Survived

If baseline tests only verify cases where both are present or both are absent, the mutation might not be caught:

**Case 1 (Both present):**
- Original: `True and True = True` ✓
- Mutant: `False and False = False` ✗ (SHOULD be caught)

**Case 2 (Budget only):**
- Original: `True and False = False` ✓
- Mutant: `False and True = False` ✓ (undetected if test doesn't cover)

### Kill Strategy

**Tests Required:**
```python
def test_success_requires_both_budget_and_days():
    result = analyze_user_input("I can spend 5000 rupees")  # Budget only
    assert result['success'] == False, "Success should be False without days"

def test_success_with_budget_and_days():
    result = analyze_user_input("I can spend 5000 rupees for 2 weeks")
    assert result['success'] == True, "Success should be True with both"

def test_success_with_days_only():
    result = analyze_user_input("I need service for 1 week")  # Days only
    assert result['success'] == False, "Success should be False without budget"
```

---

## Summary: Test Improvements to Kill 19 Survived Mutants

| Mutant Category | Count | Representative | Kill Test Strategy |
| --- | --- | --- | --- |
| **AOR (Arithmetic)** | 6 | M1, M2 (multipliers) | Boundary tests for each multiplier value (1 day, 1 week, 1 month) |
| **SDL (String/Literal)** | 5 | M3 (regex keywords) | Singular/plural keyword variations for currency |
| **LVR (Literal Value)** | 4 | M4 (default category) | Default category when no keywords match |
| **ROR (Relational)** | 3 | M5 (success logic) | All combinations of budget/days presence (both, budget-only, days-only, neither) |
| **LCR (Logical)** | 1 | Compound keywords | Multi-keyword matching scenarios |

**Total Tests to Add:** ~12–15  
**Expected Score Improvement:** 71.6% → 88% (Task 4 target)
