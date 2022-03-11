# Create VPC
resource "aws_vpc" "blog-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
}

# Create Public Subnet for EC2
resource "aws_subnet" "public-subnet" {
  vpc_id                  = aws_vpc.blog-vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true" //it makes this a public subnet
  availability_zone       = var.AZ1
}

# Create Private subnet for RDS
resource "aws_subnet" "private-subnet-1" {
  vpc_id                  = aws_vpc.blog-vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = "false" //it makes private subnet
  availability_zone       = var.AZ2
}

# Create second Private subnet for RDS
resource "aws_subnet" "private-subnet-2" {
  vpc_id                  = aws_vpc.blog-vpc.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = "false" //it makes private subnet
  availability_zone       = var.AZ3
}

# Create IGW for internet connection 
resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.blog-vpc.id
}

# Create Route table 
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.blog-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gateway.id
  }
}

# Associating route tabe to public subnet
resource "aws_route_table_association" "rta-public-subnet" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-route-table.id
}

//security group for EC2
resource "aws_security_group" "ec2-sg" {
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "MYSQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = aws_vpc.blog-vpc.id
  tags = {
    Name = "allow ssh,http,https"
  }
}

# Security group for RDS
resource "aws_security_group" "rds-sg" {
  vpc_id = aws_vpc.blog-vpc.id
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${aws_security_group.ec2-sg.id}"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow ec2"
  }
}

# Create RDS Subnet group
resource "aws_db_subnet_group" "rds-subnet-group" {
  subnet_ids = ["${aws_subnet.private-subnet-1.id}", "${aws_subnet.private-subnet-2.id}"]
}

# Create RDS instance
resource "aws_db_instance" "wordpress-db" {
  allocated_storage      = 10
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = var.instance_class
  db_subnet_group_name   = aws_db_subnet_group.rds-subnet-group.id
  vpc_security_group_ids = ["${aws_security_group.rds-sg.id}"]
  name                   = var.database_name
  username               = var.database_user
  password               = var.database_password
  skip_final_snapshot    = true
}

data "template_file" "playbook" {
  template = file("${path.module}/wp_install.yml")
  vars = {
    db_username      = "${var.database_user}"
    db_user_password = "${var.database_password}"
    db_name          = "${var.database_name}"
    db_RDS           = "${aws_db_instance.wordpress-db.endpoint}"
  }
}

# Create EC2 after RDS is provisioned
resource "aws_instance" "wordpress-ec2" {
  ami             = var.ami
  instance_type   = var.instance_type
  subnet_id       = aws_subnet.public-subnet.id
  security_groups = ["${aws_security_group.ec2-sg.id}"]

  key_name = aws_key_pair.key-pair.id
  tags = {
    Name = "Wordpress.web"
  }

  depends_on = [aws_db_instance.wordpress-db]
}

resource "aws_route53_zone" "main" {
  name = "coinmetro-dev.com"
}

resource "aws_route53_record" "dev-ns" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "blog-test.coinmetro-dev.com"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.eip.public_ip]
}

resource "aws_key_pair" "key-pair" {
  key_name   = "key-pair"
  public_key = file(var.PUBLIC_KEY_PATH)
}

# creating Elastic IP for EC2
resource "aws_eip" "eip" {
  instance = aws_instance.wordpress-ec2.id
}

output "IP" {
  value = aws_eip.eip.public_ip
}
output "RDS-Endpoint" {
  value = aws_db_instance.wordpress-db.endpoint
}

output "INFO" {
  value = "AWS Resources and Wordpress has been provisioned. Go to http://${aws_eip.eip.public_ip}"
}

# Save Rendered playbook content to local file
resource "local_file" "playbook-rendered-file" {
  content  = data.template_file.playbook.rendered
  filename = "./playbook-rendered.yml"
}

resource "null_resource" "wordpress-install" {
  connection {
    type = "ssh"
    user = "ec2-user"
    host  = aws_eip.eip.public_ip
    agent = true
  }

  # Run script to update python on remote client
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y", 
      "sudo yum install python3 -y", 
      "echo Done!"
    ]
  }

  # Play ansible playbook
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ec2-user -i '${aws_eip.eip.public_ip},' playbook-rendered.yml"
    # command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ec2-user -i '${aws_eip.eip.public_ip},' --private-key ${var.PRIV_KEY_PATH}  playbook-rendered.yml"
  }
}
