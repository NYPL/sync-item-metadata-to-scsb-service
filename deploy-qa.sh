sam package --region us-east-1 --template-file sam.qa.yml --output-template-file packaged-template.yaml --profile nypl-digital-dev --s3-bucket nypl-travis-builds-qa

aws cloudformation deploy --template-file packaged-template.yaml --stack-name sync-item-metadata-to-scsb-service-qa --profile nypl-digital-dev --region us-east-1 --capabilities CAPABILITY_IAM
