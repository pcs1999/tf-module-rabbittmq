
resource "aws_security_group" "rabbitmq" {
  name        = "${var.env}-rabbittmq_security_group"
  description = "${var.env}-rabbittmq_subnet_group"
  vpc_id      = var.vpc_id


  ingress {
    description      = "rabbitmq"
    from_port        = 5672
    to_port          = 5672
    protocol         = "tcp"
    cidr_blocks      = var.allow_cidr

  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = var.bastion_cidr

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge (local.common_tags, { Name = "${var.env}-rabbitmq_subnet_group" } )

}


// as our application code for rabbitmq  doesn't designed to deal with secured protocol of rabbitmq we are going with ec2 instance rather than the mq_broker

#resource "aws_mq_broker" "rabbitmq" {
#  broker_name        = "${var.env}-rabbittmq_mq_broker"
#  deployment_mode    = var.deployment_mode
#  engine_type        = var.engine_type
#  engine_version     = var.engine_version
#  host_instance_type = var.host_instance_type
#  security_groups    = [aws_security_group.rabbitmq.id]
#  subnet_ids = var.deployment_mode == "SINGLE_INSTANCE" ? [var.subnet_ids[0]] : var.subnet_ids
#
##  configuration {
##    id       = aws_mq_configuration.rabbitmq.id
##    revision = aws_mq_configuration.rabbitmq.latest_revision
##  }
#
#  encryption_options {
#    use_aws_owned_key = false
#    kms_key_id = data.aws_kms_key.key.arn
#  }
#
#  user {
#    username = data.aws_ssm_parameter.rabbitmq_ADMIN_USER.value
#    password = data.aws_ssm_parameter.rabbitmq_ADMIN_USER.value
#  }
#}




resource "aws_spot_instance_request" "rabbitmq_instance" {
  ami = data.aws_ami.centos8_ami.image_id
  instance_type = "t3.small"
  subnet_id = var.subnet_ids[0]
  wait_for_fulfillment = true
  vpc_security_group_ids = [aws_security_group.rabbitmq.id]
  user_data = base64encode(templatefile("${path.module}/user_data.sh",{component="rabbitmq",env=var.env} ))


  tags = merge (local.common_tags, { Name = "${var.env}-rabbitmq_instance" } )

}

resource "aws_route53_record" "rabbitmq_DNS_record" {
  zone_id = "Z09063921V1VGRMXUB88J"
  name    = "rabbitmq-${var.env}.chandupcs.online"
  type    = "A"
  ttl     = 300
  records = [aws_spot_instance_request.rabbitmq_instance.private_ip]
}


#resource "aws_ssm_parameter" "rabbitmq_endpoint" {
#  name  = "${var.env}.rabbitmq.endpoint"
#  type  = "String"
#  value = replace(replace(aws_mq_broker.rabbitmq.instances.0.endpoints.0,"amqps://", ""), ":5671", "")
#}
