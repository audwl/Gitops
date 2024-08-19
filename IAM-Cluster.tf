resource "aws_iam_role" "myungji_eks_role" {
  name = "myungji-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "myungji_eks_role_policy" {
  role       = aws_iam_role.myungji_eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# 추가된 관리자 역할
resource "aws_iam_role" "myungji_eks_admin_role" {
  name = "myungji-eks-admin-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_admin_policy" {
  role       = aws_iam_role.myungji_eks_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_vpc_policy" {
  role       = aws_iam_role.myungji_eks_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"  # 올바른 정책으로 수정
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  role       = aws_iam_role.myungji_eks_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# IAM 인스턴스 프로파일 추가
resource "aws_iam_instance_profile" "myungji_eks_admin_profile" {
  name = "myungji-eks-admin-profile"
  role = aws_iam_role.myungji_eks_admin_role.name
}
