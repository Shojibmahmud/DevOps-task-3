terraform {required_providers {aws = {source = "hashicorp/aws" version = "~> 2.70"}
    docker = {source = "kreuzwerker/docker"}
 }
}provider "aws" {profile= "default" region= "us-east-2"}
provider "docker" {host = "tcp://127.0.0.1:2376/"}
resource "aws_key_pair" "devops_task_key" 
{
  key_name = "devops_task_key"
  public_key = file("devops_task_key.pub")
}
resource "aws_security_group" "devops_task_security-group" {
  name= "devops_task_security-group"
  description = "Allow HTTP, HTTPS and SSH traffic"
     ingress { description = "SSH"
    from_port = 22
    to_port = 22
    protocol= "tcp"
    cidr_blocks = ["0.0.0.0/0"] }
  ingress {
    description= "HTTPS"
    from_port = 443
    to_port = 443
    protocol= "tcp"
    cidr_blocks= ["0.0.0.0/0"]}
  ingress {
    description= "HTTP"
    from_port = 80
    to_port= 80
    protocol= "tcp"
    cidr_blocks = ["0.0.0.0/0"]}
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]}}

resource "aws_instance" "devops_task_ec2" { ami= "ami-06be10ae4a207f54a"
  instance_type= "t2.micro"
  key_name = aws_key_pair.devops_task_key.key_name
  user_data = file("ec2.sh")
  disable_api_termination= false
  ebs_optimized= false
  hibernation  = false
  monitoring  = false
  tags  = {}
  credit_specification {cpu_credits = "standard"}
  vpc_security_group_ids = [aws_security_group.devops_task_security-group.id]
}
resource "aws_db_instance" "devops_task_db" {
  name = "devops_task_db"
  engine = "postgres"
  instance_class= "db.t2.micro"
  allocated_storage= 20
  username = "dbadmin"
  password = "Lknb6FZ44CDBhDeG"
  vpc_security_group_ids = [ aws_security_group.devops_task_security-group.id]}
resource "aws_api_gateway_rest_api" "devops_task_api" {
  name= "devops_task_api"
  description = "This is my API for demonstration purposes"
}
resource "aws_api_gateway_resource" "devops_task_api-resource1" {
  rest_api_id = aws_api_gateway_rest_api.devops_task_api.id
  parent_id = aws_api_gateway_rest_api.devops_task_api.root_resource_id
  path_part  = "date"}
resource "aws_api_gateway_method" "devops_task_api-resource1-method1" {
  rest_api_id   = aws_api_gateway_rest_api.devops_task_api.id
  resource_id = aws_api_gateway_resource.devops_task_api-resource1.id
  http_method  = "GET"
  authorization = "NONE"}
resource "aws_api_gateway_integration" "devops_task_api-resource1-method1-integration" {
  rest_api_id = aws_api_gateway_rest_api.devops_task_api.id
  resource_id = aws_api_gateway_resource.devops_task_api-resource1.id
  http_method = aws_api_gateway_method.devops_task_api-resource1-method1.http_method
  type = "HTTP_PROXY"
  integration_http_method   = "GET"
  uri                       = "http://${aws_instance.devops_task_ec2.public_ip}/"}
resource "docker_container" "devops_task_zap-container" {
  name  = "devops_task_zap"
  image = docker_image.devops_task_zap-image.latest
  command = ["python", "autostart.py",
        "-f", "python zap-full-scan.py -t http://${aws_instance.devops_task_ec2.public_ip}/"]}
resource "docker_image" "devops_task_zap-image" {
  name = "devops_task_zap-image"
  build {path = "zap"}}
output "public_ec2_ip" {
  value = aws_instance.devops_task_ec2.public_ip
  description = "Public server IP"}
output "db_address" {
  value = aws_db_instance.devops_task_db.address
  description = "Database adress"}
output "db_password" {
  value = aws_db_instance.devops_task_db.password
  description = "Database password"
}
