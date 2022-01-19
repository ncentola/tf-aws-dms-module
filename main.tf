locals {

  # this jsonencode/decode rigmarole is because terraform wants conditionals to have the EXACT same type (including map keys)
  # this converts to string and back so terraform will stop complaining for no reason
  tasks               = jsondecode(var.tasks != null ? jsonencode(var.tasks) : jsonencode({}))
  task_count          = length(keys(local.tasks))
  tasks_per_instance  = try(var.instances.tasks_per_instance, 999)

  # create indeces list to distribute tasks over
  instance_indeces    = slice(flatten([
    for i in range(local.task_count): [
      for j in range(local.tasks_per_instance):
        "replication-instance-${i}"
      ]
  ]), 0, local.task_count)

  # create distributed replication map
  replications_dist   = {
    for k, v in {
      for i, task in [for task in local.tasks: task]:
        local.instance_indeces[i] => {
          keys(local.tasks)[i] = task
        }...
    }: k => merge(var.instances, { tasks = merge(v...) })
  }

  # use the replications var if it was passed in, else use the distributed replications
  replications        = jsondecode(var.replications != null ? jsonencode(var.replications) : jsonencode(local.replications_dist))

  task_config         = flatten([
    for instance_name, instance in local.replications : [
      for task_name, task in instance.tasks : {
        unique_name               = join("-", [instance_name, task_name])
        instance_name             = instance_name
        task_name                 = task_name
        source_schema             = task.source_schema
        source_endpoint           = task.source
        target_endpoint           = task.target
        migration_type            = task.migration_type
        replication_task_settings = lookup(task, "replication_task_settings", null)
        include_tables            = [
          for i, table in task.include_tables : {
            rule-type = "selection",
            rule-id = "${i}",
            rule-name = "${i}",
            object-locator: {
                schema-name = "${task.source_schema}",
                table-name = "${table}"
            },
            rule-action = "include"
          }
        ]
        exclude_tables          =  [
          for i, table in task.exclude_tables : {
            rule-type = "selection",
            rule-id = "${i}",
            rule-name = "${i}",
            object-locator: {
                schema-name = "${task.source_schema}",
                table-name = "${table}"
            },
            rule-action = "exclude"
          }
        ]
      }
    ]
  ])
}

resource "aws_dms_endpoint" "this" {
  for_each = var.endpoints

  endpoint_id     = each.key
  endpoint_type   = each.value.endpoint_type
  engine_name     = each.value.engine_name

  server_name                 = lookup(each.value, "server_name", null)
  database_name               = lookup(each.value, "database_name", null)
  port                        = lookup(each.value, "port", null)
  ssl_mode                    = lookup(each.value, "ssl_mode", null)
  username                    = lookup(each.value, "username", null)
  password                    = lookup(each.value, "password", null)
  kms_key_arn                 = lookup(each.value, "kms_key_arn", null)
  extra_connection_attributes = lookup(each.value, "extra_connection_attributes", null)

  s3_settings {
    bucket_name                       = try(lookup(each.value.s3_settings, "bucket_name",                       null), null)
    bucket_folder                     = try(lookup(each.value.s3_settings, "bucket_folder",                     null), null)
    compression_type                  = try(lookup(each.value.s3_settings, "compression_type",                  null), null)
    csv_delimiter                     = try(lookup(each.value.s3_settings, "csv_delimiter",                     null), null)
    csv_row_delimiter                 = try(lookup(each.value.s3_settings, "csv_row_delimiter",                 null), null)
    data_format                       = try(lookup(each.value.s3_settings, "data_format",                       null), null)
    date_partition_enabled            = try(lookup(each.value.s3_settings, "date_partition_enabled",            null), null)
    encryption_mode                   = try(lookup(each.value.s3_settings, "encryption_mode",                   null), null)
    parquet_timestamp_in_millisecond  = try(lookup(each.value.s3_settings, "parquet_timestamp_in_millisecond",  null), null)
    parquet_version                   = try(lookup(each.value.s3_settings, "parquet_version",                   null), null)
    server_side_encryption_kms_key_id = try(lookup(each.value.s3_settings, "server_side_encryption_kms_key_id", null), null)
    service_access_role_arn           = try(lookup(each.value.s3_settings, "service_access_role_arn",           null), null)
  }

  tags = lookup(each.value, "tags", null)
}

resource "aws_dms_replication_instance" "this" {
  for_each = local.replications

  replication_instance_id       = each.key
  replication_instance_class    = lookup(each.value, "replication_instance_class",    null)
  replication_subnet_group_id   = lookup(each.value, "replication_subnet_group_id",   null)
  allocated_storage             = lookup(each.value, "allocated_storage",             null)
  vpc_security_group_ids        = lookup(each.value, "vpc_security_group_ids",        null)
  multi_az                      = lookup(each.value, "multi_az",                      null)
  engine_version                = lookup(each.value, "engine_version",                null)
  kms_key_arn                   = lookup(each.value, "kms_key_arn",                   null)
  preferred_maintenance_window  = lookup(each.value, "preferred_maintenance_window",  null)
  publicly_accessible           = lookup(each.value, "publicly_accessible",           null)
  apply_immediately             = lookup(each.value, "apply_immediately",             null)
  auto_minor_version_upgrade    = lookup(each.value, "auto_minor_version_upgrade",    null)

  tags = lookup(each.value, "tags", null)
}

resource "aws_dms_replication_task" "this" {
  for_each = { for config in local.task_config : config.unique_name => config }

  replication_task_id       = each.value.task_name
  migration_type            = each.value.migration_type
  replication_instance_arn  = aws_dms_replication_instance.this[each.value.instance_name].replication_instance_arn

  source_endpoint_arn       = aws_dms_endpoint.this[each.value.source_endpoint].endpoint_arn
  target_endpoint_arn       = aws_dms_endpoint.this[each.value.target_endpoint].endpoint_arn

  replication_task_settings = each.value.replication_task_settings

  table_mappings = jsonencode({
    rules = concat(
      each.value.include_tables,
      each.value.exclude_tables
    )
  })

  tags = lookup(each.value, "tags", null)
}
