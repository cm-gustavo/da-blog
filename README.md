# da-blog

New Coinmetro blog infrastructure. Provided through a Terraform project, it consists of an Ec2 instance inside a VPC, with MySQL database and Wordpress installed and configured via Ansible playbook.

### Cheat sheet:
terraform init
terraform apply
terraform destroy

### To-dos:
* DNS configuration
* Proper database credentials and configuration
* Limit access to control panel to VPN
* Create Github Actions to automate deploy
* Improve [documentation](https://coin-metro.atlassian.net/wiki/spaces/SOFT/pages/217481237/New+Blog+Infrastructure)
