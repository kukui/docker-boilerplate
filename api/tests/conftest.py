import os
from api.core.factory import create_app

import pytest

@pytest.fixture
def api():
    return create_app()
