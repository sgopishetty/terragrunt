terraform {
  source = "../../../../modules/s3-bucket"
}

include "root" {
  path   = find_in_parent_folders()
  expose = true
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/s3/s3.hcl"
  expose = true
}

inputs = {
  bucket_policy_statements = {
    AlbLogs = {
        effect = "Allow"
        actions = ["s3:PutObject","s3:ListBucket", "s3:GetBucketLocation", "s3:GetObject", "s3:DeleteObject"]
        principals = {
            AWS = ["arn:aws:iam::127311923021:root"]
        }
        keys = ["","/*"]
    }
  }
}
