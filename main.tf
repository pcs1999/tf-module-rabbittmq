// creating the aws_iam_role
resource "aws_iam_role" "aws_role" {
  name = "${var.env}-${var.component}-role"


  assume_role_policy = jsonencode({
    Version          = "2012-10-17"
    Statement        = [
      {
        Action       = "sts:AssumeRole"
        Effect       = "Allow"
        Sid          = ""
        Principal    = {
          Service    = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = merge (local.common_tags, { Name = "${var.env}-${var.component}-role" } )

}

resource "aws_iam_instance_profile" "para_instance_profile" {
  role = aws_iam_role.aws_role.name
  name = "${var.env}-${var.component}-role"
}

resource "aws_iam_policy" "aws_parameter_policy" {
  name        = "${var.env}-${var.component}-parameter_store_role"
  path        = "/"
  description = "${var.env}-${var.component}-parameter_store_role"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "VisualEditor0",
        "Effect": "Allow",
        "Action": [
          "ssm:GetParameterHistory",
          "ssm:GetParametersByPath",
          "ssm:GetParameters",
          "ssm:GetParameter"
        ],
        "Resource" : [
          "arn:aws:ssm:us-east-1:261454514620:parameter/${var.env}.${var.component}*",
          "arn:aws:ssm:us-east-1:261454514620:parameter/grafana*",
          "arn:aws:ssm:us-east-1:261454514620:parameter/${var.env}-SSH*"


        ]
      },
      {
        "Sid": "VisualEditor1",
        "Effect": "Allow",
        "Action": "ssm:DescribeParameters",
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "policy-attach" {
  role       = aws_iam_role.aws_role.name
  policy_arn = aws_iam_policy.aws_parameter_policy.arn
}


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




#resource "aws_spot_instance_request" "rabbitmq_instance" {
#  ami = data.aws_ami.ami_id.image_id
#  instance_type = "t3.small"
#  subnet_id = var.subnet_ids[0]
#  wait_for_fulfillment = true
#  vpc_security_group_ids = [aws_security_group.rabbitmq.id]
#  user_data = base64encode(templatefile("${path.module}/user_data.sh",{component="rabbitmq",env=var.env} ))
#  iam_instance_profile = aws_iam_instance_profile.para_instance_profile.name
#
#  tags = merge (local.common_tags, { Name = "${var.env}-rabbitmq_instance" } )
#
#}

resource "aws_instance" "rabbitmq_instance" {
  ami = data.aws_ami.ami_id.image_id
  instance_type = "t3.small"
  subnet_id = var.subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.rabbitmq.id]
  user_data = base64encode(templatefile("${path.module}/user_data.sh",{component="rabbitmq",env=var.env} ))
  iam_instance_profile = aws_iam_instance_profile.para_instance_profile.name

  tags = merge (local.common_tags, { Name = "${var.env}-${var.component}" } )

}

resource "aws_route53_record" "rabbitmq_DNS_record" {
  zone_id = "Z04623222IZKOJZ0BZ3PB"
  name    = "rabbitmq-${var.env}.chandupcs.online"
  type    = "A"
  ttl     = 30
  records = [aws_instance.rabbitmq_instance.private_ip]
}


#resource "aws_ssm_parameter" "rabbitmq_endpoint" {
#  name  = "${var.env}.rabbitmq.endpoint"
#  type  = "String"
#  value = replace(replace(aws_mq_broker.rabbitmq.instances.0.endpoints.0,"amqps://", ""), ":5671", "")
#}
