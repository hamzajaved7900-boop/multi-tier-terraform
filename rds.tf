# Subnet Group for RDS (AZ a + b)
resource "aws_db_subnet_group" "db_subnet" {
  name       = "rds-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  tags       = { Name = "Main DB Subnet Group" }
}

# RDS MySQL Free-tier compatible Instance
resource "aws_db_instance" "mysql" {
  allocated_storage      = 20
  max_allocated_storage  = 50
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = "appdb"
  username               = "dbadmin"
  password               = var.db_password
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  publicly_accessible    = false

  tags = { Name = "production-mysql" }
}