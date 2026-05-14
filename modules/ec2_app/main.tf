data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ─── IAM Role for EC2 ─────────────────────────────────────────────────────────

resource "aws_iam_role" "app" {
  name = "${var.project_name}-${var.environment}-app-role"

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

resource "aws_iam_role_policy_attachment" "ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.app.name
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.app.name
}

resource "aws_iam_role_policy" "secrets" {
  name = "${var.project_name}-${var.environment}-app-secrets"
  role = aws_iam_role.app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = "arn:aws:secretsmanager:*:*:secret:${var.project_name}/${var.environment}/*"
    }]
  })
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.project_name}-${var.environment}-app-profile"
  role = aws_iam_role.app.name
}

# ─── Launch Template ──────────────────────────────────────────────────────────

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-${var.environment}-app-"
  description   = "Launch template for ${var.project_name} ${var.environment} app servers"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = [var.security_group_id]

  iam_instance_profile {
    name = aws_iam_instance_profile.app.name
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_type           = "gp3"
      volume_size           = var.root_volume_size
      encrypted             = true
      delete_on_termination = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    environment  = var.environment
    project_name = var.project_name
    aws_region   = var.aws_region
    env_display  = lookup({ dev = "Development", staging = "Staging", prod = "Production" }, var.environment, var.environment)
  }))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 enforced
    http_put_response_hop_limit = 1
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.project_name}-${var.environment}-app"
      Role = "AppServer"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.tags, {
      Name = "${var.project_name}-${var.environment}-app-volume"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ─── Auto Scaling Group ──────────────────────────────────────────────────────
# Spreads instances across both private subnets (AZ1 + AZ2). If an AZ goes down
# or an instance fails, ASG launches a replacement automatically.

resource "aws_autoscaling_group" "app" {
  name_prefix         = "${var.project_name}-${var.environment}-app-"
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = [var.target_group_arn]

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  health_check_type         = "ELB"
  health_check_grace_period = 300

  # Distribute instances evenly across AZs
  default_cooldown = 300

  launch_template {
    id      = aws_launch_template.app.id
    version = aws_launch_template.app.latest_version
  }

  # Rolling instance replacement when launch template changes
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 300
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-app"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ─── CPU-based Target Tracking Scaling ───────────────────────────────────────

resource "aws_autoscaling_policy" "cpu_target" {
  name                   = "${var.project_name}-${var.environment}-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}
