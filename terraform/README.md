# Kubernetes Cluster on AWS - GitOps Setup

## Repository Structure

```
k8s_cluster_aws/
├── .github/
│   └── workflows/
│       └── terraform.yml      # GitHub Actions workflow
├── .gitignore                  # Ignores sensitive files
├── provider.tf                 # Terraform provider & backend config
├── input_variables.tf          # Variable definitions
├── datasources.tf              # Data sources
├── main.tf                     # Main infrastructure
├── outputs.tf                  # Output values
├── terraform.tfvars.example    # Example variables (safe to commit)
└── README.md                   # This file
```

## Setup Instructions

### 1. Create S3 Bucket for Terraform State

```bash
# Create S3 bucket for state storage
aws s3api create-bucket \
  --bucket your-terraform-state-bucket \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket your-terraform-state-bucket \
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
  }'
```

### 2. Create DynamoDB Table for State Locking

```bash
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-south-1
```

### 3. Configure GitHub Repository Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

Add the following secrets:

| Secret Name | Description |
|-------------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Key |
| `AWS_REGION` | AWS Region (e.g., `ap-south-1`) |
| `ADMIN_PASSWORD` | Password for VM admin user |
| `TF_STATE_BUCKET` | S3 bucket name for Terraform state |
| `TF_LOCK_TABLE` | DynamoDB table name for state locking |

### 4. Push Code to GitHub

```bash
# Initialize git (if not already)
cd k8s_cluster_aws
git init

# Add remote
git remote add origin https://github.com/your-username/your-repo.git

# Commit and push
git add .
git commit -m "Initial commit - K8s cluster infrastructure"
git push -u origin main
```

## GitOps Workflow

### Automatic Triggers

| Event | Action |
|-------|--------|
| Push to `main` | Auto-applies changes |
| Pull Request | Plans and comments on PR |
| Manual dispatch | Choose: plan, apply, or destroy |

### Manual Trigger

1. Go to Actions tab in GitHub
2. Select "Terraform K8s Cluster" workflow
3. Click "Run workflow"
4. Choose action: `plan`, `apply`, or `destroy`

## Local Development

For local development without GitOps:

```powershell
# Copy example tfvars
Copy-Item terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
notepad terraform.tfvars

# Initialize (skip backend for local)
terraform init -backend=false

# Or use local backend override
terraform init -backend-config="path=terraform.tfstate"

# Plan and apply
terraform plan
terraform apply
```

### Using Environment Variables (Recommended)

Instead of storing secrets in tfvars, use environment variables:

```powershell
# PowerShell
$env:TF_VAR_aws_access_key = "your-access-key"
$env:TF_VAR_aws_secret_key = "your-secret-key"
$env:TF_VAR_admin_password = "your-password"

terraform plan
terraform apply
```

```bash
# Bash/Linux
export TF_VAR_aws_access_key="your-access-key"
export TF_VAR_aws_secret_key="your-secret-key"
export TF_VAR_admin_password="your-password"

terraform plan
terraform apply
```

## Security Best Practices

1. **Never commit `terraform.tfvars`** - It's in `.gitignore`
2. **Use GitHub Secrets** for all sensitive values
3. **Enable S3 bucket versioning** for state recovery
4. **Enable S3 encryption** for state at rest
5. **Use DynamoDB locking** to prevent concurrent modifications
6. **Review PR plans** before merging to main
7. **Use branch protection** on main branch

## Outputs

After successful deployment, the workflow will output:
- VPC and subnet IDs
- EC2 instance public/private IPs
- SSH connection command
- Security group ID

## Troubleshooting

### State Lock Issues
```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID
```

### Backend Configuration Issues
```bash
# Reinitialize backend
terraform init -reconfigure
```

### View Current State
```bash
terraform state list
terraform state show aws_instance.k8s_nodes["k8s-cp1"]
```
