provider aws {
  region  = var.region
  profile = var.profile
}

provider aws {
  region  = "us-east-1"
  profile = var.profile
  alias   = "us_east_1"
}

terraform {
  # 'backend-config' options must be passed like :
  # terraform init -input=false -backend=true \
  #   [with] -backend-config="backend.json"
  #     [or] -backend-config="backend.tfvars"
  #     [or] -backend-config="<key>=<value>"
  backend "s3" {}
}