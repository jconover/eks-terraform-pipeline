#!/bin/bash
set -e

echo "🚀 Setting up EKS Infrastructure..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}❌ $1 is not installed${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ $1 is installed${NC}"
    fi
}

echo "Checking prerequisites..."
check_command aws
check_command terraform
check_command kubectl
check_command helm

# Configure AWS
echo -e "${YELLOW}Configuring AWS...${NC}"
aws sts get-caller-identity

# Create S3 backend
BUCKET_NAME="terraform-state-eks-pipeline"
REGION="us-west-2"

echo -e "${YELLOW}Creating S3 backend bucket...${NC}"
aws s3api create-bucket \
    --bucket $BUCKET_NAME \
    --region $REGION \
    --create-bucket-configuration LocationConstraint=$REGION 2>/dev/null || echo "Bucket already exists"

aws s3api put-bucket-versioning \
    --bucket $BUCKET_NAME \
    --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
    --bucket $BUCKET_NAME \
    --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'

# Create DynamoDB table for state locking
echo -e "${YELLOW}Creating DynamoDB table for state locking...${NC}"
aws dynamodb create-table \
    --table-name terraform-state-lock \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region $REGION 2>/dev/null || echo "Table already exists"

# Initialize Terraform
echo -e "${YELLOW}Initializing Terraform...${NC}"
cd terraform/environments/dev
terraform init

echo -e "${GREEN}✨ Setup complete! You can now run 'terraform plan' to review the infrastructure.${NC}"