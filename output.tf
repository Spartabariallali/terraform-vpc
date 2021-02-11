output "public-subnet" {
    description = "availability zone for public subnets"
    value =  aws_subnet.public-subnets.*.availability_zone
}


output "private-subnet" {
    description = "availability zone for private subnets"
    value = aws_subnet.private-subnets.*.availability_zone
}

# output "main" {
#     description = "returns dns hostname"
#     value = aws_vpc.main.enable_dns_hostnames
# }

output "IGW" {
    value = aws_internet_gateway.igw.vpc_id
}

output "route" {
    value = aws_route.internet-access.route_table_id
}

output "nat-gateway" {
    value = aws_nat_gateway.nat-gw.*.subnet_id
}

output "allocation" {
    value = aws_nat_gateway.nat-gw.*.allocation_id
}