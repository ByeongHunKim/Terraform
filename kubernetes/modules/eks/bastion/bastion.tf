data "aws_ami" "latest_amazon_ami" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.latest_amazon_ami.id
  instance_type = ""
  key_name      = ""

  subnet_id         = var.public_subnet_id
  security_groups   = [var.security_group_id]
  associate_public_ip_address = true

  tags = {
    Name = "BastionHost"
  }
}
