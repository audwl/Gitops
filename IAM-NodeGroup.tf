# EKS Node Group용 IAM 역할
resource "aws_iam_role" "myungji_eks_node_role" {
  name = "myungji-eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# EKS 노드 그룹에 필요한 기본 정책 부착
resource "aws_iam_role_policy_attachment" "myungji_eks_worker_node_policy" {
  role       = aws_iam_role.myungji_eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "myungji_eks_cni_policy" {
  role       = aws_iam_role.myungji_eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "myungji_ec2_container_registry_read_only" {
  role       = aws_iam_role.myungji_eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
