"""
Lightweight extraction of `analyze_user_input` for mutation-testing scaffolding.
This module mirrors the parsing logic from `app.py` but avoids heavy runtime
dependencies (spaCy, pandas) so tests and mutation runs are easier to execute.
Use this as the primary unit under test for initial assignment work.
"""
import re
from typing import Dict


EXCHANGE_RATES = {
    'INR_TO_PKR': 3.3,
    'USD_TO_PKR': 278.0
}


def analyze_user_input(text: str) -> Dict:
    """
    Parse free text to extract budget, days, and category.
    This is intentionally implemented without spaCy to keep tests fast.
    Returns: {budget, days, category, original_text, success}
    """
    try:
        budget = None
        days = None

        # Budget regex patterns
        budget_patterns = [
            r'([\d,]+)\s*(?:rupees?|rs\.?|pkr)',
            r'(?:rupees?|rs\.?|pkr)\s+([\d,]+)'
        ]

        for pattern in budget_patterns:
            match = re.search(pattern, text.lower())
            if match:
                budget = float(match.group(1).replace(',', ''))
                break

        # Duration patterns with multipliers (days, weeks, months)
        duration_patterns = [
            (r'(\d+)\s*(?:days?|din)', 1),
            (r'(\d+)\s*(?:weeks?|hafte)', 7),
            (r'(\d+)\s*(?:months?|mahine)', 30),
        ]

        for pattern, multiplier in duration_patterns:
            match = re.search(pattern, text.lower())
            if match:
                days = int(match.group(1)) * multiplier
                break

        # Category keywords
        category = 'meal'
        category_keywords = {
            'meal': ['meal', 'food', 'eat', 'khana', 'dinner', 'lunch', 'breakfast'],
            'laundry': ['laundry', 'wash', 'clothes', 'dhobi', 'kapray'],
            'maintenance': ['maintenance', 'repair', 'plumber', 'electrician'],
        }

        text_lower = text.lower()
        for cat, keywords in category_keywords.items():
            if any(keyword in text_lower for keyword in keywords):
                category = cat
                break

        return {
            'budget': budget,
            'days': days,
            'category': category,
            'original_text': text,
            'success': budget is not None and days is not None
        }
    except Exception as e:
        return {
            'budget': None,
            'days': None,
            'category': 'meal',
            'original_text': text,
            'success': False,
            'error': str(e)
        }
