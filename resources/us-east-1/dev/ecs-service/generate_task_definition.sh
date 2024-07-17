#!/bin/bash

TEMPLATE_FILE="${1}"
OUTPUT_FILE="${2}"
COMMIT_SHA="${3}"
NAME="${4}"

cat <<EOF > ${OUTPUT_FILE}
[
  {
    "name": "${NAME}",
    "image": "public.ecr.aws/ecs-sample-image/amazon-ecs-sample:${COMMIT_SHA}",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/epia/${NAME}",
        "awslogs-region": "us-east-1",
        "awslogs-create-group": "true",
        "awslogs-stream-prefix": "${NAME}"
      }
    },
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80,
        "protocol": "tcp"
      }
    ],
    "enable_cloudwatch_logging": "true",
    "create_cloudwatch_log_group": "true",
    "cloudwatch_log_group_name": "/aws/ecs/${NAME}",
    "cloudwatch_log_group_retention_in_days": "7"
  }
]
EOF
