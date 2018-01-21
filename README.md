# cloudwatch-to-papertrail

Lambda to send logs from AWS CloudWatch to Papertrail.

Originally [written by Apiary Inc](https://github.com/apiaryio/cloudwatch-to-papertrail). This is a forked and modified version, modified mainly to remove Datadog (so it's just CW to PT and nothing else), move from npm to Yarn, and tweaks to environment variables. I also attempt to send the name of the CloudWatch log group to Papertrail as the program name, to help you out when you're logging multiple groups. And there's a Node version upgrade (6.10) and the LambCI Lambda Docker image is working for testing.

Other than that, most of the original script still remains and is just as easy to install: simply clone the repo and follow the instructions below.

## Usage

First, ensure an IAM role exists called `lambda_basic_execution`, with the `AWSLambdaBasicExecutionRole` policy.

Then, create a Lambda function that streams logs from the specified log group to this function:

```bash
$ export AWS_DEFAULT_REGION=us-east-1
$ export PAPERTRAIL_HOST=logs.papertrailapp.com PAPERTRAIL_PORT=1234
$ LAMBDA_NAME=lambda LOG_GROUP=/aws/lambda/log_group_name make
```

Or to update an existing Lambda function:

```bash
$ export PAPERTRAIL_HOST=logs.papertrailapp.com PAPERTRAIL_PORT=1234
$ LAMBDA_NAME=lambda make deploy
```

To stream another log group to an already existing Lambda function:

```bash
$ export AWS_DEFAULT_REGION=us-east-1
$ LAMBDA_NAME=lambda LOG_GROUP=/aws/lambda/another_log_group_name make log
```

By default, we force Lambda to wait for the event loop to empty before shutting down the function. This means logs will be sent immediately to Papertrail, at the expense of longer Lambda execution times, rather than quitting the function immediately and potentially making logs wait for future invocations (which possibly also results in logs being missed). See [callbackWaitsForEmptyEventLoop](http://docs.aws.amazon.com/lambda/latest/dg/nodejs-prog-model-context.html) for details.

To reverse this behavior and instead prioritise _shorter execution times_ over _guaranteed delivery_, set `WAIT_FOR_FLUSH=false`, i.e.
```bash
$ LAMBDA_NAME=lambda WAIT_FOR_FLUSH=false make deploy
```

(The default `WAIT_FOR_FLUSH` value here is the opposite of [Apiary's original version](https://github.com/apiaryio/cloudwatch-to-papertrail) of this function).

To test the function outside of Lambda, ensure you have Docker running, then run `make test`. This will use [LambCI's Docker Lambda environment](https://github.com/lambci/docker-lambda). If you need to debug any issues with the function, set `CWTP_DEBUG=true` to log data to the console, i.e.
```bash
$ CWTP_DEBUG=true make test
```

## License

[MIT](LICENSE).