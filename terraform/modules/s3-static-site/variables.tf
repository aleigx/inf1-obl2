variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "variables_file" {
  description = "Path to the JSON file containing variables"
  type        = string
  default     = ""
}