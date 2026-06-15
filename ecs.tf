
resource "aws_iam_instance_profile" "name" {
  role = aws_iam_role.ec2_role.name
}

# resource "aws_instance" "ecs_host" {
#   ami                  = "ami-006b300825259765d" 
#   instance_type        = "t2.micro"
#   subnet_id            = aws_subnet.private_subnet["eu-west-1a"].id 
#   vpc_security_group_ids = [aws_security_group.sg.id]
#   iam_instance_profile = aws_iam_instance_profile.name.name

#   # CRITICAL: This script tells the standalone instance to register with your cluster
#   user_data = <<-EOF
#               #!/bin/bash
#                yum update -y
#               yum install docker
#               service docker start
#               usermod -a -G docker ec2-user

#               echo ECS_CLUSTER=${aws_ecs_cluster.cluster_ecs.name} >> /etc/ecs/ecs.config 
#               EOF

#   tags = {
#     Name = "standalone-ecs-host"
#   }
# }


resource "aws_launch_template" "template" {
  iam_instance_profile {
    arn = aws_iam_instance_profile.name.arn
  }
  image_id = "ami-006b300825259765d"
  instance_type = "t2.micro"
  vpc_security_group_ids = [ aws_security_group.sg.id ]
  user_data = base64encode( <<-EOF
              #!/bin/bash
               yum update -y
              yum install docker
              service docker start
              usermod -a -G docker ec2-user

              echo ECS_CLUSTER=${aws_ecs_cluster.cluster_ecs.name} >> /etc/ecs/ecs.config 
              EOF 
              )
  
}





resource "aws_autoscaling_group" "example" {

  vpc_zone_identifier = [for s in aws_subnet.private_subnet : s.id]
  desired_capacity    = 1
  max_size            = 1
  min_size            = 1
  launch_template {
    id      = aws_launch_template.template.id
    version = "$Latest"
  }
}


resource "aws_ecs_capacity_provider" "cluster_ecs" {
  name = "example"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.example.arn

    managed_scaling {
      maximum_scaling_step_size = 2
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 1
    }
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