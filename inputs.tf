variable "region" {
  description = "The AWS region to deploy to"
  type        = string
}

variable "db_name" {
  description = "The name of the database to create"
  type        = string
}

variable "engine" {
    description = "The database engine to use"
    type        = string
}

variable "db_family" {
    description = "The family of the DB parameter group"
    type        = string
}

variable "major_engine_version" {
    description = "The major version of the engine"
    type        = string
}

variable "s3_bucket_name" {
    description = "The name of the S3 bucket to use for backups"
    type        = string
}

variable "lambda_function_name" {
    description = "The name of the lambda function"
    type        = string
}
