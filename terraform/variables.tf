variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "name" {
  type    = string
  default = "portfolio"
}

# GitHub's OIDC subject for this repo includes immutable owner and repo IDs.
# Find it with: gh api repos/<owner>/<repo>/actions/oidc/customization/sub
variable "github_subject_prefix" {
  description = "Only pushes to this repository's main branch may deploy."
  type        = string
  default     = "repo:tapiwa-magumise@266259364/portfolio@1424381430"
}

variable "price_class" {
  description = "CloudFront price class. PriceClass_All includes edge locations in Africa."
  type        = string
  default     = "PriceClass_All"
  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "Must be PriceClass_100, PriceClass_200 or PriceClass_All."
  }
}
