data "aws_ami" "al2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_iam_role" "mongo" {
  name = "${var.name}-mongo-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "mongo_perm" {
  role       = aws_iam_role.mongo.name
  policy_arn = var.mongo_instance_policy_arn
}

resource "aws_iam_instance_profile" "mongo" {
  name = "${var.name}-mongo-profile"
  role = aws_iam_role.mongo.name
}

resource "aws_security_group" "mongo" {
  name        = "${var.name}-mongo-sg"
  description = "Mongo SG"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH (exercise)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  ingress {
    description     = "Mongo only from EKS nodes"
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "mongo" {
  ami                    = data.aws_ami.al2.id
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.public_subnets[0]
  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.mongo.id]
  iam_instance_profile   = aws_iam_instance_profile.mongo.name
  key_name               = aws_key_pair.mongo.key_name

  user_data = templatefile("${path.module}/mongo_user_data.sh.tpl", {
    mongo_user    = var.mongo_username
    mongo_pass    = var.mongo_password
    mongo_auth_db = var.mongo_auth_db
    bucket_name   = aws_s3_bucket.backups.bucket
  })

  tags = { Name = "${var.name}-mongo" }
}
