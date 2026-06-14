
resource "aws_iam_instance_profile" "name" {
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "ecs_host" {
  ami                  = "ami-006b300825259765d" 
  instance_type        = "t2.micro"
  subnet_id            = aws_subnet.private_subnet["eu-west-1a"].id 
  vpc_security_group_ids = [aws_security_group.sg.id]
  iam_instance_profile = aws_iam_instance_profile.name.name

  # CRITICAL: This script tells the standalone instance to register with your cluster
  user_data = <<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=${aws_ecs_cluster.cluster_ecs.name} >> /etc/ecs/ecs.config
              EOF

  tags = {
    Name = "standalone-ecs-host"
  }
}

resource "aws_ecs_cluster" "cluster_ecs" {
  name = "cluster_ecs"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# resource "aws_ecs_capacity_provider" "cluster_ecs" {
#   name    = "cluster_ecs"
#   cluster = aws_ecs_cluster.cluster_ecs.name
  

#   managed_instances_provider {
#     infrastructure_role_arn = aws_iam_role.infra_role.arn

#     instance_launch_template {
#       ec2_instance_profile_arn = aws_iam_instance_profile.name.arn
#       monitoring               = "DETAILED"
#       network_configuration {
#         subnets         = [for s in aws_subnet.private_subnet : s.id]
#         security_groups = [aws_security_group.sg.id]

#       }

#     }
#   }
# }

resource "aws_ecs_task_definition" "task" {
  family = "service"
  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "dhi.io/jenkins:latest"
      cpu       = 10
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 0
        }
      ]
    }

  ])

}


resource "aws_ecs_service" "app" {
  name            = "app"
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1
  iam_role        = aws_iam_role.infra_role.arn
  cluster = aws_ecs_cluster.cluster_ecs.name
  launch_type     = "EC2"

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = "app"
    container_port   = 80
  }

}