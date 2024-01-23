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
