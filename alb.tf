
resource "aws_lb" "alb" {
  name               = "ABL"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [for s in aws_subnet.public_subnet : s.id]

}

resource "aws_lb_listener" "list" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_target_group" "tg" {
  name        = "ecs"
  port        = "8081"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "instance"

  stickiness {
    type    = "lb_cookie"
    enabled = true
  }

  health_check {
    path                = "/"
    unhealthy_threshold = 6
    matcher             = "200,302"
  }

}

