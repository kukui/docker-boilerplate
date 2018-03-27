import sys
from flask import request, url_for


def test_valid_user(client):
    print('url_for: {}'.format(url_for('user', id=1)))
    resp = client.get(url_for('user',id=1))
    print('resp: {}'.format(dir(resp)))
    assert resp.status_code == 200

