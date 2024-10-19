# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED MODULE PARAMETERS
# These variables must be passed in by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "required_executables" {
  description = "A list of named executables that should exist on the OS PATH."
  type        = list(string)
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# These variables have a sane default that can be used, and thus are not necessary to be set to run the module.
# ---------------------------------------------------------------------------------------------------------------------

variable "error_message" {
  description = "Error message to show if the required executable is not found. This is printed for each executable that was not found. The module will make the following substitutions in the string: `__EXECUTABLE_NAME__` will become the name of the executable that was not found."
  type        = string
  default     = "Not found: __EXECUTABLE_NAME__"
}
