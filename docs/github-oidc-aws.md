# GitHub Actions AWS Access With OIDC

Use GitHub OpenID Connect (OIDC) so GitHub Actions can assume an AWS IAM role without storing long-lived AWS access keys.

## 1. Create the GitHub OIDC provider

In AWS IAM, create an identity provider:

* Provider type: OpenID Connect
* Provider URL: `https://token.actions.githubusercontent.com`
* Audience: `sts.amazonaws.com`

## 2. Create an IAM role for this repository

Use a trust policy like this, replacing `123456789012` with your AWS account ID:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:Aymogul/ecs:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

For pull request plans, you can broaden the `sub` condition carefully:

```json
"token.actions.githubusercontent.com:sub": [
  "repo:Aymogul/ecs:ref:refs/heads/main",
  "repo:Aymogul/ecs:pull_request"
]
```

## 3. Attach permissions

For learning, start with permissions that cover the services this stack creates:

* VPC, subnet, route table, internet gateway, NAT gateway, and security group permissions
* Elastic Load Balancing v2 permissions
* ECS and Application Auto Scaling permissions
* IAM role creation and policy attachment permissions for the ECS task execution role
* CloudWatch Logs permissions

In a production setup, split CI into two roles:

* Plan role: read-only plus the minimum extra permissions Terraform needs to refresh state
* Apply role: write permissions, restricted to protected branches or GitHub environments

## 4. Add GitHub repository variables

In GitHub, go to Settings > Secrets and variables > Actions > Variables and add:

* `AWS_ROLE_TO_ASSUME`: `arn:aws:iam::123456789012:role/github-actions-terraform-ecs`
* `AWS_REGION`: `us-east-1`

Do not add `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` for this workflow unless you are doing a short-lived emergency fallback.
