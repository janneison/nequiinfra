variable "prefix_environment" {
}

variable "platform_sk_db_username" {
}

variable "platform_sk_db_password" {
}

variable "vpc_id" {
}

variable "public_subnet_01_id" {
}

variable "public_subnet_02_id" {
}

variable "region" {
}


#*****************************************************************************************
#INFORMACION DE BASE DE DATOS - AURORA POSTGRES SERVERLESS

resource "aws_rds_cluster" "tf-nequi-platform-aurora-postgresql" {
  cluster_identifier = "tf-nequi-platform-aurora-postgresql-${var.prefix_environment}"
  engine             = "aurora-postgresql"
  engine_mode        = "provisioned"
  engine_version     = "13.8"
  database_name      = "tf_nequi_platform_database_instance_${var.prefix_environment}"
  master_username    = var.platform_sk_db_username
  master_password    = var.platform_sk_db_password
  
  serverlessv2_scaling_configuration {
    max_capacity = 1.0
    min_capacity = 0.5
  }
  
  tags = {
    Name        = "tf-nequi-platform-aurora-postgresql-${var.prefix_environment}"
    ProjectName = "PLATFORM-NEQUI"
  }
}

resource "aws_rds_cluster_instance" "tf-nequi-platform-aurora-postgresql-instance" {
  cluster_identifier = aws_rds_cluster.tf-nequi-platform-aurora-postgresql.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.tf-nequi-platform-aurora-postgresql.engine
  engine_version     = aws_rds_cluster.tf-nequi-platform-aurora-postgresql.engine_version
  publicly_accessible                   = true
  tags = {
    Name        = "tf-nequi-platform-aurora-postgresql-instance-${var.prefix_environment}"
    ProjectName = "PLATFORM-NEQUI"
  }
}
