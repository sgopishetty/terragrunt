#!/bin/bash

TEMPLATE_FILE="${1}"
OUTPUT_FILE="${2}"
COMMIT_SHA="${3}"
NAME="${4}"

cat <<EOF > ${OUTPUT_FILE}
[
  {
    "name": "${NAME}",
    "image": "010526272542.dkr.ecr.us-east-1.amazonaws.com/flaskapp:${COMMIT_SHA}",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/aws/ecs/${NAME}",
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
    ]
  }
]
EOF
