# cloudwatch-to-papertrail
Lambda to send logs from Cloudwatch to Papertrail

## Usage

First, ensure an IAM role exists called `lambda_basic_execution`,
with the `AWSLambdaBasicExecutionRole` policy.

Then create lambda function and streams logs from the specified log group to this function:

```bash
$ export AWS_DEFAULT_REGION=us-east-1
$ export PAPERTRAIL_HOST=logs.papertrailapp.com PAPERTRAIL_PORT=1234
$ LAMBDA_NAME=lambda LOG_GROUP=/aws/lambda/log_group_name make
```

To update existing lambda function:

```bash
$ export PAPERTRAIL_HOST=logs.papertrailapp.com PAPERTRAIL_PORT=1234
$ LAMBDA_NAME=lambda make deploy
```

To stream another log group to already existing lambda:

```bash
$ export AWS_DEFAULT_REGION=us-east-1
$ LAMBDA_NAME=lambda LOG_GROUP=/aws/lambda/another_log_group_name make log
```

By default, lambda doesn't wait for the event loop to empty before shutting down the function.
This means logs may not be sent immediately to papertrail, but instead wait for future
invocations.  It's also possible some logs may not get sent to papertrail at all. See
[callbackWaitsForEmptyEventLoop](http://docs.aws.amazon.com/lambda/latest/dg/nodejs-prog-model-context.html)

To override this behavior, set `WAIT_FOR_FLUSH=true`, i.e.
```bash
$ LAMBDA_NAME=lambda WAIT_FOR_FLUSH=true make deploy
```

Logs will be sent immediately to papertrail, at the expense of longer lambda execution times.
