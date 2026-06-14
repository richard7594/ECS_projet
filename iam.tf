data "aws_iam_policy_document" "infra_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ecs.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "infra_role" {
  assume_role_policy = data.aws_iam_policy_document.infra_role.json
}

resource "aws_iam_role_policy_attachment" "name" {
  role       = aws_iam_role.infra_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECSInfrastructureRolePolicyForManagedInstances"
}
resource "aws_iam_role_policy_attachment" "name1" {
  role       = aws_iam_role.infra_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}
##

data "aws_iam_policy_document" "ec2_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "ec2_role" {
  assume_role_policy = data.aws_iam_policy_document.infra_role.json
}

