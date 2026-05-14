output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

output "public_subnet_az1_id" {
  value = aws_subnet.public_az1.id
}

output "public_subnet_az2_id" {
  value = aws_subnet.public_az2.id
}

output "private_subnet_az1_id" {
  value = aws_subnet.private_az1.id
}

output "private_subnet_az2_id" {
  value = aws_subnet.private_az2.id
}

output "public_subnet_ids" {
  value = [aws_subnet.public_az1.id, aws_subnet.public_az2.id]
}

output "private_subnet_ids" {
  value = [aws_subnet.private_az1.id, aws_subnet.private_az2.id]
}
