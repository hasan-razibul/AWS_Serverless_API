# database.py
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from models import Base
import os
from __init__ import db_credentials

db_url = os.environ.get('DB_URL')
db_name = db_credentials['db_name']
db_username = db_credentials['db_username']
db_password = db_credentials['db_password']

DATABASE_URL = f"postgresql://{db_username}:{db_password}@{db_url}/{db_name}"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base.metadata.create_all(bind=engine)