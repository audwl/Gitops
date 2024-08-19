resource "aws_eks_node_group" "myungji_node_group" {
  cluster_name    = module.eks.cluster_name
  node_group_name = "myungji-managed-node-group"
  node_role_arn   = aws_iam_role.myungji_eks_node_role.arn
  subnet_ids      = module.vpc.private_subnets

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]

  remote_access {
    ec2_ssh_key = "myungji"
  }

  tags = {
    Name = "myungji-managed-node-group"
  }
}
