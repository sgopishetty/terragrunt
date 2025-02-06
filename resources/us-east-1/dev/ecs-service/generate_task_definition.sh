#!/bin/bash

TEMPLATE_FILE="${1}"
OUTPUT_FILE="${2}"
COMMIT_SHA="${3}"
NAME="${4}"

cat <<EOF > ${OUTPUT_FILE}
[
  {
    "name": "${NAME}",
    "image": "976193232529.dkr.ecr.us-east-1.amazonaws.com/flaskapp:${COMMIT_SHA}",
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
        "containerPort": 443,
        "hostPort": 443,
        "protocol": "tcp"
      }
    ]
  },
  {
    "name": "${NAME}-old",
    "image": "976193232529.dkr.ecr.us-east-1.amazonaws.com/flaskapp:c9c226becccfbce453ed98568908dcf0b8ac0d4a",
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
