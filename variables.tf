variable "region" {
  description = "The AWS region to modify infrastructure"
  type        = string

  validation {
    condition = ( length(split("-", var.region)) == 3 )
    error_message = "ERROR: Supplied region was in the wrong format (must take the form **-*****-*, e.g. eu-west-1)."
  }
}



