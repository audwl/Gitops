resource "aws_security_group" "kubectl_sg" {
  name        = "myungji-kubectl-sg"
  description = "Security group for kubectl instance"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "myungji-kubectl-sg"
  }
}

resource "aws_instance" "kubectl_instance" {
  ami           = "ami-0c2acfcb2ac4d02a0"
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
              yum update -y
              yum install -y aws-cli jq
              curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/kubectl
              chmod +x ./kubectl
              mv ./kubectl /usr/local/bin/

              aws eks --region ap-northeast-2 update-kubeconfig --name myungji-eks-cluster --role-arn ${aws_iam_role.myungji_eks_admin_role.arn} --kubeconfig /home/ec2-user/.kube/config

              mkdir -p /home/ec2-user/.kube
              chown ec2-user:ec2-user /home/ec2-user/.kube /home/ec2-user/.kube/config
              chmod 600 /home/ec2-user/.kube/config
              echo "export KUBECONFIG=/home/ec2-user/.kube/config" >> /home/ec2-user/.bashrc
              source /home/ec2-user/.bashrc
              EOF
}
