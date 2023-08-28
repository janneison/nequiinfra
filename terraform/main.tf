#*****************************************************************************************
#Variables
variable "access_information_region" {}
variable "access_information_access_key" {}
variable "access_information_secret_key" {}
variable "environment_var" {}

#*****************************************************************************************
#Definicion de provider
provider "aws" {
  region     = var.access_information_region
  access_key = var.access_information_access_key
  secret_key = var.access_information_secret_key
}

#*****************************************************************************************
#Informacion para almacenar el estado de Terraform en S3 modificar bucket
/*terraform{
  backend "s3" {
    bucket     = "nequi-platform-dev-terraformstate"
    key        = "terraform.tfstate"
    encrypt    = "true"
    region     = "us-east-1"
    access_key = "" se colocan manual
    secret_key = "" se colocan manual
  }
}*/

#*****************************************************************************************
#Informacion de NetWorking
module "aws_network_vpc"{
  prefix_environment = var.environment_var
  region = var.access_information_region
  source = "./modules/network/vpc"
}

#*****************************************************************************************
#Informacion de EKS
module "eks"{
  prefix_environment = var.environment_var
  vpc_id = module.aws_network_vpc.vpc_id
  public_subnet_01_id = module.aws_network_vpc.public_subnet_01_id
  public_subnet_02_id = module.aws_network_vpc.public_subnet_02_id
  private_subnet_01_id = module.aws_network_vpc.private_subnet_01_id
  private_subnet_02_id = module.aws_network_vpc.private_subnet_02_id
  source = "./modules/eks"
}

#*****************************************************************************************
#Informacion de ECR esta a modo de prueba
module "ecr"{
  prefix_environment = var.environment_var
  source = "./modules/ecr"
}


#*****************************************************************************************
#Informacion de EKS
module "rds"{
  region = var.access_information_region
  prefix_environment = var.environment_var
  vpc_id = module.aws_network_vpc.vpc_id
  public_subnet_01_id = module.aws_network_vpc.public_subnet_01_id
  public_subnet_02_id = module.aws_network_vpc.public_subnet_02_id
  platform_sk_db_password = "pass"
  platform_sk_db_username = "user"
  source = "./modules/rds"
}