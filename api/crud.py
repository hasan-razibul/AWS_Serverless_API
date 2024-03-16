from typing import Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException, UploadFile
import models, schemas
import boto3
import os
from botocore.exceptions import NoCredentialsError
from urllib.parse import urlparse

bucket_name = os.environ.get('S3_BUCKET_NAME')

s3 = boto3.client("s3")

def get_project_by_name(db: Session, name: str):
    return db.query(models.Project).filter(models.Project.name == name).first()

def create_project(db: Session, name: str, description: str, status: str, pdf: UploadFile):
    s3.upload_fileobj(pdf.file, bucket_name, pdf.filename)
    file_location = f"s3://{bucket_name}/{pdf.filename}"
    db_project = models.Project(name=name, description=description, status=status, pdf=file_location)
    db.add(db_project)
    db.commit()
    db.refresh(db_project)
    return db_project

def get_projects(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.Project).offset(skip).limit(limit).all()

def get_project(db: Session, project_id: int):
    return db.query(models.Project).filter(models.Project.id == project_id).first()

def get_project_pdf(db: Session, project_id: int):
    db_project = db.query(models.Project).filter(models.Project.id == project_id).first()
    if db_project is None:
        return None
    file_name = db_project.pdf.split('/')[-1]
    try:
        s3_response_object = s3.get_object(Bucket=bucket_name, Key=file_name)
        object_data = s3_response_object['Body'].read()
        return object_data
    except NoCredentialsError:
        raise HTTPException(status_code=400, detail="S3 credentials not found")


def update_project(db: Session, project_id: int, project: schemas.ProjectCreate, pdf: Optional[UploadFile] = None):
    db_project = db.query(models.Project).filter(models.Project.id == project_id).first()
    if db_project is None:
        return None
    update_data = project.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_project, key, value)
    if pdf:
        s3 = boto3.client('s3')
        if db_project.pdf:
            o = urlparse(db_project.pdf)
            old_file_path = o.path.lstrip('/')
            s3.delete_object(Bucket=bucket_name, Key=old_file_path)
        s3.upload_fileobj(pdf.file, bucket_name, pdf.filename)
        file_location = f"s3://{bucket_name}/{pdf.filename}"
        db_project.pdf = file_location
    db.commit()
    db.refresh(db_project)
    return db_project


def delete_project(db: Session, project_id: int):
    db_project = db.query(models.Project).filter(models.Project.id == project_id).first()
    if db_project is None:
        return None
    db.delete(db_project)
    db.commit()
    return db_project
