# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED MODULE PARAMETERS
# These variables must be passed in by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "What to name the S3 bucket. Note that S3 bucket names must be globally unique across all AWS users!"
  type        = string
}

variable "acl" {
  # Possible canned ACLs: https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#canned-acl
  description = "The canned ACL to apply. This can be 'null' if you don't want to use ACLs. See comment above for the list of possible ACLs. If not `null` bucket_ownership cannot be BucketOwnerEnforced"
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# These variables have default values that can be optionally modified.
# ---------------------------------------------------------------------------------------------------------------------

variable "bucket_policy_statements" {
  # The bucket policy statements for this S3 bucket. See the 'statement' block in the aws_iam_policy_document data
  # source for context: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document
  #
  # bucket_policy_statements is a map where the keys are the statement IDs (SIDs) and the values are objects that can
  # define the following properties:
  #
  # - effect                                      string            (optional): Either "Allow" or "Deny", to specify whether this statement allows or denies the given actions.
  # - actions                                     list(string)      (optional): A list of actions that this statement either allows or denies. For example, ["s3:GetObject", "s3:PutObject"].
  # - not_actions                                 list(string)      (optional): A list of actions that this statement does NOT apply to. Used to apply a policy statement to all actions except those listed.
  # - principals                                  map(list(string)) (optional): The principals to which this statement applies. The keys are the principal type ("AWS", "Service", or "Federated") and the value is a list of identifiers.
  # - not_principals                              map(list(string)) (optional): The principals to which this statement does NOT apply. The keys are the principal type ("AWS", "Service", or "Federated") and the value is a list of identifiers.
  # - keys                                        list(string)      (optional): A list of keys within the bucket to which this policy applies. For example, ["", "/*"] would apply to (a) the bucket itself and (b) all keys within the bucket. The default is [""].
  # - condition                                   map(object)       (optional): A nested configuration block (described below) that defines a further, possibly-service-specific condition that constrains whether this statement applies.
  #
  # condition is a map from a unique ID for the condition to an object that can define the following properties:
  #
  # - test                                        string            (required): The name of the IAM condition operator to evaluate.
  # - variable                                    string            (required): The name of a Context Variable to apply the condition to. Context variables may either be standard AWS variables starting with aws:, or service-specific variables prefixed with the service name.
  # - values                                      list(string)      (required):  The values to evaluate the condition against. If multiple values are provided, the condition matches if at least one of them applies. (That is, the tests are combined with the "OR" boolean operation.)
  description = "The IAM policy to apply to this S3 bucket. You can use this to grant read/write access. This should be a map, where each key is a unique statement ID (SID), and each value is an object that contains the parameters defined in the comment above."

  # Ideally, this would be a map(object({...})), but the Terraform object type constraint doesn't support optional
  # parameters, whereas IAM policy statements have many optional params. And we can't even use map(any), as the
  # Terraform map type constraint requires all values to have the same type ("shape"), but as each object in the map
  # may specify different optional params, this won't work either. So, sadly, we are forced to fall back to "any."
  type = any

  # Example:
  #
  # {
  #    AllIamUsersReadAccess = {
  #      effect     = "Allow"
  #      actions    = ["s3:GetObject"]
  #      principals = {
  #        AWS = ["arn:aws:iam::111111111111:user/ann", "arn:aws:iam::111111111111:user/bob"]
  #      }
  #      condition = {
  #        SourceVPCCheck = {
  #          test = "StringEquals"
  #          variable = "aws:SourceVpc"
  #          values = ["vpc-abcd123"]
  #        }
  #      }
  #    }
  # }
  default = {}
}

variable "tags" {
  description = "A map of tags to apply to the S3 Bucket. The key is the tag name and the value is the tag value."
  type        = map(string)
  default     = {}
}

variable "kms_key_arn" {
  description = "Optional KMS key to use for encrypting data in the S3 bucket. If null, data in S3 will be encrypted using the default aws/s3 key. If provided, the key policy of the provided key must allow whoever is writing to this bucket to use that key."
  type        = string
  default     = null
}

variable "bucket_key_enabled" {
  # See https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-key.html
  description = "Optional whether or not to use Amazon S3 Bucket Keys for SSE-KMS."
  type        = bool
  default     = false
}

variable "enable_sse" {
  description = "Set to true to enable server-side encryption for this bucket. You can control the algorithm using var.sse_algorithm."
  type        = bool
  default     = true
}

variable "sse_algorithm" {
  description = "The server-side encryption algorithm to use. Valid values are AES256 and aws:kms. To disable server-side encryption, set var.enable_sse to false."
  type        = string
  default     = "aws:kms"
}

variable "enable_versioning" {
  description = "Set to true to enable versioning for this bucket. If enabled, instead of overriding objects, the S3 bucket will always create a new version of each object, so all the old values are retained."
  type        = bool
  default     = false
}

variable "mfa_delete" {
  description = "Enable MFA delete for either 'Change the versioning state of your bucket' or 'Permanently delete an object version'. This cannot be used to toggle this setting but is available to allow managed buckets to reflect the state in AWS. Only used if enable_versioning is true. CIS v1.4 requires this variable to be true. If you do not wish to be CIS-compliant, you can set it to false."
  type        = bool
  default     = false
}

variable "access_logging_enabled" {
  description = "Set to true to enable access logging for this bucket. You can set the name of the bucket where access logs should be stored using the access_logging_bucket parameter."
  type        = bool
  default     = false
}

variable "access_logging_bucket" {
  description = "The S3 bucket where access logs for this bucket should be stored. Only used if access_logging_enabled is true."
  type        = string
  default     = null
}

variable "access_logging_prefix" {
  description = "A prefix (i.e., folder path) to use for all access logs stored in access_logging_bucket. Only used if access_logging_enabled is true."
  type        = string
  default     = null
}

variable "lifecycle_rules" {
  # The lifecycle rules for this S3 bucket. See the 'lifecycle_rule' block in the aws_s3_bucket resource for context:
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
  #
  # lifecycle_rules is a map where the keys are the IDs of the rules and the values are objects that can define the
  # following properties:
  #
  # - enabled                                     bool              (required): Specifies lifecycle rule status.
  # - prefix                                      string            (optional): Object key prefix identifying one or more objects to which the rule applies.
  # - tags                                        map(string)       (optional): Specifies object tags key and value.
  # - abort_incomplete_multipart_upload_days      number            (optional): Specifies the number of days after initiating a multipart upload when the multipart upload must be completed.
  # - noncurrent_version_expiration               number            (optional): Specifies the number of days noncurrent object versions expire.
  # - expiration                                  map(object)       (optional): Specifies a period in the object's expire (documented below).
  # - transition                                  map(object)       (optional): Specifies a period in the object's transitions (documented below).
  # - noncurrent_version_transition               map(object)       (optional): Specifies when noncurrent object versions transitions (documented below).
  #
  # expiration is a map from a unique ID for the expiration setting to an object that can define the following properties:
  #
  # - date                                        string            (optional): Specifies the date after which you want the corresponding action to take effect.
  # - days                                        number            (optional): Specifies the number of days after object creation when the specific rule action takes effect.
  # - expired_object_delete_marker                bool              (optional): On a versioned bucket (versioning-enabled or versioning-suspended bucket), you can add this element in the lifecycle configuration to direct Amazon S3 to delete expired object delete markers.
  #
  # transition is a map from a unique ID for the transition setting to an object that can define the following properties:
  #
  # - storage_class                               string            (required): Specifies the Amazon S3 storage class to which you want the object to transition. Can be ONEZONE_IA, STANDARD_IA, INTELLIGENT_TIERING, GLACIER, or DEEP_ARCHIVE.
  # - date                                        string            (optional): Specifies the date after which you want the corresponding action to take effect.
  # - days                                        number            (optional): Specifies the number of days after object creation when the specific rule action takes effect.
  #
  # noncurrent_version_transition is a map from a unique ID for the noncurrent_version_transition setting to an object that can define the following properties:
  #
  # - storage_class                               string            (required): Specifies the Amazon S3 storage class to which you want the noncurrent object versions to transition. Can be ONEZONE_IA, STANDARD_IA, INTELLIGENT_TIERING, GLACIER, or DEEP_ARCHIVE.
  # - days                                        number            (required): Specifies the number of days noncurrent object versions transition.
  description = "The lifecycle rules for this S3 bucket. These can be used to change storage types or delete objects based on customizable rules. This should be a map, where each key is a unique ID for the lifecycle rule, and each value is an object that contains the parameters defined in the comment above."

  # Ideally, this would be a map(object({...})), but the Terraform object type constraint doesn't support optional
  # parameters, whereas lifecycle rules have many optional params. And we can't even use map(any), as the Terraform
  # map type constraint requires all values to have the same type ("shape"), but as each object in the map may specify
  # different optional params, this won't work either. So, sadly, we are forced to fall back to "any."
  type = any
  # Example:
  #
  # {
  #    ExampleRule = {
  #      prefix  = "config/"
  #      enabled = true
  #
  #      noncurrent_version_transition = {
  #        ToStandardIa = {
  #          days          = 30
  #          storage_class = "STANDARD_IA"
  #        }
  #        ToGlacier = {
  #          days          = 60
  #          storage_class = "GLACIER"
  #        }
  #      }
  #
  #      noncurrent_version_expiration = 90
  #    }
  # }
  default = {}
}

variable "replication_enabled" {
  description = "Set to true to enable replication for this bucket. You can set the role to use for replication using the replication_role parameter and the rules for replication using the replication_rules parameter."
  type        = bool
  default     = false
}

variable "replication_role" {
  description = "The ARN of the IAM role for Amazon S3 to assume when replicating objects. Only used if replication_enabled is set to true."
  type        = string
  default     = null
}

variable "replication_rules" {
  # The replication rules for this S3 bucket. See the 'replication_configuration' block in the aws_s3_bucket resource
  # for context: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
  #
  # replication_rules is a map where the keys are the IDs of the rules and the values are objects that can define the
  # following properties:
  #
  # - status                                      string            (required): The status of the rule. Either Enabled or Disabled. The rule is ignored if status is not Enabled.
  # - priority                                    number            (optional): The priority associated with the rule.
  # - prefix                                      string            (optional): Object keyname prefix identifying one or more objects to which the rule applies.
  # - destination_bucket                          string            (required): The ARN of the S3 bucket where you want Amazon S3 to store replicas of the object identified by the rule.
  # - destination_storage_class                   string            (optional): The class of storage used to store the object. Can be STANDARD, REDUCED_REDUNDANCY, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, GLACIER, or DEEP_ARCHIVE.
  # - destination_replica_kms_key_id              string            (optional): Destination KMS encryption key ARN for SSE-KMS replication. When set, automatically configure replication of encrypted objects.
  # - destination_access_control_translation      bool              (optional): If true, override the object owners on replication. Must be used in conjunction with destination_account_id owner override configuration.
  # - destination_account_id                      string            (optional): The Account ID to use for overriding the object owner on replication. Must be used in conjunction with destination_access_control_translation override configuration.
  # - existing_object_replication                 bool              (optional): Whether existing objects in the source bucket should be replicated. This feature requires activation by AWS Support!! See https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication-what-is-isnot-replicated.html#existing-object-replication
  # - delete_marker_replication                   bool              (optional): Whether delete markers in the source bucket should be replicated.
  # - filter                                      map(object)       (optional): Filter that identifies subset of objects to which the replication rule applies (documented below).
  #
  # filter is a map from a unique ID for the filter to an object that can define the following properties:
  #
  # - prefix                                      string            (optional): Object keyname prefix that identifies subset of objects to which the rule applies.
  # - tags                                        map(string)       (optional): A map of tags that identifies subset of objects to which the rule applies. The rule applies only to objects having all the tags in its tagset.
  description = "The rules for managing replication. Only used if replication_enabled is set to true. This should be a map, where the key is a unique ID for each replication rule and the value is an object of the form explained in a comment above."

  # Ideally, this would be a list(object({...})), but the Terraform object type constraint doesn't support optional
  # parameters, whereas replication rules have many optional params. And we can't even use list(any), as the Terraform
  # list type constraint requires all values to have the same type ("shape"), but as each object in the list may specify
  # different optional params, this won't work either. So, sadly, we are forced to fall back to "any."
  type = any

  # Example:
  #
  # {
  #   ExampleConfig = {
  #     prefix                    = "config/"
  #     status                    = "Enabled"
  #     destination_bucket        = "arn:aws:s3:::my-destination-bucket"
  #     destination_storage_class = "STANDARD"
  #   }
  # }
  default = {}
}

variable "object_lock_enabled" {
  description = "Set to true to enable Object Locking. This prevents objects from being deleted for a customizable period of time. Note that this MUST be configured at bucket creation time - you cannot update an existing bucket to enable object locking unless you go through AWS support. Additionally, this is not reversible - once a bucket is created with object lock enabled, you cannot disable object locking even with this setting. Note that enabling object locking will automatically enable bucket versioning."
  type        = bool
  default     = false
}

variable "object_lock_default_retention_enabled" {
  description = "Set to true to configure a default retention period for object locks when Object Locking is enabled. When disabled, objects will not be protected with locking by default unless explicitly configured at object creation time. Only used if object_lock_enabled is true."
  type        = bool
  default     = true
}

variable "object_lock_mode" {
  description = "The default Object Lock retention mode you want to apply to new objects placed in this bucket. Valid values are GOVERNANCE and COMPLIANCE. Only used if object_lock_enabled and object_lock_default_retention_enabled are true."
  type        = string
  default     = null
}

variable "object_lock_days" {
  description = "The number of days that you want to specify for the default retention period for Object Locking. Only one of object_lock_days or object_lock_years can be configured. Only used if object_lock_enabled and object_lock_default_retention_enabled are true."
  type        = number
  default     = null
}

variable "object_lock_years" {
  description = "The number of years that you want to specify for the default retention period for Object Locking. Only one of object_lock_days or object_lock_years can be configured. Only used if object_lock_enabled and object_lock_default_retention_enabled are true."
  type        = number
  default     = null
}

variable "request_payer" {
  description = "Specifies who should bear the cost of Amazon S3 data transfer. Can be either BucketOwner or Requester. By default, the owner of the S3 bucket would incur the costs of any data transfer."
  type        = string
  default     = null
}

variable "acceleration_status" {
  description = "Sets the accelerate configuration of an existing bucket. Can be Enabled or Suspended."
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "If set to true, when you run 'terraform destroy', delete all objects from the bucket so that the bucket can be destroyed without error. Warning: these objects are not recoverable so only use this if you're absolutely sure you want to permanently delete everything!"
  type        = bool
  default     = false
}

variable "create_resources" {
  description = "Set to false to have this module skip creating resources. This weird parameter exists solely because Terraform does not support conditional modules. Therefore, this is a hack to allow you to conditionally decide if the resources in this module should be created or not."
  type        = bool
  default     = true
}

variable "bucket_ownership" {
  description = "Configure who will be the default owner of objects uploaded to this S3 bucket: must be one of BucketOwnerPreferred (the bucket owner owns objects), ObjectWriter (the writer of each object owns that object), BucketOwnerEnforced [Recommended] (the bucket owner automatically owns and has full control over every object in the bucket), or null (don't configure this feature). Note that BucketOwnerEnforced disables ACLs, and ObjectWriter only takes effect if the object is uploaded with the bucket-owner-full-control canned ACL. See https://docs.aws.amazon.com/AmazonS3/latest/dev/about-object-ownership.html for more info."
  type        = string
  default     = "BucketOwnerEnforced"
}

variable "cors_rules" {
  # cors_rules is a list(object({...})) for setting CORS rules on this S3 bucket
  # See https://docs.aws.amazon.com/AmazonS3/latest/dev/cors.html for more details

  # The objects that can define the following properties:
  #
  # - allowed_origins list(string)      (required): The origins that you want to allow cross-domain requests from.
  # - allowed_methods list(string)      (required): From the set of GET, PUT, POST, DELETE, HEAD
  # - allowed_headers list(string)      (optional): The AllowedHeader element specifies which headers are allowed in a preflight request through the Access-Control-Request-Headers header.
  # - expose_headers  list(string)      (optional): Each ExposeHeader element identifies a header in the response that you want customers to be able to access from their applications.
  # - max_age_seconds number            (optional): The MaxAgeSeconds element specifies the time in seconds that your browser can cache the response for a preflight request as identified by the resource, the HTTP method, and the origin.
  description = "CORS rules to set on this S3 bucket"

  # Ideally, this would be a list(object({...})), but the Terraform object type constraint doesn't support optional
  # parameters, whereas replication rules have many optional params. And we can't even use list(any), as the Terraform
  # list type constraint requires all values to have the same type ("shape"), but as each object in the list may specify
  # different optional params, this won't work either. So, sadly, we are forced to fall back to "any."
  type = any

  # Example:
  #
  # [
  #   {
  #     allowed_origins = ["*"]
  #     allowed_methods = ["GET", "HEAD"]
  #     allowed_headers = ["x-amz-*"]
  #     expose_headers  = ["Etag"]
  #     max_age_seconds = 3000
  #   }
  # ]
  default = []
}

variable "create_replication_iam_role_to_bucket" {
  description = "When true, provision an IAM role that allows various source buckets to replicate to this bucket. Note that this setting should be used if you intend to use this bucket as a replication destination, NOT replication source. For configuring replication from the bucket, refer to the var.replication_enabled input variable."
  type        = bool
  default     = false
}

variable "custom_iam_role_name_for_replication_role" {
  description = "The name to use for the IAM role for replication access to this bucket. When null, a generic name using the bucket name will be used. Only used if var.create_replication_iam_role_to_bucket is true."
  type        = string
  default     = null
}

variable "replication_source_buckets" {
  description = "List of buckets that should be allowed to replicate to this bucket. Only used if var.create_replication_iam_role_to_bucket is true."
  type        = list(string)
  default     = []
}

variable "iam_role_permissions_boundary" {
  description = "The ARN of the policy that is used to set the permissions boundary for the IAM role"
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------------------------------------------------
# BACKWARD COMPATIBILITY FEATURE FLAGS
# The following variables are feature flags to enable and disable certain features in the module. These are primarily
# introduced to maintain backward compatibility by avoiding unnecessary resource creation.
# ---------------------------------------------------------------------------------------------------------------------

variable "use_managed_iam_policies" {
  description = "When true, all IAM policies will be managed as dedicated policies rather than inline policies attached to the IAM roles. Dedicated managed policies are friendlier to automated policy checkers, which may scan a single resource for findings. As such, it is important to avoid inline policies when targeting compliance with various security standards."
  type        = bool
  default     = true
}

locals {
  use_inline_policies = var.use_managed_iam_policies == false
  create_acl          = var.create_resources == true && var.acl != null
}
