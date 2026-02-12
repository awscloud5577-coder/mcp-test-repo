project     = "mobilesentrix-platform"
environment = "dev"
region      = "us-east-1"
vpc_cidr    = "10.50.0.0/16"

node_instance_types = ["m6i.large", "m6a.large"]
node_desired_size   = 2
node_min_size       = 2
node_max_size       = 5

tags = {
  Owner      = "platform-team"
  CostCenter = "engineering"
}
