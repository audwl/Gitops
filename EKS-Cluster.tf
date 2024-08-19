module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "myungji-eks-cluster"
  cluster_version = "1.30"

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.public_subnets

  # 추가된 보안 그룹 규칙
  cluster_security_group_additional_rules = {
    ingress = {
      description                = "EKS Cluster allows 443 port to get API call"
      type                       = "ingress"
      from_port                  = 443
      to_port                    = 443
      protocol                   = "TCP"
      cidr_blocks                = ["0.0.0.0/0"]  # 모든 IP에서 접근 허용
      source_node_security_group = false
    }
  }

  tags = {
    Name = "myungji-eks-cluster"
  }
}
