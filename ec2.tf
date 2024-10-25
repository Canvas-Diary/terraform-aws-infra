data "aws_ami" "amzn-linux-2023-ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_launch_template" "ecs_instance_template" {
  name_prefix = "canvas-diary-"
  image_id = data.aws_ami.amzn-linux-2023-ami.id
  instance_type          = "t2.micro"
  key_name               = "canvas-diary"
  iam_instance_profile   = "ecsInstanceRole"

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster.name}" > /etc/ecs/ecs.config
              EOF

  network_interfaces {
    subnet_id = aws_subnet.public_subnet_1.id
  }

  block_device_mappings {
    ebs {
      volume_size = 30
    }
  }
}