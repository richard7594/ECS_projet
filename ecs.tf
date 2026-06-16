# 1. Define the cluster name as a local to break the cyclic dependency
locals {
  ecs_cluster_name = "cluster_ecs"
}

resource "aws_iam_instance_profile" "name" {
  name = "ecs-instance-profile"
  role = aws_iam_role.ec2_role.name
}


resource "aws_launch_template" "template" {
  name_prefix   = "ecs-template-"
  image_id      = "ami-006b300825259765d"
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


resource "aws_ecs_task_definition" "task" {
  family             = "service"
  network_mode       = "bridge"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "jenkins/jenkins:latest"
      cpu       = 10
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 0 # Dynamic port mapping (required for EC2/Bridge mode with multiple tasks)
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app.name
          awslogs-region        = "eu-west-1"  
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# 7. ECS Service
resource "aws_ecs_service" "app" {
  name                 = "app"
  cluster              = aws_ecs_cluster.cluster_ecs.id
  task_definition      = aws_ecs_task_definition.task.arn
  desired_count        = 1
  force_new_deployment = true

   capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.cluster_ecs.name
    weight            = 100
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = "app"
    container_port   = 80
  }

  # Recommended to allow the LB to attach tasks safely
  depends_on = [aws_lb_target_group.tg]
}