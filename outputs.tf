output "web_public_ip" {
  value       = aws_instance.web_server.public_ip
  description = "Public IP of Web Server"
}

output "rds_endpoint" {
  value       = aws_db_instance.mysql.endpoint
  description = "Internal DB Endpoint"
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.app_storage.id
  description = "S3 Bucket Name"
}