# Deploying Ed-Fi ODS to ECS with terraform scripts

This documentation will show you how to deploy an Ed-Fi ODS environment in Shared Instance mode (ODS/WebAPI, AdminApp, Swagger Documentation site) in Amazon Elastic Container Service.

### Requirements:

1.  Install [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

2.  Configure your [AWS credentials](https://techdocs.ed-fi.org/pages/viewpage.action?pageId=174785508) in your console.

3.  Visual Studio Code, or any Text Editor, of your choice. In this documentation, we use Visual Studio Code and also installed the HashiCorp Terraform extension (this is not required but it will help visualize the content of the files).

4.  Docker Desktop installed and running.

5.  Clone the [Ed-Fi-ECS-Starter](https://github.com/Ed-Fi-Exchange-OSS/Ed-Fi-ECS-Starter) repository.

6.  Valid AWS wildcard [certificate](https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-request-public.html). For instance, \*.yourdomain.com. This needs to be a wildcard certificate because it will be used for multiple web applications. For instance: api-dev.yourdomain.com, adminapp-dev.yourdomain.com, and swagger-dev.yourdomain.com.

7.  Valid AWS hosted zone identifier.


Open Visual Studio Code (VSC), and navigate to the folder "terraform" of the downloaded project **Ed-Fi-ECS-Starter.**


Open a New Terminal in the "terraform" folder and execute the following command (see below), this command will prepare your working directory for the commands we will execute later on.

```console
terraform init
```


Then modify the file "variables.tf" according to your needs.


Please find below all the variables and their description.

**Variables**

**aws\_region**: The geographic [area](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RegionsAndAvailabilityZones.html) for the installation.

**aws\_maximun\_availability\_zones**:Total geographic areas where for the installation, by default 2.

**project\_name**: The name of your project. This will be used as a prefix to name some resources

**rds\_password**: Password for AWS RDS database instance.

**rds\_db\_username**: Username for AWS RDS database instance.

**db\_instance\_type**: The database instance type determines the capacity(CPU and memory) of your database instance. For instance: "db.t3.small", see list of instance types [here](https://aws.amazon.com/rds/instance-types/)

**db\_instance\_storage**: The amount of allocated storage in GB.

**db\_instance\_skip\_final\_snapshot**: Determines whether a final DB snapshot is created before the DB instance is deleted, true to omit the snapshot

**postgres\_password:** The password for the user postgres.

**cidr**: The IP address range of your AWS VPC.

**docker\_images**: To store a list of Repository names, docker file paths, and log groups that will be used when the docker images are created

**image\_tag**: The version of the docker image to identify it as unique.

**aws\_profile**: To get the credentials from the configured profile in order to run a command against the AWS cloud.

**cpu**: The limit for CPU resources. 1024 CPU units are the equivalent of 1 vCPU, 2048 CPU units is equal to 2 vCPU

**memory**: The limit of memory (in MiB) to present to the task, This value has to be compatible with the CPU.

**app\_environment**: stage example: development or dev, production or prod.

**certificate\_arn**: It is assumed that a certificate exists(in the same **aws\_region**), if not, you need to create a certificate: AWS Certificate Manager >> Certificates >> Request certificate

**ssl\_policy**: The predefined security policies for Load Balancers.

**hosted\_zone\_id**: To route internet traffic for your domain or to route traffic within your VPCs when you use Route 53.  It is assumed that a certHosted zone exists, if not, create a Hosted zone:  Route 53 >> Hosted zones >> Create hosted zone.

**favorite\_browser**: The browser common you use to open web applications.

**domain**: The name of your domain will be associated with the IP address of the server hosting your applications.

**encryption\_key**: 
 **white\_ips**: The list of these IPs will be allowed access to the Admin App, example 177.x.x.x/32,188.x.x.x/32

After finishing the variable configuration, run the terraform commands in the next order.



Now that terraform has been initialized and the variables are updated with values of your environment. We can run the following commands:
\***Note**: to execute the commands, you should navigate to the location where the files were placed, example: ..\\Ed-Fi-ECS-Starter\\terraform

1.  Validate configuration values.


    ```console
    terraform validate
    ```

2.  Show changes required by the current configuration.

    ```console
    terraform plan
    ```

3.  Create or update infrastructure. Please note this command passes the extra option to approve the creation of resources.

    ```console
    terraform apply -auto-approve
    ```

    To deploy the resources, you need to you execute the "apply" command. This will execute the actions proposed in a Terraform plan. Please note that this process may take several minutes to complete.

    If everything executed successfully, you will be able to access your Ed-FI ODS/API, AdminApp, and Swagger applications.


Once you have your environment up and running, If you want to remove all the created infrastructure, you just need to run the following command:


```console
terraform destroy
```


### Known Issues:

After the script finishes deploying the environment, the AdminApp displays the error message "503 Service Temporarily Unavailable". This occurs because the AdminApp requires a little more time to run scripts and become fully operational. Simply wait a few minutes, then reload the page, and the AdminApp should be up and running.


### Conceptual diagram:

![](/docs/assets/images/ecs-conceptual-diagram.png)
