import pytest
from ai_analysis import analyze_user_input


def test_analyze_user_input_currency_and_days_simple():
    text = "I have 3,000 rupees for 7 days for food"
    r = analyze_user_input(text)
    assert r['budget'] == 3000.0
    assert r['days'] == 7
    assert r['category'] == 'meal'
    assert r['success'] is True


def test_analyze_user_input_weeks_multiplier():
    text = "I have 2 weeks and 2000 rupees food"
    r = analyze_user_input(text)
    assert r['days'] == 14


def test_analyze_user_input_missing_numbers():
    text = "I want suggestions"
    r = analyze_user_input(text)
    assert r['budget'] is None
    assert r['days'] is None
    assert r['success'] is False
