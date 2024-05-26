variable "function_name" {
    description = "The name of the Lambda function"
    type        = string
}

variable "handler" {
    description = "The entry point of the Lambda function"
    type        = string
}

variable "runtime" {
    description = "The runtime of the Lambda function"
    type        = string
}