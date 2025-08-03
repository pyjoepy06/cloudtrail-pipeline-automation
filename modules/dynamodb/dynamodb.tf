resource "aws_dynamodb_table" "events_monitor" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "eventID"
  range_key    = "eventTime"

  attribute {
    name = "eventID"
    type = "S"
  }

  attribute {
    name = "eventTime"
    type = "S"
  }

  tags = {
    Name = format("%s-dynambodb", var.table_name)
  }
}
