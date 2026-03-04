variable "region" {
  type    = string
  default = "us-east-1"
}

# NEW stack name so you can run Terraform alongside your manual env
variable "name" {
  type    = string
  default = "tf-tasky"
}

variable "vpc_cidr" {
  type    = string
  default = "10.60.0.0/16"
}

variable "ssh_cidr" {
  type    = string
  default = "0.0.0.0/0"
}

variable "mongo_username" {
  type    = string
  default = "jaimekate"
}

variable "mongo_password" {
  type      = string
  sensitive = true
}

variable "mongo_auth_db" {
  type    = string
  default = "admin"
}

variable "jwt_secret_key" {
  type      = string
  sensitive = true
}

# Pass this in from CI after pushing to ECR
# e.g. 565393060528.dkr.ecr.us-east-1.amazonaws.com/tasky-app:SHA
variable "app_image" {
  type = string
}

# Intentionally over-permissive for the exercise
variable "mongo_instance_policy_arn" {
  type    = string
  default = "arn:aws:iam::aws:policy/AdministratorAccess"
}
