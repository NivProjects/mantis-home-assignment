data "aws_ami" "amazon_linux_2023" { # get latest Amazon Linux 2023 AMI
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

resource "aws_security_group" "k8s_sg" {
  name        = "k8s-cluster-sg"
  description = "Security group for Kubeadm single node cluster"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1" # all
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-sg"
  }
}

resource "aws_key_pair" "k8s_key" { # if SSM not working 
  key_name   = "k8s-node-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "k8s_node" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  key_name               = aws_key_pair.k8s_key.key_name
  iam_instance_profile   = "Moveo-EC2Role"


  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "k8s-kubeadm-node"
  }
}
