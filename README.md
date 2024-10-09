# Sync Item Metadata to SCSB Service

This is a small Ruby app deployed as an AWS Lambda behind API Gateway to serve the following:

```
POST /api/v0.1/recap/sync-item-metadata-to-scsb
```

## Setup

### Installation

```
bundle install; bundle install --deployment
```

### Setup

All config is in sam.[ENVIRONMENT].yml templates, encrypted as necessary.

## Contributing

### Git Workflow

This app uses [Main-QA-Production workflow](https://github.com/NYPL/engineering-general/blob/main/standards/git-workflow.md#main-qa-production)

### Running events locally

The following will invoke the lambda against the sample `event.json`
```
AWS_ACCESS_KEY_ID=[your access key id] AWS_SECRET_ACCESS_KEY=[your secret access key] sam local invoke --event event.json --region us-east-1 --template sam.qa.yml --profile nypl-digital-dev
```

Note that the AWS profile used must be able to decrypt the `SQS_QUEUE_URL` value in your chosen sam file.

A sample `sam.local.yml` includes an `SQS_QUEUE_URL` parameter encrypted using the `nypl-digital-dev` account, which decrypts to "http://host.docker.internal:4576/queue/sierra-updates-for-scsb-local".

When populating an SQS queue, the `aws sqs` cli tool may be useful for inspecting the messages written. For example, when populating a localstack SQS, run the following to pop the last 10 messages:

```
aws sqs --endpoint http://localhost:4576 --profile local receive-message --region us-east-1 --queue-url http://localhost:4576/queue/sierra-updates-for-scsb-local --attribut-names All --message-attribute-names All --max-number-of-messages 10
```

Update `event.json` as follows:

```
sam local generate-event apigateway aws-proxy --path api/v0.1/recap/sync-item-metadata-to-scsb --method POST --body "{ \"barcodes\": [ \"01234567891011\" ], \"user_email\": \"email@example.com\"}" > event.json
```

### Running server locally

To run the server locally:

```
sam local start-api --region us-east-1 --template sam.[ENVIRONMENT].yml --profile [aws profile]
```

### Gemfile Changes

Given that gems are installed with the `--deployment` flag, Bundler will complain if you make changes to the Gemfile. To make changes to the Gemfile, exit deployment mode:

```
bundle install --no-deployment
```

## Testing

```
bundle exec rspec
```

## Deploy

Deployments are entirely handled by Github Actions. To deploy to qa or production, `qa`, and `production` branches on origin, respectively.
