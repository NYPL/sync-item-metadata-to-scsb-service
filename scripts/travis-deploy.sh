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
ENVIRONMENT_CAPS=$(echo $ENVIRONMENT_NAME | awk '{print toupper($0)}')

AWS_ACCESS_KEY_ID=$(echo "\$AWS_ACCESS_KEY_ID_$ENVIRONMENT_CAPS")
AWS_SECRET_ACCESS_KEY=$(echo "\$AWS_SECRET_ACCESS_KEY_$ENVIRONMENT_CAPS")

sam validate --template sam.$ENVIRONMENT_NAME.yml
PACKAGE_CMD=$(echo "sam package --template-file sam.$ENVIRONMENT_NAME.yml --output-template-file packaged-template.yaml")

echo Running package command for "$ENVIRONMENT_NAME" environment:
echo "  $PACKAGE_CMD"

# TODO: Need to make stack-name dynamic
DEPLOY_CMD=$(echo "aws cloudformation deploy --template-file packaged-template.yaml --stack-name sync-item-metadata-to-scsb-service-$ENVIRONMENT_NAME --capabilities CAPABILITY_IAM --s3-bucket nypl-travis-builds-$ENVIRONMENT_NAME")

echo Running deploy command for "$ENVIRONMENT_NAME" environment:
echo "  $DEPLOY_CMD"

# Execute command:
eval $DEPLOY_CMD
