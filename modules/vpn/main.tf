data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ─── IAM Role for VPN ─────────────────────────────────────────────────────────
# Grants Session Manager (break-glass access without SSH key) and CloudWatch agent.

resource "aws_iam_role" "vpn" {
  name = "${var.project_name}-${var.environment}-vpn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "vpn_ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.vpn.name
}

resource "aws_iam_role_policy_attachment" "vpn_cloudwatch" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.vpn.name
}

resource "aws_iam_instance_profile" "vpn" {
  name = "${var.project_name}-${var.environment}-vpn-profile"
  role = aws_iam_role.vpn.name
}

# ─── Elastic IP for VPN ───────────────────────────────────────────────────────

resource "aws_eip" "vpn" {
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-vpn-eip"
  })
}

resource "aws_eip_association" "vpn" {
  instance_id   = aws_instance.vpn.id
  allocation_id = aws_eip.vpn.id
}

# ─── OpenVPN EC2 Instance ────────────────────────────────────────────────────

resource "aws_instance" "vpn" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_pair_name
  iam_instance_profile   = aws_iam_instance_profile.vpn.name

  # Must be disabled so VPN can route traffic between clients and private subnets
  source_dest_check = false

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true

    tags = merge(var.tags, {
      Name = "${var.project_name}-${var.environment}-vpn-root"
    })
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    environment     = var.environment
    project_name    = var.project_name
    vpn_client_cidr = var.vpn_client_cidr
  }))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-vpn"
    Role = "VPNServer"
  })
}
