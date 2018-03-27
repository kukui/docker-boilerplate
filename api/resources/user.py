from flask import jsonify, request
from flask.ext.restful import Resource

from api.models.base import db
from api.models import User as UserModel, UserSchema


class UserList(Resource):
    def get(self):
        return jsonify(data=[user.json for user in User.query])

    def post(self):
        payload = request.get_json()
        user = User(**params)
        db.session.add(user)
        db.session.commit()
        return user.json


class User(Resource):
    schema = UserSchema()

    def get(self, id):
        user = UserModel.query.get(id)
        return self.schema.dump(user).data

    def post(self):

        params = request.get_json()
        deserialized = self.schema.load(params).data
        print('deserialized: {}'.format(deserialized))
        db.session.add(deserialized)
        db.session.commit()
        return self.schema.dump(deserialized)
