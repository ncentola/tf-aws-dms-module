resource "aws_s3_bucket" "dms" {
  bucket  = "example-dms-bucket"
  acl     = "private"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = [
        "dms.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "s3_access" {
  statement {

    actions = [
      "s3:*"
    ]

    resources = [
      aws_s3_bucket.dms.arn,
    ]
  }

}

resource "aws_iam_role" "dms_s3_role" {
  name                = "DMSS3AccessRole"
  assume_role_policy  = data.aws_iam_policy_document.assume_role_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
  ]

  inline_policy {
    name = "S3Access"
    policy = data.aws_iam_policy_document.s3_access.json
  }
}

# # -- Boilerplate DMS resources --
# resource "aws_dms_replication_subnet_group" "replication_subnet_group" {
#   replication_subnet_group_description = "Replication subnet group for DMS test"
#   replication_subnet_group_id          = "nbly-${var.environment}-dms-subnet-group"
#
#   subnet_ids = var.dms_subnets
# }
#
# data "aws_iam_policy_document" "dms_assume_role" {
#   statement {
#     actions = ["sts:AssumeRole"]
#
#     principals {
#       identifiers = ["dms.amazonaws.com"]
#       type        = "Service"
#     }
#   }
# }
#
# resource "aws_iam_role" "dms-access-for-endpoint" {
#   assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
#   name               = "dms-access-for-endpoint"
# }
#
# resource "aws_iam_role_policy_attachment" "dms-access-for-endpoint-AmazonDMSRedshiftS3Role" {
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSRedshiftS3Role"
#   role       = aws_iam_role.dms-access-for-endpoint.name
# }
#
# resource "aws_iam_role" "dms-cloudwatch-logs-role" {
#   assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
#   name               = "dms-cloudwatch-logs-role"
# }
#
# resource "aws_iam_role_policy_attachment" "dms-cloudwatch-logs-role-AmazonDMSCloudWatchLogsRole" {
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
#   role       = aws_iam_role.dms-cloudwatch-logs-role.name
# }
#
# resource "aws_iam_role" "dms-vpc-role" {
#   assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
#   name               = "dms-vpc-role"
# }
#
# resource "aws_iam_role_policy_attachment" "dms-vpc-role-AmazonDMSVPCManagementRole" {
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
#   role       = aws_iam_role.dms-vpc-role.name
# }
#
# data "aws_secretsmanager_secret" "creds" {
#   for_each = var.glue_connections_config
#   name = each.value.secret_name
# }
#
# data "aws_secretsmanager_secret_version" "latests" {
#   for_each  = data.aws_secretsmanager_secret.creds
#   secret_id = each.value.id
# }
#
