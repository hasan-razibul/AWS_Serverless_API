import os
from typing import List
from fastapi import FastAPI, Depends, HTTPException, UploadFile, File, Form
import uvicorn
import io
import boto3
from fastapi.responses import StreamingResponse
from urllib.parse import urlparse
from sqlalchemy.orm import Session
import crud
import models
import schemas
from database import SessionLocal, engine

s3_bucket_name = os.environ.get('S3_BUCKET_NAME')

models.Base.metadata.create_all(bind=engine)

app = FastAPI()


# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@app.post("/projects/", response_model=schemas.Project)
async def create_project(name: str = Form(...), description: str = Form(...), status: str = Form(...), pdf: UploadFile = File(...), db: Session = Depends(get_db)):
    db_project = crud.get_project_by_name(db, name=name)
    if db_project:
        raise HTTPException(status_code=400, detail="Name already registered")
    return crud.create_project(db=db, name=name, description=description, status=status, pdf=pdf)


@app.get("/projects/", response_model=List[schemas.Project])
async def read_projects(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    projects = crud.get_projects(db, skip=skip, limit=limit)
    return projects


@app.get("/projects/{project_id}", response_model=schemas.Project)
async def read_project(project_id: int, db: Session = Depends(get_db)):
    db_project = crud.get_project(db, project_id=project_id)
    if db_project is None:
        raise HTTPException(status_code=404, detail="Project not found")
    return db_project


@app.get("/projects/{project_id}/pdf")
async def get_project_pdf(project_id: int, db: Session = Depends(get_db)):
    db_project = crud.get_project(db, project_id=project_id)
    if db_project is None:
        raise HTTPException(status_code=404, detail="Project not found")

    object_data = crud.get_project_pdf(db, project_id)
    if object_data is None:
        raise HTTPException(status_code=400, detail="S3 credentials not found")

    response = StreamingResponse(io.BytesIO(object_data), media_type='application/pdf')
    response.headers["Content-Disposition"] = f"attachment; filename={db_project.pdf.split('/')[-1]}"
    return response


@app.put("/projects/{project_id}", response_model=schemas.Project)
async def update_project(
    project_id: int, 
    name: str = Form(None), 
    description: str = Form(None), 
    status: str = Form(None), 
    pdf: UploadFile = File(None), 
    db: Session = Depends(get_db)
):
    db_project = crud.get_project(db, project_id=project_id)
    if db_project is None:
        raise HTTPException(status_code=404, detail="Project not found")

    if name is not None:
        db_project.name = name
    if description is not None:
        db_project.description = description
    if status is not None:
        db_project.status = status
    if pdf is not None:
        s3 = boto3.client('s3')

        # delete the old file
        if db_project.pdf:
            o = urlparse(db_project.pdf)
            old_file_path = o.path.lstrip('/')
            s3.delete_object(Bucket=s3_bucket_name, Key=old_file_path)

        # upload the new file to S3
        s3.put_object(Body=await pdf.read(), Bucket=s3_bucket_name, Key=pdf.filename)

        # update the database record with the new file's URL
        db_project.pdf = f"s3://{s3_bucket_name}/{pdf.filename}"

    db.commit()
    db.refresh(db_project)
    return db_project




@app.delete("/projects/{project_id}", response_model=schemas.Project)
async def delete_project(project_id: int, db: Session = Depends(get_db)):
    db_project = crud.get_project(db, project_id=project_id)
    if db_project is None:
        raise HTTPException(status_code=404, detail="Project not found")
    
    s3 = boto3.client('s3')
    try:
        o = urlparse(db_project.pdf)
        file_path = o.path.lstrip('/')
        
        s3.delete_object(Bucket=s3_bucket_name, Key=file_path)
    except Exception as e:
        print(f"Error: {e}")
    
    return crud.delete_project(db=db, project_id=project_id)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)