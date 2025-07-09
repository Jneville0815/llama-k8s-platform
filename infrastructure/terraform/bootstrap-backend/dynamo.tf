resource "aws_dynamodb_table" "remote_state" {
  name           = "tfstate-lock-${var.repository_name}"
  hash_key       = "LockID"
  read_capacity  = 10
  write_capacity = 10
  attribute {
    name = "LockID"
    type = "S"
  }
}