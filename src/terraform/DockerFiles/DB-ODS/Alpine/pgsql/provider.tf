# terraform {
#   required_providers {
#     aws = {
#       source = "hashicorp/aws"
#       version = "5.8.0"
#     }
#   }
#    required_version = ">= 1.5.0"
# }

# provider "aws" {
#   # Configuration options
#    region = "us-west-1"
# }

// Used by get the current aws number account.
data "aws_caller_identity" "current" {
}