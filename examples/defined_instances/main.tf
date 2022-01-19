provider "aws" {
  region  = "us-east-1"
  profile = "2w"
}

terraform {
  backend "s3" {
    bucket  = "ps-ncentola-2w-tf-state-us-east-1"
    key     = "tf-aws-dms-module-example.tfstate"
    region  = "us-east-1"
    profile = "2w"
  }
}

module "dms" {
  source = "../../"

  endpoints     = {
    application-db-a = {
      endpoint_type                 = "source"
      engine_name                   = "postgres"
      server_name                   = "app_db.internal.something.com"
      port                          = 5432
      database_name                 = "app"
      username                      = "dms"
      password                      = "supersecret"
      extra_connection_attributes   = null
      tags                          = { cooler = "stuffer"}
    }
    dms-s3-bucket-a = {
      endpoint_type                 = "target"
      engine_name                   = "s3"
      extra_connection_attributes   = null
      tags                          = { cool = "stuff"}
      s3_settings = {
        bucket_name             = aws_s3_bucket.dms.bucket
        bucket_folder           = "prefix_a/"
        data_format             = "parquet"
        date_partition_enabled  = true
        service_access_role_arn = aws_iam_role.dms_s3_role.arn
      }
    }
    dms-s3-bucket-b = {
      endpoint_type                 = "target"
      engine_name                   = "s3"
      extra_connection_attributes   = null
      tags                          = { cool = "stuff"}
      s3_settings = {
        bucket_name             = aws_s3_bucket.dms.bucket
        bucket_folder           = "prefix_b/"
        data_format             = "parquet"
        date_partition_enabled  = true
        service_access_role_arn = aws_iam_role.dms_s3_role.arn
      }
    }
    dms-s3-bucket-c = {
      endpoint_type                 = "target"
      engine_name                   = "s3"
      extra_connection_attributes   = null
      tags                          = { cool = "stuff"}
      s3_settings = {
        bucket_name             = aws_s3_bucket.dms.bucket
        bucket_folder           = "prefix_c/"
        data_format             = "parquet"
        date_partition_enabled  = true
        service_access_role_arn = aws_iam_role.dms_s3_role.arn
      }
    }
  }
  replications  = var.replications
}
