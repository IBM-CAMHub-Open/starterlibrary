variable "key_name" {}
variable "public_ssh_key" {}

resource "aws_key_pair" "orpheus_public_key" {
    key_name = "${var.key_name}"
    public_key = "${var.public_ssh_key}"
}

output "key_pair_id" {
  value = "${aws_key_pair.orpheus_public_key.id}"
}
