import pandas as pd
import yaml

def test_two():
    df = pd.DataFrame({"A": [1, 2], "B": [3, 4]})
    print(df)
    assert 1 + 1 == 2