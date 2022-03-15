database_name           = "wordpress_db"          // database name
database_user           = "wordpress_user"        // database username
database_password       = "wordpress_password"    // database password
shared_credentials_file = "~/.aws"                // Access key and Secret key file location
PUBLIC_KEY_PATH         = "./files/id_rsa.pub"
instance_type           = "t2.micro"
instance_class          = "db.t2.micro"

region                  = "eu-west-2"
ami                     = "ami-0dd555eb7eb3b7c82" // linux 2 ami
AZ1                     = "eu-west-2a"            // avaibility zones
AZ2                     = "eu-west-2b"
AZ3                     = "eu-west-2c"
