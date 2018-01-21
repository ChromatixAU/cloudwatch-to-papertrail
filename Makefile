PAPERTRAIL_HOST ?= logs.papertrailapp.com
PAPERTRAIL_PORT ?= 1234
LAMBDA_NAME ?= system_name
LOG_GROUP ?= log_group_name
WAIT_FOR_FLUSH ?= false

ALNUM_LOG_GROUP = $(shell echo $(LOG_GROUP) | sed 's/[^[:alnum:]]/_/g')
AWS_ACCOUNT_ID = $(shell aws sts get-caller-identity --output text --query Account)

all: lambda log

deps:
	rm -rf node_modules
	yarn

env:
	rm -f env.json
	echo "{\"papertrailHost\": \"$(PAPERTRAIL_HOST)\", \"papertrailPort\": $(PAPERTRAIL_PORT), \"lambdaName\": \"$(LAMBDA_NAME)\", \"logGroup\": \"$(LOG_GROUP)\", \"waitForFlush\": $(WAIT_FOR_FLUSH)}" > env.json

create-zip:
	rm -f code.zip
	zip code.zip -r index.js env.json node_modules

lambda: deps env create-zip
	aws lambda create-function --publish \
	--function-name $(LAMBDA_NAME) \
	--runtime nodejs4.3 \
	--handler index.handler \
	--zip-file fileb://code.zip \
	--role arn:aws:iam::$(AWS_ACCOUNT_ID):role/lambda_basic_execution

deploy: deps env create-zip
	aws lambda update-function-code --publish \
	--function-name $(LAMBDA_NAME) \
	--zip-file fileb://code.zip

log:
	aws lambda add-permission \
	--function-name $(LAMBDA_NAME) \
	--statement-id $(ALNUM_LOG_GROUP)__$(LAMBDA_NAME) \
	--principal logs.$(AWS_DEFAULT_REGION).amazonaws.com \
	--action lambda:InvokeFunction \
	--source-arn arn:aws:logs:$(AWS_DEFAULT_REGION):$(AWS_ACCOUNT_ID):log-group:$(LOG_GROUP):* \
	--source-account $(AWS_ACCOUNT_ID)

	aws logs put-subscription-filter \
	--log-group-name $(LOG_GROUP) \
	--destination-arn arn:aws:lambda:$(AWS_DEFAULT_REGION):$(AWS_ACCOUNT_ID):function:$(LAMBDA_NAME) \
	--filter-name LambdaStream_$(LAMBDA_NAME) \
	--filter-pattern ""

clean:
	rm -f code.zip env.json

test: env
	docker pull lambci/lambda
	docker run --name lambda --rm -v "${PWD}":/var/task lambci/lambda index.handler '{}'

destroy:
	aws lambda delete-function \
	--function-name $(LAMBDA_NAME)
