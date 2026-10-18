variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "name" {
  type    = string
  default = "portfolio"
}

variable "github_repo" {
  description = "Only pushes to this repository's main branch may deploy."
  type        = string
  default     = "tapiwa-magumise/portfolio"
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
