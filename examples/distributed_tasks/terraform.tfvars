tasks = {
  schema-a = {
    source          = "application-db-a"
    target          = "dms-s3-bucket-a"
    migration_type  = "full-load-and-cdc"
    source_schema   = "schema_a"
    include_tables  = [
      "good_table"
    ]
    exclude_tables  = [
      "bad_table"
    ]
  }
  schema-b = {
    source          = "application-db-a"
    target          = "dms-s3-bucket-b"
    migration_type  = "full-load-and-cdc"
    source_schema   = "schema_b"
    include_tables  = [
      "good_table"
    ]
    exclude_tables  = [
      "bad_table"
    ]
  }
  schema-c = {
    source          = "application-db-a"
    target          = "dms-s3-bucket-c"
    migration_type  = "full-load-and-cdc"
    source_schema   = "schema_c"
    include_tables  = [
      "good_table"
    ]
    exclude_tables  = [
      "bad_table"
    ]
  }
  # schema-d = {
  #   source          = "application-db-a"
  #   target          = "dms-s3-bucket-c"
  #   migration_type  = "full-load-and-cdc"
  #   source_schema   = "schema_c"
  #   include_tables  = [
  #     "good_table"
  #   ]
  #   exclude_tables  = [
  #     "bad_table"
  #   ]
  # }
}

instances = {
  tasks_per_instance          = 1
  replication_instance_class  = "dms.t2.micro"
  allocated_storage           = 20
  multi_az                    = false
  replication_subnet_group_id = "asdf"
  vpc_security_group_ids      = ["sg-0e016fadd3cf9b139"]
}
