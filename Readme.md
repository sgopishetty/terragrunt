## ECS Cluster Architecture Overview

The Chapi poc hosting environment on an ECS cluster involves several key components that work together to ensure high availability, scalability, and efficient resource utilization. Below are the descriptions and roles of each component:

### Key Components

1. **Auto Scaling Group (ASG)**
   - **Purpose**: Automatically scales the number of EC2 instances based on demand.
   - **Function**: Ensures the ECS cluster has sufficient compute capacity to run tasks by launching or terminating EC2 instances.
   - **Integration**: Instances in the ASG register themselves with the ECS cluster.

2. **ECS Cluster**
   - **Purpose**: Logical grouping of EC2 instances (or Fargate tasks) that run containerized applications.
   - **Function**: Manages and schedules the placement of containers across the cluster resources.
   - **Integration**: Communicates with ASG to ensure the cluster has the required capacity.

3. **Task Definition**
   - **Purpose**: Defines the container specifications, including image, CPU, memory, and ports.
   - **Function**: Blueprint for ECS tasks, specifying how containers should be run.
   - **Integration**: Used by ECS Services to create and manage tasks.

4. **ECS Service**
   - **Purpose**: Manages the deployment and scaling of a specified number of tasks from a task definition.
   - **Function**: Ensures the desired number of tasks are running and replaces failed tasks.
   - **Integration**: Works with ALB to distribute traffic across tasks and integrates with the ECS cluster for resource management.

5. **Application Load Balancer (ALB)**
   - **Purpose**: Distributes incoming application traffic across multiple targets (tasks).
   - **Function**: Provides high availability and scalability by balancing the load among tasks.
   - **Integration**: Registered with ECS services to route traffic to the running tasks.

### Architecture Diagram

Here is a high-level architecture diagram of the ECS application hosting environment:

![ECS Architecture Diagram](https://example.com/path-to-diagram)

## Prerequisites for running through terragrunt

- [Terraform](https://www.terraform.io/downloads.html)
- [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/)
- SSH key configured for accessing the Terraform modules repository

## Setup SSH for Terraform Modules

To access the Terraform modules repository via SSH, you need to configure your SSH key locally and have access to modules repo : <link>

## Configure AWS CLI

1. Install the AWS CLI following the [installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Configure the AWS CLI with your credentials:
    ```sh
    aws configure
    ```
   You will be prompted to enter your AWS Access Key ID, Secret Access Key, region, and output format.

## Setup AWS Access locally

Before running terragrunt commands you need to setup below env variables or follow command

```
export AWS_ACCESS_KEY_ID=<secret>
export AWS_SECRET_ACCESS_KEY=<secret>
```

## Running Terragrunt Commands

Navigate to the appropriate resource directory and run the Terragrunt commands for each resource.

### Init

To initialize use the `init` command.

```sh
cd dev/alb/
terragrunt init
```

### Plan

To see the changes that will be applied by Terragrunt, use the `plan` command.

```sh
cd dev/alb/
terragrunt plan
```

### Apply

To see the changes that will be applied by Terragrunt, use the `plan` command.

```sh
cd dev/alb/
terragrunt apply
```

## Running Terragrunt Commands for deploying all resources at each environment level as Best Practice

Navigate to the env directory

### Init

To see the changes that will be applied by Terragrunt, use the `plan` command.

```sh
cd dev/
terragrunt run-all init
```

### Plan

To see the changes that will be applied by Terragrunt, use the `plan` command.

```sh
cd dev/
terragrunt run-all plan
```

### Apply

To see the changes that will be applied by Terragrunt, use the `plan` command.

```sh
cd dev/
terragrunt run-all apply
```