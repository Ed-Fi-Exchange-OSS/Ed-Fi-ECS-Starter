# Ed-Fi ECS Starter IAM policies
These are the policies required to deploy the Ed-Fi ECS Starter on your AWS account:

```
application-autoscaling:*
cloudformation:*
ec2:AuthorizeSecurityGroupIngress
ec2:CreateSecurityGroup
ec2:CreateTags
ec2:DeleteSecurityGroup
ec2:DescribeRouteTables
ec2:DescribeSecurityGroups
ec2:DescribeSubnets
ec2:DescribeVpcs
ec2:RevokeSecurityGroupIngress
ecs:CreateCluster
ecs:CreateService
ecs:DeleteCluster
ecs:DeleteService
ecs:DeregisterTaskDefinition
ecs:DescribeClusters
ecs:DescribeServices
ecs:DescribeTasks
ecs:ListAccountSettings
ecs:ListTasks
ecs:RegisterTaskDefinition
ecs:UpdateService
elasticloadbalancing:*
iam:AttachRolePolicy
iam:CreateRole
iam:DeleteRole
iam:DetachRolePolicy
iam:PassRole
logs:CreateLogGroup
logs:DeleteLogGroup
logs:DescribeLogGroups
logs:FilterLogEvents
route53:CreateHostedZone
route53:DeleteHostedZone
route53:GetHealthCheck
route53:GetHostedZone
route53:ListHostedZonesByName
servicediscovery:*
```