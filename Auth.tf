# EKS 클러스터 인증 데이터
data "aws_eks_cluster_auth" "myungji_eks_cluster" {
  name = module.eks.cluster_name
}

# Kubernetes provider 설정
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

# aws-auth ConfigMap 생성
resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = <<YAML
- rolearn: ${aws_iam_role.myungji_eks_admin_role.arn}
  username: admin
  groups:
  - system:masters
YAML

    mapUsers = <<YAML
- userarn: arn:aws:iam::213899591783:user/myungji.kim
  username: myungji.kim
  groups:
  - system:masters
YAML
  }

  depends_on = [module.eks]
}
