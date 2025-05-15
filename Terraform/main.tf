provider "aws" {
  region = "eu-north-1"
}

resource "aws_instance" "backend" {
  ami                         = "ami-04542995864e26699" # Ubuntu 22.04 in eu-north-1
  instance_type               = "t3.micro"
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.backend_sg.id]
  user_data                   = file("init.sh")
  tags = {
    Name = "mern-backend"
  }
}

resource "aws_security_group" "backend_sg" {
  name        = "mern-backend-sg"
  description = "Allow HTTP, SSH, and app port"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "frontend" {
  bucket = var.frontend_bucket
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "frontend_public_access_block" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
  
}
resource "aws_s3_bucket_website_configuration" "frontend_website" {
  bucket = aws_s3_bucket.frontend.id
  
  index_document {
    suffix = "index.html"
  }
  
  error_document {
    key = "index.html"
  }
}


resource "aws_s3_bucket_policy" "frontend_policy" {
  bucket = aws_s3_bucket.frontend.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "PublicReadGetObject"
        Effect = "Allow"
        Principal = "*"
        Action = ["s3:GetObject"]
        Resource = ["${aws_s3_bucket.frontend.arn}/*"]
      }
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.frontend_public_access_block]
}

resource "aws_s3_bucket" "media" {
  bucket = var.media_bucket
  force_destroy = true
}

resource "aws_iam_user" "s3_user" {
  name = "media-uploader"
}

resource "aws_iam_access_key" "s3_user_key" {
  user = aws_iam_user.s3_user.name
}

resource "aws_iam_user_policy" "s3_user_policy" {
  name = "s3-upload-policy"
  user = aws_iam_user.s3_user.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Action: ["s3:PutObject", "s3:GetObject"],
        Resource: "${aws_s3_bucket.media.arn}/*"
      }
    ]
  })
}

output "s3_user_access_key" {
  value = aws_iam_access_key.s3_user_key.id
  sensitive = true
}

output "s3_user_secret_key" {
  value = aws_iam_access_key.s3_user_key.secret
  sensitive = true
}
output "frontend_bucket_website_url" {
  value = aws_s3_bucket_website_configuration.frontend_website.website_endpoint
  sensitive = true
}
output "media_bucket_name" {
  value = aws_s3_bucket.media.bucket
  sensitive = true
}
output "media_bucket_arn" {
  value = aws_s3_bucket.media.arn
  sensitive = true
}
output "frontend_bucket_name" {
  value = aws_s3_bucket.frontend.bucket
  sensitive = true
}
output "frontend_bucket_arn" {
  value = aws_s3_bucket.frontend.arn
  sensitive = true
}
output "backend_instance_public_ip" {
  value = aws_instance.backend.public_ip
  sensitive = true
}
