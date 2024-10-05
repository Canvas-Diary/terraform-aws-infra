resource "aws_db_instance" "rds_instance" {
  allocated_storage      = 20
  db_name                = "canvas_diary_mysql"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t4g.micro"
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = "default.mysql8.0"
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.id
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  availability_zone      = "ap-northeast-2a"
  skip_final_snapshot    = true
}