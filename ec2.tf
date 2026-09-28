data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = "my -web -server"
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  # Automated web server setup
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y nginx mysql-client awscli
              systemctl start nginx
              systemctl enable nginx
              echo "<h1>Multi-Tier App Running! S3 Bucket: ${aws_s3_bucket.app_storage.id}</h1>" > /var/www/html/index.html
              EOF

  tags = { Name = "web-tier-server" }
}