data "aws_ssm_parameter" "rabbitmq_ADMIN_USER" {
  name = "${var.env}.rabbitmq.DB_ADMIN_USER"
}

data "aws_ssm_parameter" "rabbitmq_ADMIN_PASS" {
  name = "${var.env}.rabbitmq.DB_ADMIN_PASS"
}
data "aws_kms_key" "key" {
  key_id = "alias/roboshop"
}


data "aws_ami" "ami_id" {
  most_recent      = true
  name_regex       = "pre-installed-ansible"
  owners           = ["261454514620"]

}