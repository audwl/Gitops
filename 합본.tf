module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  
  name = "myungji-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true  # NAT 게이트웨이 하나만 생성
  reuse_nat_ips        = true  # Elastic IP 재사용
  external_nat_ip_ids  = [aws_eip.nat.id]  # NAT 게이트웨이에 사용할 EIP 지정

  tags = {
    Name = "myungji-vpc"
  }
}

# NAT Gateway에 필요한 Elastic IP 생성
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "myungji-vpc-nat-eip"
  }
}
# EKS 클러스터에 필요한 IAM 역할
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

# EC2 인스턴스에 필요한 IAM 역할
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
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  role       = aws_iam_role.myungji_eks_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# EC2 인스턴스를 위한 IAM 인스턴스 프로파일
resource "aws_iam_instance_profile" "myungji_eks_admin_profile" {
  name = "myungji-eks-admin-profile"
  role = aws_iam_role.myungji_eks_admin_role.name
}
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
# EC2 인스턴스를 위한 보안 그룹 정의
resource "aws_security_group" "kubectl_sg" {
  name        = "myungji-kubectl-sg"
  description = "Security group for kubectl instance"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # SSH 접근 허용
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # HTTPS 접근 허용 (EKS API 서버 접근)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # 모든 아웃바운드 트래픽 허용
  }

  tags = {
    Name = "myungji-kubectl-sg"
  }
}


# EKS-Cluster.tf
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

# Kubernetes provider 설정 (alias 추가)
provider "kubernetes" {
  alias                  = "eks_cluster"
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

# 리소스에서 alias된 provider를 사용하는 경우:
# resource "kubernetes_config_map" "example" {
#   provider = kubernetes.eks_cluster
#   ...
# }
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
# EC2 인스턴스 생성
resource "aws_instance" "kubectl_instance" {
  ami           = "ami-0c2acfcb2ac4d02a0"  # Amazon Linux 2 AMI
  instance_type = "t3.micro"
  key_name      = "myungji"

  vpc_security_group_ids = [aws_security_group.kubectl_sg.id]
  subnet_id              = module.vpc.public_subnets[0]

  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.myungji_eks_admin_profile.name

  tags = {
    Name = "myungji-kubectl-ec2"
  }

  user_data = <<-EOF
            #!/bin/bash
            # 시스템 업데이트 및 필요한 패키지 설치
            yum update -y
            yum install -y aws-cli jq
            
            # kubectl 다운로드 및 설치
            curl -o /usr/local/bin/kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/kubectl
            chmod +x /usr/local/bin/kubectl
            
            # kubectl 설정을 위한 kubeconfig 파일 생성
            mkdir -p /home/ec2-user/.kube

            # AWS CLI의 기본 리전 설정 (필요에 따라 설정)
            export AWS_DEFAULT_REGION=ap-northeast-2

            # EKS 클러스터에 대한 kubeconfig 파일 생성 시도 및 재시도
            RETRY_COUNT=0
            MAX_RETRIES=5
            while [ ! -f /home/ec2-user/.kube/config ] && [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
                aws eks --region ap-northeast-2 update-kubeconfig --name myungji-eks-cluster --role-arn ${aws_iam_role.myungji_eks_admin_role.arn} --kubeconfig /home/ec2-user/.kube/config
                RETRY_COUNT=$((RETRY_COUNT+1))
                if [ ! -f /home/ec2-user/.kube/config ]; then
                    echo "Retrying in 30 seconds..."
                    sleep 30
                fi
            done
            
            # 올바른 권한 설정
            chown -R ec2-user:ec2-user /home/ec2-user/.kube
            chmod 600 /home/ec2-user/.kube/config
            
            # KUBECONFIG 환경 변수 설정
            echo "export KUBECONFIG=/home/ec2-user/.kube/config" >> /home/ec2-user/.bashrc
            source /home/ec2-user/.bashrc
            EOF






}