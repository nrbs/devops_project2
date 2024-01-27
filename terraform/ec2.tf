resource "aws_instance" "eks_management_instance" {
  ami           = "ami-0c7217cdde317cfec" # Free tier Ubuntu Server 22.04 LTS
  instance_type = "t2.micro"              # Free tier eligible
  key_name      = "nur-aws-kp"            # Key pair name to access the instance


  subnet_id                   = module.vpc.public_subnets[0]              # Public subnet to launch the instance
  associate_public_ip_address = true                                      # Assign a public IP address to the instance
  vpc_security_group_ids      = [aws_security_group.eks_management_sg.id] # Security group to allow SSH access

  tags = {
    Name        = "EKS manager instance"
    Environment = "dev"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt install unzip
              
              # Install AWS CLI
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              sudo ./aws/install
              aws --version

              # AWS Configure
              # aws configure
              # aws configure set aws_access_key_id DOLLAR{var.aws_access_key}

              # Install kubectl
              curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
              curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
              sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
              kubectl version --client
              aws eks update-kubeconfig --name my-cluster --region us-east-1

              # Install Istio
              curl -L https://istio.io/downloadIstio | sh -
              cd istio*
              export PATH=$PWD/bin:$PATH
              istioctl install --set profile=demo -y

              # Install ArgoCD
              curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
              sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
              rm argocd-linux-amd64

              # Namespace
              kubectl create namespace argocd
              kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
              kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
              argocd admin initial-password -n argocd > argocd-password.txt


              EOF

}

resource "aws_security_group" "eks_management_sg" {
  name        = "eks_management_sg"
  description = "Security group to allow SSH access to EKS management instance"

  vpc_id = module.vpc.vpc_id

  ingress {
    description = "Allow SSH access from my public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["209.122.83.186/32"] # My public IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "EKS management instance SG"
    Environment = "dev"
  }

}
