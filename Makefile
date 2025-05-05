# Variables
CLUSTER_NAME = minecraft-servers
REGION = eu-central-1
SERVICE_NAME = minecraft-vanilla

# Targets
.PHONY: start stop get-dns connect help

start:
	@echo "Starting Fargate service $(SERVICE_NAME)..."
	aws ecs update-service --cluster $(CLUSTER_NAME) --service $(SERVICE_NAME) --desired-count 1 --region $(REGION) --no-cli-pager

stop:
	@echo "Stopping Fargate service $(SERVICE_NAME)..."
	aws ecs update-service --cluster $(CLUSTER_NAME) --service $(SERVICE_NAME) --desired-count 0 --region $(REGION) --no-cli-pager

get-dns:
	@echo "Retrieving NLB DNS name..."
	@NLB_DNS=$$(aws elbv2 describe-load-balancers --names minecraft-nlb --region $(REGION) --query "LoadBalancers[0].DNSName" --output text); \
	if [ "$$NLB_DNS" != "None" ]; then \
		echo "NLB DNS: $$NLB_DNS"; \
	else \
		echo "No NLB found with name 'minecraft-nlb'."; \
	fi

connect:
	@echo "Connecting to Fargate container..."
	@TASK_ARN=$$(aws ecs list-tasks --cluster $(CLUSTER_NAME) --service-name $(SERVICE_NAME) --region $(REGION) --query "taskArns[0]" --output text); \
	if [ "$$TASK_ARN" != "None" ]; then \
		aws ecs execute-command --cluster $(CLUSTER_NAME) --task "$$TASK_ARN" --container $(SERVICE_NAME)-task --command "/bin/bash" --interactive --region $(REGION); \
	else \
		echo "No running tasks found for service $(SERVICE_NAME)."; \
	fi

# Default target
.DEFAULT_GOAL := help

help:
	@echo "Usage:"
	@echo "  make start    - Start the Fargate service"
	@echo "  make stop     - Stop the Fargate service"
	@echo "  make get-dns  - Get the NLB public DNS name"
	@echo "  make connect  - Open an interactive session with the Fargate container"
