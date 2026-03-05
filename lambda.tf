resource "aws_lambda_function" "save_session" {
  function_name = "FSE100_SaveSession"   

  runtime = "nodejs22.x"
  handler = "index.handler"

  filename         = "${path.module}/lambda/save_session.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/save_session.zip")

  role = aws_iam_role.lambda_exec_role.arn

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.student_sessions.name
      STAGE      = "dev"
    }
  }
}

resource "aws_lambda_function" "login" {
  function_name = "FSE100_Login"

  runtime = "nodejs22.x"
  handler = "index.handler"

  filename         = "${path.module}/lambda/login.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/login.zip")

  role = aws_iam_role.lambda_exec_role.arn

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.student_sessions.name
      STAGE      = "dev"
    }
  }
}
