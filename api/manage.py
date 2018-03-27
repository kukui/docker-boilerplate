# manage.py
'''
Management script for organizing commands one of which is
the command for running the server.
Required environment variables:
API_CONFIG: path to the configuration file
'''
import os

from flask.cli import FlaskGroup

from api.core.database import db
from api.core.factory import create_app

import pytest

# set FLASK_APP to this file. It's needed by the FlaskGroup instance
# when called without a create_app keyword argument. This smells like
# magic but the other option is to constrain the arguments to our
# create_app in order to play nicely with flask.cli viz ScripInfo.

os.environ['FLASK_APP'] = __file__
cli = FlaskGroup()
app = create_app()


@app.shell_context_processor
def make_shell_context():
    from api import models
    return dict(app=app, db=db, models=models)


@cli.command()
def create_db():
    db.drop_all()
    db.create_all()
    db.session.commit()


@cli.command()
def drop_db():
    """Drops the db tables."""
    db.drop_all()


@cli.command()
def create_admin():
    """Creates the admin user."""
    db.session.add(User(email='ad@min.com', password='admin', admin=True))
    db.session.commit()


@cli.command()
def create_data():
    """Creates sample data."""
    pass


@cli.command()
def test():
    pytest.main()


@cli.command()
def cov():
    """Runs the unit tests with coverage."""
    tests = unittest.TestLoader().discover('project/tests')
    result = unittest.TextTestRunner(verbosity=2).run(tests)
    if result.wasSuccessful():
        COV.stop()
        COV.save()
        print('Coverage Summary:')
        COV.report()
        COV.html_report()
        COV.erase()
        return 0
    return 1


@cli.command()
def runserver():
    """Runs the app server."""
    app.run(port=5000, host="0.0.0.0", use_reloader=False)


if __name__ == '__main__':
    cli.main()
