# Multi-Tier AWS Infrastructure with Terraform

A three-tier web application infrastructure on AWS (web, storage and database tiers), provisioned entirely with Terraform. Running `terraform apply` creates 18 resources: a custom VPC, an Nginx web server, a private MySQL database and a private S3 bucket.

## Architecture

```
                        Internet
                            |
                   [ Internet Gateway ]
                            |
 +--------------------- VPC 10.0.0.0/16 ---------------------+
 |                                                           |
 |  Public subnet 10.0.1.0/24 (us-east-1a)                   |
 |  +-----------------------------------------------------+  |
 |  |  EC2 (Ubuntu 22.04, t3.micro, Nginx)                |  |
 |  |  Security group: HTTP 80, SSH 22                    |  |
 |  |  IAM instance profile ---------------> S3 bucket    |  |
 |  +-------------------------+---------------------------+  |
 |                            | MySQL 3306 (web SG only)      |
 |  Private subnets (1a, 1b)  v                               |
 |  +-----------------------------------------------------+  |
 |  |  RDS MySQL 8.0 (db.t3.micro), not publicly reachable |  |
 |  +-----------------------------------------------------+  |
 +-----------------------------------------------------------+
```

## Resources Created

| Layer | Resources |
|---|---|
| Network | VPC, Internet Gateway, 1 public subnet, 2 private subnets, public route table and association |
| Security | Web security group (HTTP, SSH), database security group (MySQL from web tier only) |
| Compute | EC2 instance (latest Ubuntu 22.04 AMI, Nginx installed via `user_data`) |
| Database | RDS MySQL 8.0 instance, DB subnet group across two Availability Zones |
| Storage | S3 bucket with a random suffix, all public access blocked |
| Access | IAM role, inline S3 policy and instance profile attached to the EC2 instance |

## Project Structure

| File | Purpose |
|---|---|
| `provider.tf` | Terraform and AWS provider versions, default tags |
| `variables.tf` | Input variables (region, VPC CIDR, database password) |
| `vpc.tf` | VPC, subnets, internet gateway, route table |
| `security_groups.tf` | Web and database security groups |
| `s3_iam.tf` | S3 bucket, public access block, IAM role, policy, instance profile |
| `ec2.tf` | Web server EC2 instance and Ubuntu AMI lookup |
| `rds.tf` | RDS MySQL instance and DB subnet group |
| `outputs.tf` | Web server IP, RDS endpoint, S3 bucket name |

## Security Design

- The database sits in private subnets with `publicly_accessible = false`.
- The database security group accepts MySQL traffic only from the web server's security group, not from any IP range.
- The S3 bucket blocks all public access.
- The EC2 instance reaches S3 through an IAM role, so no access keys are stored on the server.
- The database password is marked `sensitive` and is supplied through a `.tfvars` file, which is excluded from Git.
- State files, `.tfvars` and `.pem` files are excluded through `.gitignore`.

## Known Limitations and Planned Improvements

This is a learning project, so some choices are intentionally simple:

- SSH (port 22) is open to `0.0.0.0/0`. In production this should be restricted to a known IP or replaced with AWS Systems Manager Session Manager.
- The IAM policy uses `Resource = "*"`. It should be scoped to the specific bucket.
- The web server has a single public instance. A production setup would add an Application Load Balancer and an Auto Scaling Group.
- The database is single-AZ. Multi-AZ can be enabled with `multi_az = true`.
- Terraform state is stored locally. A remote backend (S3 with DynamoDB locking) would suit team use.
- The EC2 key pair name is hardcoded in `ec2.tf` and could be turned into a variable.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5.0
- AWS CLI configured with credentials (`aws configure`)
- An existing EC2 key pair in `us-east-1`. Update `key_name` in `ec2.tf` to match its name.

## Usage

Create a `terraform.tfvars` file (ignored by Git) with the database password:

```hcl
db_password = "your-strong-password"
```

Then run:

```bash
terraform init      # download providers
terraform plan      # preview changes
terraform apply     # create the infrastructure (RDS takes about 5 minutes)
```

Terraform prints these outputs when it finishes:

- `web_public_ip`: public IP of the web server
- `rds_endpoint`: database endpoint (reachable only from inside the VPC)
- `s3_bucket_name`: name of the private S3 bucket

Open `http://<web_public_ip>` in a browser to see the Nginx page, which also shows the S3 bucket name.

## Connecting to the Server

```bash
ssh -i /path/to/your-key.pem ubuntu@<web_public_ip>
```

From the server, the database can be reached with the MySQL client that `user_data` installs:

```bash
mysql -h <rds_endpoint_host> -u dbadmin -p appdb
```

## Cleanup

Run this when you are done, because the EC2 instance and RDS database cost money while running:

```bash
terraform destroy
```

## What I Learned

- Designing a VPC with public and private subnets and routing through an internet gateway
- Restricting database access by referencing security groups instead of IP ranges
- Granting EC2 access to S3 through IAM roles and instance profiles
- Splitting Terraform code across files and using variables, outputs, data sources and the `random` provider
- Keeping secrets and state out of version control
