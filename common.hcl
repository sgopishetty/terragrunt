locals {
  # The default tags to apply in all environments.
  team_name = "terraf"
  tags = {
    #"epi:product-stream" = "product-engineering",
    "epi:team"           = "quality-engineering",
    #"epi:supported-by"   = "quality-engineering",
    #"epi:environment"    = "production",
    #"epi:owner"          = "quality-engineering",

  }

  remote_state_prefix = "epi-stg-${local.team_name}"
}