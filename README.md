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

 * Cut branches from `development`.
 * Create PR against `development`.
 * After review, PR author merges.
 * Merge `development` > `qa`
 * Merge `qa` > `master`
 * Tag version bump in `master`

### Running events locally

```
sam local invoke --event event.json --region us-east-1 --template sam.[ENVIRONMENT].yml --profile [aws profile]
```

Note that the AWS profile used must be able to decrypt the `SQS_QUEUE_URL` value in your chosen sam file.

A sample `sam.local.yml` includes an `SQS_QUEUE_URL` parameter encrypted using the `nypl-digital-dev` account, which decrypts to "http://host.docker.internal:4576/queue/sierra-updates-for-scsb-local".

When populating an SQS queue, the `aws sqs` cli tool may be useful for inspecting the messages written. For example, when populating a localstack SQS, run the following to pop the last 10 messages:

```
aws sqs --endpoint http://localhost:4576 --profile local receive-message --region us-east-1 --queue-url http://localhost:4576/queue/sierra-updates-for-scsb-local --attribut-names All --message-attribute-names All --max-number-of-messages 10
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
