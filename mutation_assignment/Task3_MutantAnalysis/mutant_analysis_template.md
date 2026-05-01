# Mutant Analysis Template

Use this template for each survived mutant. Save as `M<index>_<short-id>.md`.

## [M1] Mutant Identification
- File: `ai_analysis.py`
- Operator: (e.g., ROR, LCR, AOR)
- Mutant ID: 

## [M2] Original vs Mutated Code
```diff
- original line
+ mutated line
```

## [M3] Semantic Impact Analysis
- Business-level effect:
- Exact input boundary that exposes difference:
- User-visible consequence:

## [M4] Root Cause Analysis
- Which existing test allowed mutant to survive (show assertion snippet):
- Why the test did not discriminate:

## [M5] Mutant-Killing Test Case
```python
# Intent: Describe why this input discriminates
def test_...():
    ...
```

## [M6] Verification
- Mutmut result before: SURVIVED (screenshot/console)
- Mutmut result after: KILLED (screenshot/console)
