locals {
  ecs_cluster_name = "cluster_ecs"
}

resource "aws_iam_instance_profile" "name" {
  name = "ecs-instance-profile"
  role = aws_iam_role.ec2_role.name
}

data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

resource "aws_launch_template" "template" {
  name_prefix   = "ecs-template-"
  image_id      = data.aws_ssm_parameter.ecs_ami.value
  instance_type = "t2.micro"

  iam_instance_profile {
    arn = aws_iam_instance_profile.name.arn
  }

  vpc_security_group_ids = [aws_security_group.sg.id]


  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${local.ecs_cluster_name} >> /etc/ecs/ecs.config
  EOF
  )
}


resource "aws_autoscaling_group" "example" {
  name                = "ecs-asg"
  vpc_zone_identifier = [for s in aws_subnet.private_subnet : s.id]
  desired_capacity    = 1
  max_size            = 2
  min_size            = 1
  target_group_arns = [ aws_lb_target_group.tg.arn ]
  launch_template {
    id      = aws_launch_template.template.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
}


resource "aws_ecs_capacity_provider" "cluster_ecs" {
  name = "example-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.example.arn

    managed_scaling {
      maximum_scaling_step_size = 2
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100 # Target 100% utilization of instances
    }
  }
}

# 5. ECS Cluster & Association
resource "aws_ecs_cluster" "cluster_ecs" {
  name = local.ecs_cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}


resource "aws_ecs_cluster_capacity_providers" "example" {
  cluster_name       = aws_ecs_cluster.cluster_ecs.name
  capacity_providers = [aws_ecs_capacity_provider.cluster_ecs.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.cluster_ecs.name
  }
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/app"
  retention_in_days = 7  
}

