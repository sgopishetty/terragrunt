#!/usr/bin/env bash
# Enable MFA Delete to all S3 buckets

set -e

readonly DEFAULT_REGION="us-east-1"

function print_usage {
  echo
  echo "Usage: mfa-delete.sh [OPTIONS]"
  echo
  echo
  echo "Required arguments:"
  echo -e "  --account-id\tThe AWS account ID where the buckets are."
  echo
  echo "Optional arguments:"
  echo
  echo -e "  --region\tThe AWS region. Default: $DEFAULT_REGION"
  echo
  echo "For each bucket, you will be prompted to insert a MFA Code."
  echo
  echo
  echo "Example: mfa-delete.sh --region eu-central-1 --account-id 123456789123"
}

# Log to stderr, as we use stdout to return values from functions
function log {
  local -r level="$1"
  local -r message="$2"
  local -r timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  >&2 echo -e "${timestamp} [${level}] ${message}"
}

function log_info {
  local -r message="$1"
  log "INFO" "$message"
}

function log_error {
  local -r message="$1"
  log "ERROR" "$message"
}

function assert_not_empty {
  local -r arg_name="$1"
  local -r arg_value="$2"

  if [[ -z "$arg_value" ]]; then
    log_error "The value for '$arg_name' cannot be empty."
    print_usage
    exit 1
  fi
}

function list_buckets {
  local -r region="$1"

  log_info "Retrieving a list of S3 buckets..."
  aws s3api list-buckets --query "Buckets[].[Name]" --output text --region "$region"
}

function get_bucket_mfa_delete_status() {
  local -r bucket="$1"
  local -r region="$2"

  aws s3api get-bucket-versioning --bucket "$bucket" --query "MFADelete" --region "$region" --output text
}

function mfa_delete_is_disabled() {
  local -r bucket="$1"
  local -r region="$2"

  local status
  status=$(get_bucket_mfa_delete_status "$bucket" "$region")
  log_info "Status of bucket ($bucket) is: $status"
  if [[ "$status" == 'Disabled' ]] || [[ "$status" == 'None' ]]; then
    return 0
  fi
  return 1
}

function enable_mfa_delete {
  local -r bucket="$1"
  local -r region="$2"
  local -r mfa_arn="$3"

  log_info "Activating MFA Delete for the bucket $bucket..."
  echo -n "Enter MFA token: "
  read -r mfa_token

  aws s3api put-bucket-versioning --bucket "$bucket" \
    --versioning-configuration Status=Enabled,MFADelete=Enabled \
    --mfa "$mfa_arn $mfa_token" \
    --region "$region"

  echo
}

function run {
  local account_id
  local region="$DEFAULT_REGION"

  while [[ $# > 0 ]]; do
    local key="$1"

    case "$key" in
      --region)
        assert_not_empty "$key" "$2"
        region="$2"
        shift
        ;;
      --account-id)
        assert_not_empty "$key" "$2"
        account_id="$2"
        shift
        ;;
      *)
        log_error "Unrecognized argument: $key"
        print_usage
        exit 1
        ;;
    esac

    shift
  done

  assert_not_empty "--account-id" "$account_id"

  local -r mfa_arn="arn:aws:iam::$account_id:mfa/root-account-mfa-device"
  local -a s3_buckets
  s3_buckets=$(list_buckets "$region")

  if [[ -z "$s3_buckets" ]]; then
    log_info "There were no S3 buckets found in your account."
  else
    for bucket in $s3_buckets; do
      if mfa_delete_is_disabled "$bucket" "$region"; then
        log_info "In order to activate MFA Delete for your buckets, you need to enter a new MFA token for $mfa_arn at every request."
        enable_mfa_delete "$bucket" "$region" "$mfa_arn"
      fi
    done
    log_info "Done."
  fi
}

run "$@"
