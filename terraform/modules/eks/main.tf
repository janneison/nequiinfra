variable "prefix_environment" {
}

variable "vpc_id" {
}

variable "public_subnet_01_id" {
}

variable "public_subnet_02_id" {
}

variable "private_subnet_01_id" {
}

variable "private_subnet_02_id" {
}

#INFORMACION DE CLUSTER EKS
#Creacion de rol para manejo del EKS
resource "aws_iam_role" "nequi-platform-eksrole" {
  name = "nequi-platform-eksrole-${var.prefix_environment}"
  assume_role_policy = jsonencode({
                                    "Version": "2012-10-17",
                                    "Id": "PLATFORM_EKS_ASSUMEROLE_POLICY",
                                    "Statement": [
                                        {
                                        "Effect": "Allow",
                                        "Principal": {
                                            "Service": "eks.amazonaws.com",
                                            "AWS": "arn:aws:iam::847669793978:user/eks-user-deploy-qa"
                                        },
                                        "Action": "sts:AssumeRole"
                                        }
                                    ]
                                })
  tags = {
    Name = "nequi-platform-eksrole-${var.prefix_environment}"
    ProjectName = "PLATFORM-NEQUI"
  }
}

#Politica para administrar el EKS
resource "aws_iam_role_policy_attachment" "nequi-platform-eksrolepolicyAmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.nequi-platform-eksrole.name
}

#Politica para administrar los nodos del EKS
resource "aws_iam_role_policy_attachment" "nequi-platform-eksroleAmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.nequi-platform-eksrole.name
}

#Security group para el EKS
resource "aws_security_group" "nequi-platform-eksclustersecuritygroup" {
  name = "nequi-platform-eksclustersecuritygroup-${var.prefix_environment}"
  vpc_id = var.vpc_id
  tags = {
    Name = "nequi-platform-eksclustersecuritygroup-${var.prefix_environment}"
    ProjectName = "PLATFORM-NEQUI"
  }
}

#Politicas de acceso desde y hacia el cluster
resource "aws_security_group_rule" "nequi-platform-eksclusterinbound" {
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.nequi-platform-eksclustersecuritygroup.id
  source_security_group_id = aws_security_group.nequi-platform-eksclustersecuritygroup.id
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "nequi-platform-eksclusteroutbound" {
  description              = "Allow cluster API Server to communicate with the worker nodes"
  from_port                = 1024
  protocol                 = "tcp"
  security_group_id        = aws_security_group.nequi-platform-eksclustersecuritygroup.id
  source_security_group_id = aws_security_group.nequi-platform-eksclustersecuritygroup.id
  to_port                  = 65535
  type                     = "egress"
}

resource "aws_cloudwatch_log_group" "nequi-platform-cloudwatchloggroup" {
  name              = "/aws/eks/nequi-platform-eksclustercloudwatchloggroup-${var.prefix_environment}"
  retention_in_days = 30
  tags = {
    Name        = "nequi-platform-eksclustercloudwatchloggroup-${var.prefix_environment}"
    ProjectName = "PLATFORM-NEQUI"
    Environment-Pre = "Pre"
    Environment-QA = "QA"
  }
}

#Creacion del cluster EKS
resource "aws_eks_cluster" "nequi-platform-ekscluster" {
  name     = "nequi-platform-ekscluster-${var.prefix_environment}"
  version = "1.26"
  role_arn = aws_iam_role.nequi-platform-eksrole.arn
  vpc_config {
    endpoint_private_access=false
    endpoint_public_access=true
    security_group_ids = [
        aws_security_group.nequi-platform-eksclustersecuritygroup.id
    ]
    subnet_ids = [
        var.public_subnet_01_id,
        var.public_subnet_02_id,
        var.private_subnet_01_id,
        var.private_subnet_02_id
    ]
  }
  depends_on = [
    aws_iam_role_policy_attachment.nequi-platform-eksrolepolicyAmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.nequi-platform-eksroleAmazonEKSVPCResourceController,
    aws_cloudwatch_log_group.nequi-platform-cloudwatchloggroup
  ]
  tags = {
    Name = "nequi-platform-ekscluster-${var.prefix_environment}"
    ProjectName = "PLATFORM-NEQUI"
  }
}

#Endpoint del EKS
output "endpoint" {
  value = aws_eks_cluster.nequi-platform-ekscluster.endpoint
}

#Certificado de autorizacion del EKS
output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.nequi-platform-ekscluster.certificate_authority[0].data
}

resource "aws_iam_role" "eks-fargate-profile-dev" {
  name = "eks-fargate-profile-dev"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks-fargate-profile-dev" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks-fargate-profile-dev.name
}

resource "aws_eks_fargate_profile" "kube-system" {
  cluster_name           = aws_eks_cluster.nequi-platform-ekscluster.name
  fargate_profile_name   = "kube-system"
  pod_execution_role_arn = aws_iam_role.eks-fargate-profile-dev.arn

  # These subnets must have the following resource tag: 
  # kubernetes.io/cluster/<CLUSTER_NAME>.
  subnet_ids = [
        var.private_subnet_01_id,
        var.private_subnet_02_id
  ]

  selector {
    namespace = "kube-system"
  }
  tags = {
    ProjectName = "PLATFORM-NEQUI"
  }
}

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.nequi-platform-ekscluster.id
}

resource "null_resource" "k8s_patcher" {
  depends_on = [aws_eks_fargate_profile.kube-system]

  triggers = {
    endpoint = aws_eks_cluster.nequi-platform-ekscluster.endpoint
    ca_crt   = base64decode(aws_eks_cluster.nequi-platform-ekscluster.certificate_authority[0].data)
    token    = data.aws_eks_cluster_auth.eks.token
  }

  provisioner "local-exec" {
    command = <<EOH
cat >/tmp/ca.crt <<EOF
${base64decode(aws_eks_cluster.nequi-platform-ekscluster.certificate_authority[0].data)}
EOF
kubectl \
  --server="${aws_eks_cluster.nequi-platform-ekscluster.endpoint}" \
  --certificate_authority=/tmp/ca.crt \
  --token="${data.aws_eks_cluster_auth.eks.token}" \
  patch deployment coredns \
  -n kube-system --type json \
  -p="[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]"
EOH
  }
  lifecycle {
    ignore_changes = [triggers]
  }
}

resource "aws_eks_fargate_profile" "platform" {
  cluster_name           = aws_eks_cluster.nequi-platform-ekscluster.name
  fargate_profile_name   = "platform"
  pod_execution_role_arn = aws_iam_role.eks-fargate-profile-dev.arn
  # These subnets must have the following resource tag: 
  # kubernetes.io/cluster/<CLUSTER_NAME>.
  subnet_ids = [
        var.private_subnet_01_id,
        var.private_subnet_02_id
  ]
  selector {
    namespace = "platform"
  }
  tags = {
    ProjectName = "PLATFORM-NEQUI"
  }
}

data "tls_certificate" "nequi-platform-tls_certificate" {
  url = aws_eks_cluster.nequi-platform-ekscluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "nequi-platform-iam_openid_connect_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.nequi-platform-tls_certificate.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.nequi-platform-ekscluster.identity[0].oidc[0].issuer
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.nequi-platform-ekscluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.nequi-platform-ekscluster.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.nequi-platform-ekscluster.id]
      command     = "aws"
    }
  }
}

resource "helm_release" "metrics-server" {
  name = "metrics-server"

  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "3.8.2"

  set {
    name  = "metrics.enabled"
    value = false
  }

  depends_on = [aws_eks_fargate_profile.kube-system]
}


data "aws_iam_policy_document" "aws_load_balancer_controller_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.nequi-platform-iam_openid_connect_provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.nequi-platform-iam_openid_connect_provider.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "aws_load_balancer_controller" {
  assume_role_policy = data.aws_iam_policy_document.aws_load_balancer_controller_assume_role_policy.json
  name               = "aws-load-balancer-controller"
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  policy = file("./iam_policy.json")
  name   = "AWSLoadBalancerController"
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller_attach" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}

output "aws_load_balancer_controller_role_arn" {
  value = aws_iam_role.aws_load_balancer_controller.arn
}

resource "helm_release" "aws-load-balancer-controller" {
  name = "aws-load-balancer-controller-fourier-platform"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.4.1"

  set {
    name  = "clusterName"
    value = aws_eks_cluster.nequi-platform-ekscluster.name
  }

  set {
    name  = "image.tag"
    value = "v2.4.2"
  }

  set {
    name  = "replicaCount"
    value = 1
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.aws_load_balancer_controller.arn
  }

  # EKS Fargate specific
  set {
    name  = "region"
    value = "us-east-1"
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  depends_on = [aws_eks_fargate_profile.kube-system]
}