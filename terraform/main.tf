module "test_dbs" {
  source = "./modules/test_dbs"
}

module "snapshots_tool_rds_dest" {
  source = "./modules/snapshots_tool_rds_dest"
}


# module "snapshots_tool_rds_source" {
#   source = "./modules/snapshots_tool_rds_source"
# }
