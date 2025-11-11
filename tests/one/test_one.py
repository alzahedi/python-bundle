import requests
import os

def test_one():
    response = requests.get("https://api.github.com")
    print(response.json())
    print(f"Test environment variable TEST_ENV: {os.getenv('TEST_ENV')}")
    assert response.status_code == 200