# 보안그룹 - Bastion 호스트 수정
resource "aws_security_group" "bastion" {
  name        = "bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id

  # SSH 접근 허용
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.bastion_cidr_block]
  }

  # 모든 아웃바운드 트래픽 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "BastionHost"
  }
}

# EKS 노드 보안 그룹 수정
resource "aws_security_group" "eks_node" {
  name        = "eks-node-sg"
  description = "Security group for EKS nodes"
  vpc_id      = var.vpc_id

  # Bastion에서의 kubectl 명령어 접근 허용 (EKS 노드)
  ingress {
    from_port       = 10250
    to_port         = 10250
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # EKS 클러스터 API 서버 접근을 위한 443 포트 오픈
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # 모든 아웃바운드 트래픽 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "EKSNodeSG"
  }
}
