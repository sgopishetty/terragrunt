# Create public subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id     = var.vpc_id
  cidr_block = var.public_subnet_cidrs[count.index]
  #availability_zone = var.availability_zones[count.index % length(var.availability_zones)]
  map_public_ip_on_launch = true

  tags = merge(
    var.public_subnet_tags,
    {
      "Name" = "chapi-${var.env}-public-subnet-${count.index + 1}"
    }
  )
}

# Create private subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id     = var.vpc_id
  cidr_block = var.private_subnet_cidrs[count.index]

  tags = merge(
    var.private_subnet_tags,
    {
      "Name" = "chapi-${var.env}-private-subnet-${count.index + 1}"
    }
  )
}

# Create public route table
resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  tags = {
    "Name" = "chapi-${var.env}-public-route-table"
  }
}

# Associate public subnets with the public route table
resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Create private route table
resource "aws_route_table" "private" {
  vpc_id = var.vpc_id

  tags = {
    "Name" = "chapi-${var.env}-private-route-table"
  }
}

# Associate private subnets with the private route table
resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}


# Create route for public subnets to access the internet
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.internet_gateway_id
}

#resource "aws_route" "private_nat_gateway" {
#  route_table_id         = aws_route_table.private.id
#  destination_cidr_block = "0.0.0.0/0"
#  nat_gateway_id         = var.nat_gateway_id
#}