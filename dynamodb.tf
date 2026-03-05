resource "aws_dynamodb_table" "student_sessions" {
  name         = "StudentSessions"
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "StudentID"
  range_key = "SessionID"

  attribute {
    name = "StudentID"
    type = "N"
  }

  attribute {
    name = "SessionID"
    type = "S"
  }

  # Future: local or global secondary indexes can be added here.
}
