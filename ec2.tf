data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "ec2_instance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_subnet.id
  key_name               = "canvas-diary"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  availability_zone      = "ap-northeast-2a"

  lifecycle {
    replace_triggered_by = [aws_security_group.ec2_sg]
  }

  tags = {
    Name = "ec2_instance"
  }
}