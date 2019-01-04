#!/bin/bash

# This script is called by Travis to deploy the app for a named environment.

# Fail if ENVIRONMENT param invalid:
if ! [[ $1 =~ ^(development|qa|production) ]] ; then
  echo Aborting travis-deploy. Must specify ENVIRONMENT.
  echo Usage: ./scripts/travis-deploy ENVIRONMENT
  echo "  Where ENVIRONMENT is (development|qa|production)"
  exit
fi

ENVIRONMENT_NAME=$1

# Capitalize environment name:
ENVIRONMENT_CAPS=$(echo $ENVIRONMENT_NAME | awk '{print toupper($0)}')

# Given a REPO_SLUG like "NYPL/sync-item-metadata-to-scsb-service",
# extract just repo name (everything following slash):
REPO_NAME=${TRAVIS_REPO_SLUG##*/}

# Set AWS credentials based on which environment we're deploying to:
eval AWS_ACCESS_KEY_ID=\$AWS_ACCESS_KEY_ID_$ENVIRONMENT_CAPS
eval AWS_SECRET_ACCESS_KEY=\$AWS_SECRET_ACCESS_KEY_$ENVIRONMENT_CAPS
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY

# Validate template
sam validate --template sam.$ENVIRONMENT_NAME.yml

# Package to S3:
PACKAGE_CMD="sam package --template-file sam.$ENVIRONMENT_NAME.yml --output-template-file packaged-template.yaml --s3-bucket nypl-travis-builds-$ENVIRONMENT_NAME --s3-prefix $REPO_NAME"

echo Running package command for "$ENVIRONMENT_NAME" environment:
echo "  $PACKAGE_CMD"

eval $PACKAGE_CMD

# Deploy from S3:
DEPLOY_CMD="aws cloudformation deploy --template-file packaged-template.yaml --stack-name $REPO_NAME-$ENVIRONMENT_NAME --capabilities CAPABILITY_IAM"

echo Running deploy command for "$ENVIRONMENT_NAME" environment:
echo "  $DEPLOY_CMD"

eval $DEPLOY_CMD
