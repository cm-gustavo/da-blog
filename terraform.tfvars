database_name           = "wordpress_db"          // database name
database_user           = "wordpress_user"        // database username
database_password       = "wordpress_password"    // database password
shared_credentials_file = "~/.aws"                // Access key and Secret key file location
PUBLIC_KEY_PATH         = "~/.ssh/id_rsa.pub"
PRIV_KEY_PATH           = "~/.ssh/id_rsa"
instance_type           = "t2.micro"
instance_class          = "db.t2.micro"

// region                  = "us-east-1"
// ami                     = "ami-0a8b4cd432b1c3063" // linux 2 ami
// AZ1                     = "us-east-1a"            // avaibility zones
// AZ2                     = "us-east-1b"
// AZ3                     = "us-east-1c"

region                  = "eu-west-2"
ami                     = "ami-0dd555eb7eb3b7c82" // linux 2 ami
AZ1                     = "eu-west-2a"            // avaibility zones
AZ2                     = "eu-west-2b"
AZ3                     = "eu-west-2c"
