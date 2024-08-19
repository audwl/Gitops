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
  external_nat_ip_ids  = [aws_eip.nat.id]

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
