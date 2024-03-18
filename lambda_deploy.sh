#!/bin/bash

# This script is used to deploy a Python application to AWS Lambda.
# Usage: ./lambda_deploy.sh <app_directory> <lambda_function_name> <region>

# Check if the correct number of arguments were provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <app_directory> <lambda_function_name> <region>"
    exit 1
fi

# Assign arguments to variables for easier access
app_dir=$1
lambda_function_name=$2
region=$3

# Define the name of the deployment package
package_name="app.zip"

# Clean-up any existing deployment package and package directory
echo "Cleaning up..."
rm -f $package_name
rm -rf package

# Install Python dependencies into the package directory
echo "Installing dependencies..."
pip3 install --python-version 3.9 --platform manylinux2014_x86_64 --only-binary=:all: --implementation cp --target ./package -r $app_dir/requirements.txt

# Check if pip3 install was successful
if [ "$?" -ne 0 ]; then
    echo "Error installing dependencies"
    exit 1
fi

# Create the deployment package
echo "Creating deployment package..."
cd package
zip -r ../$package_name .
cd ../$app_dir
zip ../$package_name . -r
cd ..

# Clean up the package directory
rm -rf package

# Deploy the package to AWS Lambda
echo "Deploying to AWS Lambda..."
aws lambda update-function-code --region $region --function-name $lambda_function_name --zip-file fileb://$package_name

# Check if aws lambda update-function-code was successful
if [ "$?" -ne 0 ]; then
    echo "Error deploying to AWS Lambda"
    exit 1
fi

echo "Deployment successful!"