output "vpc_id" {
  value = aws_vpc.nequi-platform-vpc.id
}

output "public_subnet_01_id" {
  value = aws_subnet.nequi-platform-public-subnet-01.id
}

output "public_subnet_02_id" {
  value = aws_subnet.nequi-platform-public-subnet-02.id
}

output "private_subnet_01_id" {
  value = aws_subnet.nequi-platform-private-subnet-01.id
}

output "private_subnet_02_id" {
  value = aws_subnet.nequi-platform-private-subnet-02.id
}

output "routetable_igw" {
  value = aws_route_table.nequi-platform-route-table-igw.id
}
