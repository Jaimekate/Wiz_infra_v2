resource "tls_private_key" "mongo_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "mongo" {
  key_name   = "${var.name}-mongo-key"
  public_key = tls_private_key.mongo_ssh.public_key_openssh
}
