#!/usr/bin/python
# -*- coding: utf-8 -*-

import logging
import os
import sys

from flask import Flask
from flask import jsonify
from flask_swagger import swagger
from flask_restful import Api
from werkzeug.debug import DebuggedApplication
from api.core.database import db
from api.core.responses import response_with
import api.core.responses as resp
from api.resources.user import User, UserList


def create_app():

    app = Flask('app')
    app.config.from_envvar('API_CONFIG')
    if app.debug:
        app.wsgi_app = DebuggedApplication(app.wsgi_app, True)

    api = Api(app)

    # START GLOBAL HTTP CONFIGURATIONS
    @app.after_request
    def add_header(response):
        return response

    @app.errorhandler(400)
    def bad_request(e):
        logging.error(e)
        return response_with(resp.BAD_REQUEST_400)

    @app.errorhandler(500)
    def server_error(e):
        logging.error(e)
        return response_with(resp.SERVER_ERROR_500)

    @app.errorhandler(404)
    def not_found(e):
        logging.error(e)
        return response_with(resp.NOT_FOUND_HANDLER_404)

    # END GLOBAL HTTP CONFIGURATIONS

    @app.route("/api/v1/spec")
    def spec():
        swag = swagger(app, prefix='/api/v1')
        swag['info']['version'] = "1"
        swag['info']['title'] = "Flask Starter API"
        return jsonify(swag)



    @app.route('/api/help', methods=['GET'])
    def help():
        """Print available functions."""
        func_list = {}
        for rule in api.url_map.iter_rules():
            if rule.endpoint != 'static':
                func_list[rule.rule] = api.view_functions[rule.endpoint].__doc__
        return jsonify(func_list)


    logging.basicConfig(stream=sys.stdout,
                        format='%(asctime)s|%(levelname)s|%(filename)s:%(lineno)s|%(message)s',
                        level=logging.DEBUG)

    api.add_resource(User, '/api/v1/user/<int:id>')
    api.add_resource(UserList, '/api/v1/users')

    db.init_app(app)
    with app.app_context():
        db.create_all()
    return app
