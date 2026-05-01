"""Simple test runner to execute unit checks without pytest.
This allows verification of core tests in environments where pytest/venv
installation fails. It is NOT a replacement for pytest for the assignment,
but useful as a fallback executed here.
"""
from ai_analysis import analyze_user_input


def assert_equal(a, b, msg=None):
    if a != b:
        raise AssertionError(msg or f"Expected {a} == {b}")


def assert_true(a, msg=None):
    if not a:
        raise AssertionError(msg or f"Expected {a} to be True")


def assert_false(a, msg=None):
    if a:
        raise AssertionError(msg or f"Expected {a} to be False")


def test_currency_and_days_simple():
    text = "I have 3,000 rupees for 7 days for food"
    r = analyze_user_input(text)
    assert_equal(r['budget'], 3000.0)
    assert_equal(r['days'], 7)
    assert_equal(r['category'], 'meal')
    assert_true(r['success'])


def test_weeks_multiplier():
    text = "I have 2 weeks and 2000 rupees food"
    r = analyze_user_input(text)
    assert_equal(r['days'], 14, f"Expected 14 days, got {r['days']}")


def test_months_multiplier():
    text = "I have 1 month and 5000 rupees maintenance"
    r = analyze_user_input(text)
    assert_equal(r['days'], 30, f"Expected 30 days (1 month), got {r['days']}")


def test_missing_numbers():
    text = "I want suggestions"
    r = analyze_user_input(text)
    assert_equal(r['budget'], None)
    assert_equal(r['days'], None)
    assert_false(r['success'])


def test_success_flag_requires_both():
    # Only budget, no days
    text = "I have 3000 rupees"
    r = analyze_user_input(text)
    assert_false(r['success'], "success should be False if days missing")
    
    # Only days, no budget
    text = "I need 5 days"
    r = analyze_user_input(text)
    assert_false(r['success'], "success should be False if budget missing")


def test_category_meal():
    text = "I need meal planning"
    r = analyze_user_input(text)
    assert_equal(r['category'], 'meal')


def test_category_laundry():
    text = "I need laundry services"
    r = analyze_user_input(text)
    assert_equal(r['category'], 'laundry')


def test_category_maintenance():
    text = "I need repair and electrician services"
    r = analyze_user_input(text)
    assert_equal(r['category'], 'maintenance')


def test_category_default():
    text = "I need help with something"
    r = analyze_user_input(text)
    assert_equal(r['category'], 'meal', "default category should be 'meal'")


def test_week_multiplier_exact():
    text = "3 weeks and 1000 rupees meal"
    r = analyze_user_input(text)
    assert_equal(r['days'], 21, f"3 weeks = 21 days, got {r['days']}")


def test_month_multiplier_exact():
    text = "2 months and 5000 rupees maintenance"
    r = analyze_user_input(text)
    assert_equal(r['days'], 60, f"2 months = 60 days, got {r['days']}")


def test_day_multiplier():
    text = "5 days and 2000 rupees laundry"
    r = analyze_user_input(text)
    assert_equal(r['days'], 5, f"5 days should remain 5, got {r['days']}")


def test_budget_with_comma():
    text = "I have 10,000 rupees for 7 days"
    r = analyze_user_input(text)
    assert_equal(r['budget'], 10000.0)


def test_budget_without_comma():
    text = "I have 5000 rupees for 3 days"
    r = analyze_user_input(text)
    assert_equal(r['budget'], 5000.0)


def test_rupees_variations():
    text1 = "I have 2000 rupees for 5 days"
    r1 = analyze_user_input(text1)
    assert_equal(r1['budget'], 2000.0)
    
    text2 = "I have 3000 rupee for 4 days"
    r2 = analyze_user_input(text2)
    assert_equal(r2['budget'], 3000.0)
    
    text3 = "I have 1500 rs. for 2 days"
    r3 = analyze_user_input(text3)
    assert_equal(r3['budget'], 1500.0)


def test_large_budget():
    text = "I have 100,000 rupees for 30 days"
    r = analyze_user_input(text)
    assert_equal(r['budget'], 100000.0)


def test_zero_days_boundary():
    text = "I have 0 days and 1000 rupees"
    r = analyze_user_input(text)
    assert_equal(r['days'], 0)
    assert_equal(r['budget'], 1000.0)
    assert_true(r['success'])


def test_currency_order():
    text = "I need rupees 3000 for 5 days"
    r = analyze_user_input(text)
    assert_equal(r['budget'], 3000.0)


def test_case_insensitivity():
    text = "I have 2000 RUPEES for 7 DAYS for MEAL"
    r = analyze_user_input(text)
    assert_equal(r['budget'], 2000.0)
    assert_equal(r['days'], 7)
    assert_equal(r['category'], 'meal')
    assert_true(r['success'])


def test_category_priority():
    text = "I need meal preparation and laundry services"
    r = analyze_user_input(text)
    assert_equal(r['category'], 'meal')


def test_urdu_keywords():
    text = "I need khana for 5 din"
    r = analyze_user_input(text)
    assert_equal(r['category'], 'meal')
    assert_equal(r['days'], 5)


if __name__ == '__main__':
    tests = [
        test_currency_and_days_simple,
        test_weeks_multiplier,
        test_months_multiplier,
        test_missing_numbers,
        test_success_flag_requires_both,
        test_category_meal,
        test_category_laundry,
        test_category_maintenance,
        test_category_default,
        test_week_multiplier_exact,
        test_month_multiplier_exact,
        test_day_multiplier,
        test_budget_with_comma,
        test_budget_without_comma,
        test_rupees_variations,
        test_large_budget,
        test_zero_days_boundary,
        test_currency_order,
        test_case_insensitivity,
        test_category_priority,
        test_urdu_keywords,
    ]
    failed = 0
    for t in tests:
        try:
            t()
            print(f"✓ {t.__name__}")
        except Exception as e:
            print(f"✗ {t.__name__} -> {e}")
            failed += 1
    
    if failed == 0:
        print(f"\nAll {len(tests)} tests passed! ✓")
    else:
        print(f"\n{failed}/{len(tests)} tests failed.")
        exit(1)
