import string

from sqlalchemy import ForeignKey
from sqlalchemy.sql.expression import func
from marshmallow_sqlalchemy import ModelSchema
from marshmallow import fields
from marshmallow.validate import Length, NoneOf

from api.core.database import db


class User(db.Model):

    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    email = db.Column(db.String(255), unique=True, nullable=False)
    first_name = db.Column(db.String(255), nullable=False)
    last_name = db.Column(db.String(255), nullable=False)
    password = db.Column(db.String(255), nullable=False)
    registered = db.Column(db.DateTime, nullable=False, default=func.now())
    verified = db.Column(db.DateTime)
    active = db.Column(db.Boolean, nullable=False, default=True)
    admin = db.Column(db.Boolean, nullable=False, default=False)


class UserSchema(ModelSchema):
    class Meta(ModelSchema.Meta):
        model = User
        sqla_session = db.session

    id = fields.Number(dump_only=True)
    email = fields.Email(required=True)
    first_name = fields.String(required=True, validate=[Length(2, 32), NoneOf(string.punctuation + '\t\r\n\v\f ')])
    last_name = fields.String(required=True, validate=[Length(2, 32), NoneOf(string.punctuation + '\t\r\n\v\f ')])
    name = fields.FormattedString('{} {}')
    password = fields.String(required=True)
    registered = fields.DateTime()
    verified = fields.DateTime()
    active = fields.Bool(default=True)
    admin = fields.Bool(default=False)

