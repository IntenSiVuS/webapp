"""
Test response
"""
from pathlib import Path

import requests

WEBAPP_URL = Path('output.txt').read_text()

WEBAPP_URL = WEBAPP_URL.replace('\n', '')

def test_webapp():
    """
    Test:
    1. App is rechable to outside world
    """
    # Reachable from outside
    resp = requests.get(WEBAPP_URL) 
    assert resp.status_code == 200
