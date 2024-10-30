resource "aws_eip" "elb" {
  domain = "vpc"
}

resource "aws_lb" "nlb" {
  load_balancer_type = "network"
  name               = "canvas-diary-nlb"
  internal           = false

  subnet_mapping {
    subnet_id     = aws_subnet.public_subnet_1.id
    allocation_id = aws_eip.elb.id
  }

  security_groups = [aws_security_group.ec2_sg.id]
}

resource "aws_lb_target_group" "nlb_tg" {
  name     = "canvas-diary-nlb-tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_vpc.main_vpc.id

  health_check {
    path     = "/swagger-ui/index.html"
    timeout  = 10
    interval = 10
  }
}

resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = aws_lb.nlb.arn
  protocol          = "TCP"
  port              = "80"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_tg.arn
  }
}