data "aws_ami" "amzn-linux-2023-ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "ec2_instance" {
  ami                    = data.aws_ami.amzn-linux-2023-ami.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet_1.id
  key_name               = "canvas-diary"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  availability_zone      = "ap-northeast-2a"
  iam_instance_profile   = "ecsInstanceRole"

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install ecs-init -y
              echo "ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster.name}" > /etc/ecs/ecs.config
              usermod -aG docker ec2-user
              systemctl enable --now --no-block ecs.service
              EOF

  root_block_device {
    volume_size = 20
  }

  lifecycle {
    replace_triggered_by = [aws_security_group.ec2_sg]
  }

  tags = {
    Name = "ec2_instance"
  }
}