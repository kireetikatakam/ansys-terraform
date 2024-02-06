output "ec2_instance" {
  value = {
    instance_id = aws_instance.nginx.id
    public_ip   = aws_instance.nginx.public_ip
  }
}