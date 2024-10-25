data "aws_ami" "amzn-linux-2023-ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_launch_template" "ecs_instance_template" {
  name_prefix   = "canvas-diary-"
  image_id      = data.aws_ami.amzn-linux-2023-ami.id
  instance_type = "t2.micro"
  key_name      = "canvas-diary"

  network_interfaces {
    security_groups = [aws_security_group.ec2_sg.id]
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 30
    }
  }

  iam_instance_profile {
    name = "ecsInstanceRole"
  }

  user_data = base64encode(
    <<-EOF
    #!/bin/bash
    # mysql client 설치
    wget https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm
    dnf install mysql80-community-release-el9-1.noarch.rpm -y
    dnf update -y
    dnf install mysql-community-client -y

    # ECS container agent 설치
    yum update -y
    yum install ecs-init -y
    echo "ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster.name}" > /etc/ecs/ecs.config
    systemctl enable --now --no-block ecs.service

    # Docker 권한 설정
    usermod -aG docker ec2-user
    EOF
  )
}