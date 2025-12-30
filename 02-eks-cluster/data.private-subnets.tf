data "aws_subnets" "private" {
  filter {
    name   = "tag:Project"
    values = ["eks-devopsproject"]
  }

  filter {
    name   = "tag:Purpose"
    values = ["eks-devopsproject-cluster"]
  }
}
