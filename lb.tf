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

resource "aws_lb_listener" "nlb_listener_http" {
  load_balancer_arn = aws_lb.nlb.arn
  protocol          = "TCP"
  port              = "80"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_tg.arn
  }
}

resource "aws_lb_listener" "nlb_listener_https" {
  load_balancer_arn = aws_lb.nlb.arn
  protocol          = "TLS"
  port              = "443"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = "arn:aws:acm:ap-northeast-2:339713161378:certificate/81d8eb70-4fdc-4dc2-9057-0f05c0be9d40"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_tg.arn
  }
}