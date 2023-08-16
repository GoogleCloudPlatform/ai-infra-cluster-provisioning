project_id      = "my-project-id"
resource_prefix = "my-cluster-name"
instance_groups = [
  {
    target_size = 4
    zone        = "us-east4-a"
  },
  {
    target_size = 4
    zone        = "us-east4-a"
  },
]
