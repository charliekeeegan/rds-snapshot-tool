resource "aws_iam_role" "snapshots_rds" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  force_detach_policies = true
}

data "aws_iam_policy_document" "snapshot_rds" {

  statement {
    sid    = "AllowUseOfTheKey"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid    = "AllowAttachmentOfPersistentResources"
    effect = "Allow"
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    resources = [
      "*"
    ]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["True"]
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "rds:CreateDBSnapshot",
      "rds:DeleteDBSnapshot",
      "rds:DescribeDBInstances",
      "rds:DescribeDBSnapshots",
      "rds:ModifyDBSnapshotAttribute",
      "rds:DescribeDBSnapshotAttributes",
      "rds:CopyDBSnapshot",
      "rds:ListTagsForResource",
      "rds:AddTagsToResource"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "snapshot_rds" {
  name   = "snapshot_rds"
  policy = data.aws_iam_policy_document.snapshot_rds.json
}
resource "aws_iam_role_policy_attachment" "attachment" {
  role       = aws_iam_role.snapshots_rds.name
  policy_arn = aws_iam_policy.snapshot_rds.arn
}



resource "aws_iam_role" "iamrole_state_execution" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = join("", ["states.", data.aws_region.current.name, ".amazonaws.com"])
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  force_detach_policies = true
  inline_policy {
    name = "inline_policy_rds_snapshot"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "lambda:InvokeFunction"
          ]
          Resource = "*"
        }
      ]
    })
  }
}


resource "aws_iam_role" "iamrole_step_invocation" {
  name = "invoke-state-machines"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  force_detach_policies = true
  inline_policy {
    name = "inline_policy_state_invocation"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "states:StartExecution"
          ]
          Resource = "*"
        }
      ]
    })
  }
}
