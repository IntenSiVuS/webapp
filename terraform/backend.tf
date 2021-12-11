terraform {
  # i am using the same credentials to store the state as the actual terraform plan/apply (to deploy the infrastructure)
  # It's best to split this with different roles and ideally different accounts 
  backend "s3" {}
}
