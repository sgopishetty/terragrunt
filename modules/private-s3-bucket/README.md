# Private S3 Bucket

This module can be used to create and manage an [Amazon S3](https://aws.amazon.com/s3/) bucket that enforces 
best practices for private access:

- No public access: all public access is completely blocked.
- Encryption at rest: server-side encryption is enabled, optionally with a custom KMS key.
- Encryption in transit: the bucket can only be accessed over TLS.



## How do you use this module?

* Check out the [private-s3-bucket example](/examples/private-s3-bucket) for working sample code.
* Check out [`variables.tf`](variables.tf) for all the configuration parameters you can set. 

## How do you enable MFA Delete?

Enabling MFA Delete in your bucket adds another layer of security by requiring MFA in any request to delete a version or change the versioning state of the bucket.

The attribute `mfa_delete` is only used by Terraform to [reflect the current state of the bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket#mfa_delete). It is not possible to create a bucket if the `mfa_delete` is `true`, because it needs to be activated [using AWS CLI or the API](https://docs.aws.amazon.com/AmazonS3/latest/userguide/MultiFactorAuthenticationDelete.html).

To make this change [**you need to use the root user of the account**](https://docs.aws.amazon.com/general/latest/gr/root-vs-iam.html#aws_tasks-that-require-root) that owns the bucket, and MFA needs to be enabled.

**Note:** We do not recommend you have active access keys for the root user, so remember to delete them after you finish this.

In order to enable MFA Delete, you need to:
1. [Create access keys for the root user](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_root-user.html#id_root-user_manage_add-key)
1. [Configure MFA for the root user](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_root-user.html#id_root-user_manage_mfa)
1. Create a bucket with `mfa_delete=false`.
1. Using the root user, call the AWS CLI to enable MFA Delete. If you are using `aws-vault`, it is necessary to [use the `--no-session` flag](https://github.com/99designs/aws-vault/blob/7d912c9/USAGE.md#using---no-session).
    ```
   aws s3api put-bucket-versioning --region <REGION> \
    --bucket <BUCKET NAME> \
    --versioning-configuration Status=Enabled,MFADelete=Enabled \
    --mfa "arn:aws:iam::<ACCOUNT ID>:mfa/root-account-mfa-device <MFA CODE>"
    ```
1. Set `mfa_delete=true` in your Terraform code
1. Remove any Lifecycle Rule that the bucket might contain (for the `aws-config-bucket` and `cloudtrail-bucket` modules, enabling `mfa_delete` will already disable the lifecycle rules).
1. Run `terraform apply`.
1. If there are no left S3 buckets to enable MFA Delete, delete the access keys for the root user, but NOT the MFA.

**Note:** If you are using `aws-vault` to authenticate your requests, you need to use the `--no-session` flag.

### Using mfa-delete.sh

If you want to enable MFA Delete to _all_ your buckets at once, you can use the script at `mfa-delete-script/mfa-delete.sh`. You need to use the access keys for the root user and the root MFA code.

Usage:
```
aws-vault exec --no-session <PROFILE> -- ./mfa-delete.sh --account-id <ACCOUNT ID>
```

Example:
```
aws-vault exec --no-session root-prod -- ./mfa-delete.sh --account-id 226486542153
```

### Known Issues

* `An error occurred (InvalidRequest) when calling the PutBucketVersioning operation: DevPay and Mfa are mutually exclusive authorization methods`: If you receive this error when running any of the commands/scripts above then you might not be authenticated as the root user or MFA may not be enabled correctly. If you are using `aws-vault` to authenticate your requests, you need to use the `--no-session` flag.

