#!/bin/bash

# Modify the security group 
CLUSTER_SECURITY_GROUP_ID=$(aws eks describe-cluster --name test-cluster --query 'cluster.resourcesVpcConfig.clusterSecurityGroupId' --output text)
PROTOCOL="all"
CIDR="0.0.0.0/0"
aws ec2 authorize-security-group-ingress --group-id $CLUSTER_SECURITY_GROUP_ID --protocol $PROTOCOL --cidr $CIDR

# Associate IAM OIDC provider to the cluster
eksctl utils associate-iam-oidc-provider --region=us-west-2 --cluster=test-cluster --approve

# IAM Service Account for the EKS Cluster
eksctl create iamserviceaccount \
  --region us-west-2 \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster test-cluster \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve \
  --role-only \
  --role-name AmazonEKS_EBS_CSI_DriverRole

# Install EBS CSI Driver on EKS
eksctl create addon --name aws-ebs-csi-driver --cluster test-cluster --service-account-role-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/AmazonEKS_EBS_CSI_DriverRole --force