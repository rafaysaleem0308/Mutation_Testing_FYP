"""Simple test runner to execute unit checks without pytest.
This allows verification of core tests in environments where pytest/venv
installation fails. It is NOT a replacement for pytest for the assignment,
but useful as a fallback executed here.
"""
from ai_analysis import analyze_user_input


def assert_equal(a, b, msg=None):
    if a != b:
        raise AssertionError(msg or f"Expected {a} == {b}")


def test_currency_and_days_simple():
    text = "I have 3,000 rupees for 7 days for food"
    r = analyze_user_input(text)
    assert_equal(r['budget'], 3000.0)
    assert_equal(r['days'], 7)
    assert_equal(r['category'], 'meal')
    assert_equal(r['success'], True)


def test_weeks_multiplier():
    text = "I have 2 weeks and 2000 rupees food"
    r = analyze_user_input(text)
    assert_equal(r['days'], 14)


def test_missing_numbers():
    text = "I want suggestions"
    r = analyze_user_input(text)
    assert_equal(r['budget'], None)
    assert_equal(r['days'], None)
    assert_equal(r['success'], False)


if __name__ == '__main__':
    tests = [
        test_currency_and_days_simple,
        test_weeks_multiplier,
        test_missing_numbers,
    ]
    for t in tests:
        try:
            t()
            print(f"PASS: {t.__name__}")
        except Exception as e:
            print(f"FAIL: {t.__name__} -> {e}")
            raise
    print("All fallback tests passed")
