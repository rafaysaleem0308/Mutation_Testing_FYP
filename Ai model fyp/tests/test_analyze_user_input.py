import pytest
from ai_analysis import analyze_user_input


# ============================================================================
# BASIC FUNCTIONAL TESTS
# ============================================================================

def test_analyze_user_input_currency_and_days_simple():
    """[M5] Basic test: budget + days + category + success flag"""
    text = "I have 3,000 rupees for 7 days for food"
    r = analyze_user_input(text)
    assert r['budget'] == 3000.0
    assert r['days'] == 7
    assert r['category'] == 'meal'
    assert r['success'] is True


def test_analyze_user_input_weeks_multiplier():
    """[M5] Tests week multiplier (7x) to kill AOR mutants (7->1, 7->6, 7->8)"""
    text = "I have 2 weeks and 2000 rupees food"
    r = analyze_user_input(text)
    assert r['days'] == 14, f"Expected 14 days, got {r['days']}"


def test_analyze_user_input_months_multiplier():
    """[M5] Tests month multiplier (30x) to kill AOR mutants"""
    text = "I have 1 month and 5000 rupees maintenance"
    r = analyze_user_input(text)
    assert r['days'] == 30, f"Expected 30 days (1 month), got {r['days']}"


def test_analyze_user_input_missing_numbers():
    """[M5] Ensures success=False when budget/days absent"""
    text = "I want suggestions"
    r = analyze_user_input(text)
    assert r['budget'] is None
    assert r['days'] is None
    assert r['success'] is False


# ============================================================================
# ROR TESTS (Relational Operator Replacement)
# ============================================================================

def test_success_flag_requires_both_budget_and_days():
    """[M5] Kills ROR mutant: 'and' -> 'or' in success logic"""
    # Only budget, no days
    text = "I have 3000 rupees"
    r = analyze_user_input(text)
    assert r['success'] is False, "success should be False if days missing"
    
    # Only days, no budget
    text = "I need 5 days"
    r = analyze_user_input(text)
    assert r['success'] is False, "success should be False if budget missing"


def test_days_must_be_nonzero_integer():
    """[M5] Kills ROR: boundary testing on duration parsing"""
    text = "I have 1 day and 1000 rupees"
    r = analyze_user_input(text)
    assert r['days'] == 1, "1 day should parse as 1"
    assert r['success'] is True


# ============================================================================
# LCR TESTS (Logical Connector Replacement: and <-> or)
# ============================================================================

def test_category_detection_meal_keyword():
    """[M5] Kills LCR: 'or' logic in keyword matching"""
    text = "I need meal planning"
    r = analyze_user_input(text)
    assert r['category'] == 'meal'


def test_category_detection_laundry_keyword():
    """[M5] Kills LCR: ensures each category keyword triggers correctly"""
    text = "I need laundry services"
    r = analyze_user_input(text)
    assert r['category'] == 'laundry'


def test_category_detection_maintenance_keyword():
    """[M5] Kills LCR: maintenance category logic"""
    text = "I need repair and electrician services"
    r = analyze_user_input(text)
    assert r['category'] == 'maintenance'


def test_category_default_when_no_keywords():
    """[M5] Kills LVR mutant: default category='meal' must not be mutated"""
    text = "I need help with something"
    r = analyze_user_input(text)
    assert r['category'] == 'meal', "default category should be 'meal'"


# ============================================================================
# AOR TESTS (Arithmetic Operator Replacement: +, -, *, /)
# ============================================================================

def test_week_multiplier_exact():
    """[M5] Kills AOR: 7 * days. Mutants: 6*days, 8*days, 7+days, 7-days"""
    text = "3 weeks and 1000 rupees meal"
    r = analyze_user_input(text)
    assert r['days'] == 21, f"3 weeks = 21 days, got {r['days']}"


def test_month_multiplier_exact():
    """[M5] Kills AOR: 30 * days. Mutants: 29*days, 31*days, 30+days"""
    text = "2 months and 5000 rupees maintenance"
    r = analyze_user_input(text)
    assert r['days'] == 60, f"2 months = 60 days, got {r['days']}"


def test_day_multiplier_is_one():
    """[M5] Kills AOR: 1 * days (or omitted). Mutant: 2*days, 0*days"""
    text = "5 days and 2000 rupees laundry"
    r = analyze_user_input(text)
    assert r['days'] == 5, f"5 days should remain 5, got {r['days']}"


# ============================================================================
# STRING/REGEX PATTERN TESTS (SDL: String Literal Replacement)
# ============================================================================

def test_budget_with_comma_separator():
    """[M5] Kills SDL: ensures comma stripping works"""
    text = "I have 10,000 rupees for 7 days"
    r = analyze_user_input(text)
    assert r['budget'] == 10000.0


def test_budget_without_comma():
    """[M5] Tests parsing without comma separator"""
    text = "I have 5000 rupees for 3 days"
    r = analyze_user_input(text)
    assert r['budget'] == 5000.0


def test_rupees_keyword_variations():
    """[M5] Kills SDL: tests 'rupees', 'rupee', 'rs.'"""
    text1 = "I have 2000 rupees for 5 days"
    r1 = analyze_user_input(text1)
    assert r1['budget'] == 2000.0
    
    text2 = "I have 3000 rupee for 4 days"  # singular
    r2 = analyze_user_input(text2)
    assert r2['budget'] == 3000.0
    
    text3 = "I have 1500 rs. for 2 days"  # abbreviated
    r3 = analyze_user_input(text3)
    assert r3['budget'] == 1500.0


def test_day_keyword_variations():
    """[M5] Kills SDL: tests 'days', 'day', 'din'"""
    text1 = "3 days and 2000 rupees"
    r1 = analyze_user_input(text1)
    assert r1['days'] == 3
    
    text2 = "1 day and 1000 rupees"  # singular
    r2 = analyze_user_input(text2)
    assert r2['days'] == 1


def test_week_keyword_variations():
    """[M5] Tests 'weeks', 'week', 'hafte'"""
    text1 = "2 weeks and 3000 rupees"
    r1 = analyze_user_input(text1)
    assert r1['days'] == 14
    
    text2 = "1 week and 2000 rupees"  # singular
    r2 = analyze_user_input(text2)
    assert r2['days'] == 7


def test_month_keyword_variations():
    """[M5] Tests 'months', 'month', 'mahine'"""
    text1 = "3 months and 5000 rupees"
    r1 = analyze_user_input(text1)
    assert r1['days'] == 90
    
    text2 = "1 month and 4000 rupees"  # singular
    r2 = analyze_user_input(text2)
    assert r2['days'] == 30


# ============================================================================
# BOUNDARY & EDGE CASES
# ============================================================================

def test_large_budget():
    """[M5] Tests large numeric parsing"""
    text = "I have 100,000 rupees for 30 days"
    r = analyze_user_input(text)
    assert r['budget'] == 100000.0


def test_zero_days_boundary():
    """[M5] Tests boundary: 0 days parsed but success depends"""
    text = "I have 0 days and 1000 rupees"
    r = analyze_user_input(text)
    assert r['days'] == 0
    assert r['budget'] == 1000.0
    assert r['success'] is True  # days is not None


def test_currency_order_currency_first():
    """[M5] Tests 'rupees 3000' order (currency keyword first)"""
    text = "I need rupees 3000 for 5 days"
    r = analyze_user_input(text)
    assert r['budget'] == 3000.0


def test_case_insensitivity():
    """[M5] Ensures regex is case-insensitive"""
    text = "I have 2000 RUPEES for 7 DAYS for MEAL"
    r = analyze_user_input(text)
    assert r['budget'] == 2000.0
    assert r['days'] == 7
    assert r['category'] == 'meal'
    assert r['success'] is True


# ============================================================================
# CATEGORY PRIORITY TESTS
# ============================================================================

def test_category_first_match_wins():
    """[M5] If multiple categories mentioned, first match in keyword list wins"""
    text = "I need meal preparation and laundry services"
    r = analyze_user_input(text)
    assert r['category'] == 'meal'


def test_urdu_keyword_support():
    """[M5] Tests Urdu/regional keywords like 'khana', 'dhobi', 'din'"""
    text = "I need khana for 5 din"
    r = analyze_user_input(text)
    assert r['category'] == 'meal'
    assert r['days'] == 5
