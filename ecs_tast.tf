
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

  depends_on = [aws_lb_target_group.tg]
}