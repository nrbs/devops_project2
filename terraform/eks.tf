module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.20.0"

  cluster_name    = "my-cluster"
  cluster_version = "1.28"

  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }
  
  subnet_ids               = module.vpc.private_subnets
  vpc_id                   = module.vpc.vpc_id
  control_plane_subnet_ids = module.vpc.public_subnets

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["m6i.large", "m5.large", "m5n.large", "t3.large"]
  }

  eks_managed_node_groups = {

    green = {
      use_custom_launch_template = false
      min_size                   = 1
      max_size                   = 10
      desired_size               = 1

      instance_types = ["t3.large"]
      capacity_type  = "SPOT"
    }
  }

  # Fargate Profile(s)
  fargate_profiles = {
    default = {
      name = "default"
      selectors = [
        {
          namespace = "default"
        }
      ]
    }
  }

  # aws-auth configmap
  manage_aws_auth_configmap = false

  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::083849672660:role/role1"
      username = "role1"
      groups   = ["system:masters"]
    },
  ]

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::083849672660:user/protouser"
      username = "protouser"
      groups   = ["system:masters"]
    }
  ]

  aws_auth_accounts = [
    "083849672660"
  ]

  cluster_security_group_additional_rules = {
    ec2_ingress = {
      description              = "Allow connections from EC2 to EKS cluster"
      from_port                = 443
      to_port                  = 443
      type                     = "ingress"
      protocol                 = "tcp"
      source_security_group_id = aws_security_group.eks_management_sg.id
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

