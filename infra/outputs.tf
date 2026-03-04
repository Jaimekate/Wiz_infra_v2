output "cluster_name" { value = module.eks.cluster_name }

output "mongo_public_ip" { value = aws_instance.mongo.public_ip }
output "mongo_private_ip" { value = aws_instance.mongo.private_ip }

output "backup_bucket" { value = aws_s3_bucket.backups.bucket }

output "mongo_ssh_private_key_pem" {
  value     = tls_private_key.mongo_ssh.private_key_pem
  sensitive = true
}
