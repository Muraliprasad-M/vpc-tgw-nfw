# Backend initialization

Run:
```bash
cd vpc-it
./scripts/init_backend.sh --bucket my-tfstate-bucket --dynamodb my-tfstate-locks --region eu-west-2 --key net/vpc-it/terraform.tfstate
terraform init -backend-config=backend.hcl
```
