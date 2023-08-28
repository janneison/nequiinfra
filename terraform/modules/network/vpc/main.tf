variable "prefix_environment" {
}

variable "region" {
}

resource "aws_vpc" "nequi-platform-vpc" {
  cidr_block       = "10.4.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  tags = {
    Name = "nequi-platform-vpc-${var.prefix_environment}"
    ProjectName = "PLATFORM-NEQUI"
  }
}


#Informacion del Internet Gateway
resource "aws_internet_gateway" "nequi-platform-internet-gateway" {
  vpc_id = aws_vpc.nequi-platform-vpc.id
  tags = {
    Name = "nequi-platform-internet-gateway_${var.prefix_environment}"
    ProjectName = "PLATFORM-NEQUI"
    Environment = "QA"
  }
}

#Informacion de las Subredes privadas
resource "aws_subnet" "nequi-platform-private-subnet-01" {
  vpc_id     = aws_vpc.nequi-platform-vpc.id
  cidr_block = "10.4.0.0/24"
  availability_zone = "${var.region}a"
  map_public_ip_on_launch = true
  depends_on = [aws_internet_gateway.nequi-platform-internet-gateway]
  tags = {
    Name = "nequi-platform-private-subnet-01-${var.prefix_environment}"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/nequi-platform-ekscluster-${var.prefix_environment}" = "shared"
    ProjectName = "PLATFORM-NEQUI"
  }
}

resource "aws_subnet" "nequi-platform-private-subnet-02" {
  vpc_id     = aws_vpc.nequi-platform-vpc.id
  cidr_block = "10.4.2.0/24"
  availability_zone = "${var.region}b"
  map_public_ip_on_launch = true
  depends_on = [aws_internet_gateway.nequi-platform-internet-gateway]
  tags = {
    Name = "nequi-platform-private-subnet-02-${var.prefix_environment}"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/nequi-platform-ekscluster-${var.prefix_environment}" = "shared"
    ProjectName = "PLATFORM-NEQUI"
  }
}

#Informacion de las Subredes publicas
resource "aws_subnet" "nequi-platform-public-subnet-01" {
  vpc_id     = aws_vpc.nequi-platform-vpc.id
  cidr_block = "10.4.1.0/24"
  availability_zone = "${var.region}a"
  map_public_ip_on_launch = true
  depends_on = [aws_internet_gateway.nequi-platform-internet-gateway]
  tags = {
    Name = "nequi-platform-public-subnet-01-${var.prefix_environment}"
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/nequi-platform-ekscluster-${var.prefix_environment}" = "shared"
    ProjectName = "PLATFORM-NEQUI"
  }
}

resource "aws_subnet" "nequi-platform-public-subnet-02" {
  vpc_id     = aws_vpc.nequi-platform-vpc.id
  cidr_block = "10.4.3.0/24"
  availability_zone = "${var.region}b"
  map_public_ip_on_launch = true
  depends_on = [aws_internet_gateway.nequi-platform-internet-gateway]
  tags = {
    Name = "nequi-platform-public-subnet-02-${var.prefix_environment}"
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/nequi-platform-ekscluster-${var.prefix_environment}" = "shared"
    ProjectName = "PLATFORM-NEQUI"
  }
}

#Informacion de elastic ips
resource "aws_eip" "nequi-platform-eip-01" {
  vpc = true
  tags = {
    Name = "nequi-platform_eip-01-${var.prefix_environment}"
    ProjectName = "PLATFORM-NEQUI"
  }
}

resource "aws_eip" "nequi-platform-eip-02" {
  vpc = true
  tags = {
    Name = "nequi-platform-eip-02-${var.prefix_environment}"
    ProjectName = "PLATFORM-NEQUI"
  }
}

#Informacion de los NAT Gateway
resource "aws_nat_gateway" "nequi-platform-nat-gateway-01" {
  allocation_id = aws_eip.nequi-platform-eip-01.id
  subnet_id     = aws_subnet.nequi-platform-public-subnet-01.id
  tags = {
    Name = "nequi-platform-nat-gateway-01-${var.prefix_environment}"
    ProjectName = "PLATFORM-NEQUI"
  }
}

resource "aws_nat_gateway" "nequi-platform-nat-gateway-02" {
  allocation_id = aws_eip.nequi-platform-eip-02.id
  subnet_id     = aws_subnet.nequi-platform-public-subnet-02.id
  tags = {
    Name = "nequi-platform-nat-gateway-02-${var.prefix_environment}"
    ProjectName = "PLATFORM-NEQUI"
  }
}

#Informacion de la tabla de ruteo asociada al Internet Gateway
resource "aws_route_table" "nequi-platform-route-table-igw" {
  vpc_id = aws_vpc.nequi-platform-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nequi-platform-internet-gateway.id
  }
  tags = {
    Name = "nequi-platform-route-table-igw-${var.prefix_environment}"
    ProjectName = "PLATFORM-NEQUI"
  }
}

#Asociacion de subnets a las tablas de ruteo del Internet Gateway
resource "aws_route_table_association" "nequi-platform-routetableassociation-01" {
  subnet_id      = aws_subnet.nequi-platform-public-subnet-01.id
  route_table_id = aws_route_table.nequi-platform-route-table-igw.id
}

resource "aws_route_table_association" "nequi-platform-routetableassociation-02" {
  subnet_id      = aws_subnet.nequi-platform-public-subnet-02.id
  route_table_id = aws_route_table.nequi-platform-route-table-igw.id
}

#Informacion de la tabla de ruteo asociada al NAT Gateway
resource "aws_route_table" "nequi-platform-route-table-nat-01" {
  vpc_id = aws_vpc.nequi-platform-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nequi-platform-nat-gateway-01.id
  }
  tags = {
    Name = "nequi-platform-route-table-nat-01-${var.prefix_environment}"
    ProjectName = "PLATFORM-NEQUI"
  }
}

resource "aws_route_table" "nequi-platform-route-table-nat-02" {
  vpc_id = aws_vpc.nequi-platform-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nequi-platform-nat-gateway-02.id
  }
  tags = {
    Name = "nequi-platform-route-table-nat-02-${var.prefix_environment}"
    ProjectName = "PLATFORM-NEQUI"
  }
}

resource "aws_route_table_association" "nequi-platform-routetableassociation-03" {
  subnet_id      = aws_subnet.nequi-platform-private-subnet-01.id
  route_table_id = aws_route_table.nequi-platform-route-table-nat-01.id
}

resource "aws_route_table_association" "nequi-platform-routetableassociation-04" {
  subnet_id      = aws_subnet.nequi-platform-private-subnet-02.id
  route_table_id = aws_route_table.nequi-platform-route-table-nat-02.id
}
