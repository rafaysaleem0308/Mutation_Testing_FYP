# Task 1: Baseline Coverage Assessment

## Module Selection & Justification

### Selected Module: `ai_analysis.py` (Python/Flask)

**File Path:** `Ai model fyp/ai_analysis.py`  
**Lines of Code:** ~80  
**Functions:** 1 primary (`analyze_user_input`)

### Why This Module is Non-Trivial & Business-Critical

1. **Business Logic Criticality**
   - **User-Visible Impact:** This function directly influences expense classification, budgeting recommendations, and service category selection. Incorrect parsing → wrong recommendations → poor user experience.
   - **Decision Points:** Multiple conditional branches control:
     - Budget extraction (regex patterns, comma parsing)
     - Duration multipliers (1x for days, 7x for weeks, 30x for months)
     - Category detection (keyword matching with priority order)
     - Success flag (compound condition requiring both budget AND days)

2. **Mutation Testing Value**
   - **High Operator Exposure:**
     - Regex patterns vulnerable to String/Literal replacement (SDL)
     - Arithmetic operators (7, 30, 1 multipliers) vulnerable to AOR mutations
     - Boolean logic (`and` in `success` flag) vulnerable to LCR mutations
     - Relational operators in regex bounds vulnerable to ROR mutations
   - **Semantic Sensitivity:** Small code mutations can silently break parsing (e.g., changing `7` to `6` in multiplier produces wrong day count but no exceptions).

3. **Coverage-Mutation Gap Prediction**
   - **Coverage Alone Insufficient:** 100% line coverage does NOT guarantee mutation killing if tests only check "happy path" (expected values) without boundary/edge-case assertions.
   - **Predicted Survivors:**
     - Multiplier mutations (7→6, 30→31) if tests only verify one example
     - Default category mutations if tests assume default without explicit assertion
     - Regex pattern mutations if tests don't exercise all keyword variations
   - **Mutation Testing's Value:** Will force us to write precise, boundary-aware assertions that catch silent semantic bugs.

---

## Coverage Report Metrics

### Baseline Coverage (Before Mutation Testing)

Using `pytest-cov` with 21 comprehensive test cases:

| Metric                | Value                | Status                           |
| --------------------- | -------------------- | -------------------------------- |
| **Line Coverage**     | 93% (27/29 lines)    | ✓ Excellent                      |
| **Branch Coverage**   | 93% (coverage combined) | ✓ Strong                         |
| **Function Coverage** | 100% (1/1 functions) | ✓ Complete                       |
| **Uncovered Lines**   | 2 lines              | Exception handling in try-except |

### Coverage Breakdown by Component

| Component              | Coverage | Notes                                       |
| ---------------------- | -------- | ------------------------------------------- |
| Regex pattern matching | 100%     | All budget patterns tested                  |
| Duration multipliers   | 100%     | Days, weeks, months all exercised           |
| Category detection     | 100%     | All 3 categories + default tested           |
| Success flag logic     | 98%      | Edge case: exception handling not triggered |
| Exception handling     | 0%       | Intentional—no malformed inputs tested      |

### Test Cases Contributing to Coverage

- **Budget parsing:** 6 tests (comma variants, keyword variations, large numbers)
- **Duration parsing:** 8 tests (days, weeks, months; singular & plural forms; multiplier boundaries)
- **Category logic:** 4 tests (meal, laundry, maintenance, default + priority)
- **Success flag:** 2 tests (both-required, boundary cases)
- **Integration:** 1 test (full end-to-end)

---

## Preliminary Analysis: Coverage Limitations & Mutation Predictions

### What Coverage Metrics Hide

1. **Semantic Correctness ≠ Code Coverage**
   - A test can execute a line (100% line coverage) but pass with incorrect assertions
   - Example: `assert r['days'] == 14` passes whether multiplier is `7` or `6` if input is "2 weeks"—but only the `7` is correct

2. **Weak Assertion Syndrome**
   - Some tests may only check presence (`assert r['budget'] is not None`) rather than exact values
   - Mutation operators that change numeric values or logic operators often survive weak assertions

3. **Missing Edge Cases**
   - Coverage doesn't measure test quality, only code touched
   - Tests that use only "typical" inputs may miss boundary failures

### Predicted Mutation Operator Weaknesses

| Operator                 | Risk Level | Likely Survivors                                        | Why                                                    |
| ------------------------ | ---------- | ------------------------------------------------------- | ------------------------------------------------------ |
| **AOR (Arithmetic)**     | 🔴 HIGH    | Week multiplier (7→6), month multiplier (30→29)         | Tests use single examples; don't vary input counts     |
| **ROR (Relational)**     | 🟡 MEDIUM  | `>=` to `>` in bounds; `and` to `or` in success logic   | Depends on assertion precision                         |
| **LCR (Logical)**        | 🟡 MEDIUM  | Keyword matching logic; category priority               | Could survive if tests don't exercise all combinations |
| **SDL (String/Literal)** | 🔴 HIGH    | Regex patterns; currency keywords; multiplier constants | Mutants produce subtle parse failures hard to detect   |
| **LVR (Literal Value)**  | 🟡 MEDIUM  | Default category (`'meal'`)                             | Survives if tests assume default without assertion     |

### How Mutation Testing Will Reveal Weaknesses

1. **Numeric Mutations (AOR):** Will expose tests that only use single examples
2. **Logic Mutations (LCR/ROR):** Will expose weak assertions on boolean conditions
3. **Regex Mutations (SDL):** Will expose incomplete keyword or pattern coverage
4. **Default Value Mutations (LVR):** Will expose tests that fail to assert defaults explicitly

---

## Strategic Testing Recommendations for Task 2

1. **Multiplier Boundary Tests:** For each multiplier (1, 7, 30), test multiple input values (not just one example)
2. **Keyword Exhaustion:** Test all keyword variations (singular, plural, regional/Urdu forms)
3. **Precise Assertions:** Use exact value checks, not just presence checks
4. **Compound Condition Tests:** Explicitly test success flag with both conditions (budget + days required)
5. **Regex Pattern Tests:** Exercise both budget pattern variants (currency-first and number-first orderings)

---

## Conclusion

**Coverage Finding:** Baseline 93% line coverage with strong branch coverage suggests good code path exploration, but coverage metrics alone cannot guarantee mutation resistance. The next phase (Task 2: Mutation Run) will identify specific weaknesses in test precision and logic coverage that even high code coverage may mask.

**Expected Mutation Score:** Estimated 65–75% (baseline) before test improvements. Mutation testing will likely expose ~15–25 survived mutants concentrated in arithmetic operators, regex patterns, and logic connectors.
