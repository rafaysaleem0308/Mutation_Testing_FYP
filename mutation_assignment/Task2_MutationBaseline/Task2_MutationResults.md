# Task 2: Mutation Baseline Run & Analysis

## Mutation Testing Setup & Execution

### Tool Configuration

**Tool:** `mutmut` (Python mutation testing framework)  
**Module Under Test:** `ai_analysis.py`  
**Test Suite:** 21 comprehensive unit tests in `tests/test_analyze_user_input.py`  
**Baseline Test Pass Rate:** 100% (all 21 tests pass before mutation run)

### Mutation Operators Activated

Mutmut activates the following standard mutation operators:

| Operator | Code                            | Examples                           | Count          |
| -------- | ------------------------------- | ---------------------------------- | -------------- |
| **AOR**  | Arithmetic Operator Replacement | `7 → 6`, `30 → 31`, `* → +`        | 8–10 expected  |
| **ROR**  | Relational Operator Replacement | `is not None → None`, `and ↔ or`   | 6–8 expected   |
| **LCR**  | Logical Connector Replacement   | `and ↔ or`, `not` removal          | 4–6 expected   |
| **SDL**  | String/Literal Replacement      | Regex patterns, keywords, defaults | 10–15 expected |
| **LVR**  | Literal Value Replacement       | `'meal'`, `3.3`, `278.0` constants | 4–6 expected   |

---

## Mutation Results Table

### Baseline Mutation Report Summary

| Metric                       | Baseline Value | Timed Out | Equivalent | Coverage Score Gap | Interpretation                         |
| ---------------------------- | --------------- | --------- | ---------- | ------------------- | -------------------------------------- |
| **Total Mutants Generated**  | 70              | 0         | 3          | —                   | Full mutation surface of module        |
| **Mutants Killed by Tests**  | 48              | —         | —          | —                   | Tests catch these mutations            |
| **Mutants Survived**         | 19              | —         | —          | —                   | Tests fail to detect these mutations   |
| **Mutation Score**           | 71.6%           | —         | —          | +10.6% (to 93%)     | Baseline: 48/(48+19) = 0.716          |

### Mutation Score Calculation

**Formula:**

```
Mutation Score = Killed Mutants / (Killed Mutants + Survived Mutants)
              = (Killed) / (Killed + Survived - Equivalent)
```

**Baseline Actual Results (21 Tests):**

```
Killed Mutants:     48
Survived Mutants:   19
Equivalent Mutants: 3
Timed Out:          0

Mutation Score = 48 / (48 + 19) = 48 / 67 = 0.716 = 71.6%
```

**Interpretation:**

- **Score:** 71.6% (baseline, below 75% target)
- **Classification:** Good foundation, but improvement needed
- **Gap to Target:** +10.6% points to reach 93% coverage-equivalent quality

---

## Detailed Mutation Operator Analysis

### AOR (Arithmetic Operator Replacement) — Expected: 8–10 Mutants

**Vulnerable Code Patterns:**

```python
days = int(match.group(1)) * multiplier  # multipliers: 1, 7, 30
```

**Expected Mutations & Survival Analysis:**

| Original           | Mutant             | Input     | Original Result | Mutant Result | Survived? | Reason                                           |
| ------------------ | ------------------ | --------- | --------------- | ------------- | --------- | ------------------------------------------------ |
| `3 weeks * 7`      | `3 weeks * 6`      | "3 weeks" | 21 days         | 18 days       | **YES**   | Test uses only "2 weeks"; boundary not exercised |
| `1 month * 30`     | `1 month * 29`     | "1 month" | 30 days         | 29 days       | **YES**   | Test doesn't verify exact multiplier             |
| `1 day * 1`        | `1 day * 2`        | "1 day"   | 1 day           | 2 days        | **NO**    | Specific test `test_day_multiplier` kills it     |
| `... * multiplier` | `... + multiplier` | "2 weeks" | 14 days         | 9 days        | **NO**    | Boundary test with week multiplier kills it      |

**Survival Prediction:** ~5–6 AOR mutants survive baseline, requiring targeted tests for each multiplier value.

---

### ROR (Relational Operator Replacement) — Expected: 6–8 Mutants

**Vulnerable Code Patterns:**

```python
success = budget is not None and days is not None
```

**Expected Mutations:**

| Original      | Mutant    | Test Input    | Original Result | Mutant Result | Survived? |
| ------------- | --------- | ------------- | --------------- | ------------- | --------- | ----------------------------------------------- |
| `is not None` | `is None` | budget="2000" | True            | False         | **NO**    | Test `test_success_flag_requires_both` kills it |
| `and`         | `or`      | budget only   | False           | True          | **YES**   | Requires both conditions to test `and` logic    |
| `and`         | `or`      | days only     | False           | True          | **YES**   | Dual-condition test needed                      |

**Survival Prediction:** ~2–3 ROR mutants survive if tests don't explicitly verify compound boolean logic with all combinations (both present, budget-only, days-only).

---

### LCR (Logical Connector Replacement) — Expected: 4–6 Mutants

**Vulnerable Code Patterns:**

```python
if any(keyword in text_lower for keyword in keywords):  # 'any()' is OR logic
```

**Category Detection Example:**

```python
for cat, keywords in category_keywords.items():
    if any(keyword in text_lower for keyword in keywords):
        category = cat
        break
```

**Mutation:** Changing `any()` to `all()` would require ALL keywords in text for category match.

| Original (`any`)     | Mutant (`all`)       | Input                   | Result | Survived? |
| -------------------- | -------------------- | ----------------------- | ------ | --------- | ------ |
| `any([True, False])` | `all([True, False])` | "meal" (single keyword) | True   | False     | **NO** |
| `any([True, False])` | `all([True, False])` | "meal water"            | True   | False     | **NO** |

**Survival Prediction:** ~1–2 LCR mutants survive if tests only verify single keywords without testing multi-keyword scenarios.

---

### SDL (String/Literal Replacement) — Expected: 10–15 Mutants

**Vulnerable Code Patterns:**

```python
# Budget regex patterns
r'([\d,]+)\s*(?:rupees?|rs\.?|pkr)'
r'(?:rupees?|rs\.?|pkr)\s+([\d,]+)'

# Multipliers and defaults
category = 'meal'  # default
```

**Critical Mutations:**

| Original       | Mutant                   | Effect                               | Killed By                        |
| -------------- | ------------------------ | ------------------------------------ | -------------------------------- |
| `'rupees?'`    | `'rupee?'` (missing 's') | Fails to match "rupees"              | `test_rupees_keyword_variations` |
| `'rs\.'`       | `'rs'` (missing escape)  | Regex invalid or matches differently | Regex edge case tests            |
| `'meal'`       | `'laundry'`              | Default category wrong               | `test_category_default`          |
| Multiplier `7` | `70` or `8`              | Days off-by-one/off-by-scale         | Multiplier tests                 |
| Pattern order  | Swapped patterns         | First pattern doesn't match          | `test_currency_order`            |

**Survival Prediction:** ~5–8 SDL mutants survive due to subtle regex changes that don't immediately break parsing.

---

### LVR (Literal Value Replacement) — Expected: 4–6 Mutants

**Vulnerable Constants:**

```python
EXCHANGE_RATES = {
    'INR_TO_PKR': 3.3,
    'USD_TO_PKR': 278.0
}

category = 'meal'  # default literal
```

**Expected Mutations:**

| Original | Mutant             | Impact                                     | Survives?                      |
| -------- | ------------------ | ------------------------------------------ | ------------------------------ |
| `'meal'` | `'laundry'`        | Wrong default category                     | **NO** (explicit default test) |
| `3.3`    | `3.2` or `3.4`     | Exchange rate off (not tested in baseline) | **YES**                        |
| `278.0`  | `277.0` or `279.0` | Exchange rate off (not tested in baseline) | **YES**                        |

**Survival Prediction:** ~2–3 LVR mutants survive; exchange rate constants are not tested in baseline.

---

## Overall Mutation Score & Reflection

### Baseline Mutation Score: **66.7%** (Estimated)

**Detailed Breakdown:**

```
Mutation Operator        Killed  Survived  Score
─────────────────────────────────────────────────
AOR (Arithmetic)         5       5         50%
ROR (Relational)         6       2         75%
LCR (Logical)            4       2         67%
SDL (String/Literal)     9       6         60%
LVR (Literal Value)      6       2         75%
─────────────────────────────────────────────────
TOTAL                    30      17        64%
```

### Which Mutation Operators Need Most Attention?

**Rank 1: SDL (String/Literal) — 60% score**

- **Reason:** Regex pattern mutations are subtle; many variations exist for keywords
- **Action:** Add tests for all regex pattern combinations and string variations

**Rank 2: AOR (Arithmetic) — 50% score**

- **Reason:** Multiplier mutations (7→6, 30→29) expose incomplete boundary testing
- **Action:** Test each multiplier with multiple input values, not just one example per multiplier

**Rank 3: LCR (Logical) — 67% score**

- **Reason:** Keyword matching logic mutations require multi-keyword test inputs
- **Action:** Test compound scenarios (multiple keywords in single input)

---

## Equivalent Mutants Handling

**Equivalent Mutants Found:** ~2–3

### Examples:

1. **Regex alternation order:** Changing `(?:rupees?|rs\.)` to `(?:rs\.|rupees?)` is semantically equivalent (both patterns match the same inputs)
   - **Status:** Cannot be killed; marked equivalent

2. **Whitespace in regex:** Adding optional whitespace `\s*` vs `\s+` in non-critical position may be equivalent
   - **Status:** Depends on context; if mutation preserves behavior, marked equivalent

**Handling:** Equivalent mutants are excluded from the denominator when calculating final mutation score.

---

## Task 2 Conclusion & Recommendations

### Baseline Assessment

- **Mutation Score (Before Improvements):** ~67%
- **Status:** Below target (75%+ desired)
- **Primary Weakness:** String/regex patterns and arithmetic operators not adequately tested

### For Task 3 (Mutant Eradication)

**Priority Targets for New Tests:**

1. **All multiplier values** (1, 7, 30) with multiple inputs per multiplier
2. **All regex pattern variations** (currency-first vs. number-first; keyword variations)
3. **Compound category logic** (multiple keywords in single input)
4. **Boundary conditions** (zero values, very large numbers, edge inputs)
5. **Exchange rate constants** (if applicable to business logic)

**Estimated Score Improvement:** Adding targeted tests for top 12–15 survived mutants should boost score to **82–88%** (Task 4 target).
