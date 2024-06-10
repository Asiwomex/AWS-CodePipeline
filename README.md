# Deploying a Django todo app onto an EC2 using CodeCommit, CodeBuild, CodeDeploy and CodePipeline

In this work, a django todo app will be commited to CodeCommit, built into an image using CodeBuild and saved in a container, ECR. This will then be deployed onto an instance using CodeDeploy with CodePipeline being used for the CI/CD process. The buildspec.yml, appspec.yml and scripts are provided in the repo.
## The following Services will be used

1. AWS Codecommit - a service for hosting repositories, take it as Github
2. AWS Codebuild - to automate the building of the image
3. AWS Codedeploy - to automate application deployments to EC2
4. AWS Codepipeline - for the CI/CD automation process
5. AWS ECR - as the container registry for your image or artifacts
6. EC2 - a virtual machine 
7. AWS IAM - to set up policies for the above mentioned services
8. S3 bucket - to store your artifacts


## 1. CodeCommit
First  navigate to Codecommit and create a repo
- clone the repo to your local machine using the HTTPs URL and copy your files into it
	- if it's your first time, you will need to authenticate with AWS Codecommit
	- in your IAM console, got to the security credential of your username
	- Scroll to “HTTPS Git credential for AWS codeCommit” and click on “generate credentials”. Once its created you can copy your username and password to authenticate Codecommit
- have a buildspec.yml and appspec.ymls file in it
- commit, add and push your files to your AWS repo
### Buildspec.yml
1. In your Django application's root directory, create a new file named buildspec.yml.
2. Open the buildspec.yml file in a text editor and add the following content and save:

```
version: 0.2

env:

  variables:

    AWS_DEFAULT_REGION: "us-east-2" # Adjust to your region

    AWS_ACCOUNT_ID: "001526952227"  # Adjust to your account ID

    IMAGE_REPO_NAME: "test-repo-private"   # Adjust to your repository name

    IMAGE_TAG: "latest"             # Adjust to your image tag

  

phases:

  pre_build:

    commands:

      - echo Logging in to Amazon ECR...

      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com

  build:

    commands:

      - echo Build started on `date`

      - echo Building the Docker image...

      - docker build -t $IMAGE_REPO_NAME:$IMAGE_TAG .

      - docker tag $IMAGE_REPO_NAME:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG

  post_build:

    commands:

      - echo Build completed on `date`

      - echo Pushing the Docker image...

      - docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG

artifacts:

  files:

    - appspec.yml

    - scripts/*
```
3. Replace $IMAGE_REPO_NAME, $IMAGE_TAG, $AWS_ACCOUNT_ID, and $AWS_DEFAULT_REGION with the appropriate values for your Django application and AWS environment.
4. Modify the install, pre_build, build, and post_build commands as needed for your specific Django application setup and requirements.
5. Save the buildspec.yml file and commit the changes to your CodeCommit repository.  Before setting up your code pipe line , you can go to codebuild to build your project to see whether your buildspec file is okay. Once your build is successful, you can proceed to setup CodePipeline to automate the whole process


### Appspec.yml
1. In your Django application's root directory, create a new file named appspec.yml.
2. Open the appspec.yml file in a text editor and add the following contents and save:
```
version: 0.0

os: linux

files:

  - source: /

    destination: /home/ec2-user/app

hooks:

  AfterInstall:

    - location: scripts/deploy.sh

      timeout: 300

      runas: ec2-user
```


### Scripts (deploy.sh)
Create a folder in your root directory, labeled "scripts" and create deploy.sh in it and paste the following and save in the deploy.sh
```
#!/bin/bash

# Define variables from environment
AWS_DEFAULT_REGION="us-east-2"
AWS_ACCOUNT_ID="001526952227"
IMAGE_REPO_NAME="test-repo-private"
IMAGE_TAG="latest"
CONTAINER_NAME="my-app"

IMAGE_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${IMAGE_REPO_NAME}:${IMAGE_TAG}"

  
# Log in to ECR

aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com
 

# Pull the latest image
docker pull $IMAGE_URI
 
# Stop and remove the old container if it exists

if [ "$(docker ps -a -q -f name=$CONTAINER_NAME)" ]; then

  docker stop $CONTAINER_NAME

  docker rm $CONTAINER_NAME

fi 

# Run the new container

docker run -d --name $CONTAINER_NAME -p 8000:8000 $IMAGE_URI
```

Save all, Commit and Push

## 2. Create an ECR and take note of your URI

## 3. Create an S3 bucket and note the bucket name

## 4. Create IAM role permissions for the following, 

1. **for CodeBuild (select code build since you're doing it for code build)**
	- Amazonec2containerregistry full access
	- codebuild admin access
	- codecommitfullaccess
	- s3fullaccess to upload the artifact
	- create role
2. **for EC2, give it**
	- CodeDeployFullAccess
	- AmazonEC2ContainerRegistryReadOnly
	- AmazonS3ReadOnly 
	- EC2FullAccess
3. **For CodeDeploy,**
	- CodeDeploy
	- EC2FullAccess
	- EC2ContainerRegistryReadOnly
	- CodeBuildFullAccess
4. For CodePipeline
	1. CodeCommitFullAccess
	2. CodeBuildFullAccess
	3. CodeDeployFullAccess
	4. EC2ContainerRegistryFullAccess
	5. EC2FullAccess
## 5. Codebuild
**Create your codebuild project**
	1. Click on "Create build project" to start and name your project
	2. Under SOURCE, choose AWS CodeCommit
	3. Under ENVIRONMENT, select the appropriate operating system and runtime for your application (eg. Amazon Linux, Standard)
	4. Enable the "Privileged" option to allow your build to run Docker commands.
	5. always use latest version of "image"
	6. add the service role (Role ARN)
	7. under "Buildspec", choose "Use buildspec "
	8. Under "Artifacts," choose the appropriate artifact type and location for storing the build output (e.g., "Amazon S3" ). choose s3 and select the s3  bucket to store your artifacts.
	9. Under "Logs," choose the appropriate CloudWatch log group for storing your build logs. Or you can leave the default
	10. Click "Continue" to proceed to the next step.
	11. Choose the existing role with the necessary permissions for CodeBuild to access AWS services like CodeCommit, ECR, and CloudWatch Logs
	12. click build project to build your project
	13. got to settings and edit the environments under edit project, enter the AWS_ACCOUNT_ID, AWS_DEFAULT_REGION, IMAGE_REPO_NAME, IMAGE_TAG,
	14. start build

## 6. EC2
Set up an EC2 Instance
	1. Open the Amazon EC2 console by navigating to the EC2 service in the AWS Management Console.
	2. Click on "Launch instance" and choose an Amazon Machine Image (AMI) and instance type suitable for your Django application (e.g., Amazon Linux 2 AMI and t2.micro instance type).
	3. Configure the instance details as needed, such as the VPC, subnet, and security group settings.
	4. Under "Configure Instance Details," expand the "Advanced Details" section and paste the following script in the "User data" field:
```
#!/bin/bash

# Update the package list and install necessary packages

sudo yum update -y

sudo yum install -y ruby wget

# Install Docker

sudo yum install docker -y

sudo usermod -aG docker ec2-user

sudo service docker start

# Enable Docker to start on boot

sudo systemctl enable docker

# Install AWS CodeDeploy Agent

cd /home/ec2-user

wget https://aws-codedeploy-us-east-2.s3.us-east-2.amazonaws.com/latest/install

chmod +x ./install

sudo ./install auto

# Start the CodeDeploy agent

sudo service codedeploy-agent start

# Enable CodeDeploy agent to start on boot

sudo systemctl enable codedeploy-agent

# Print versions to verify installation

docker --version

sudo yum info codedeploy-agent

sudo systemctl status codedeploy-agent
```

 5. Launch instance and not the Public IP or DNS Name for later use
 6. SSH into the server and use `docker --versioin` to check for the version of docker installed
 7. To check if Code Agent is installed successfully, use `sudo systemctl status codedeploy-agent`
 8. If the installation was not successful, you can copy the codes and install them in your terminal
 9. Navigate to the AWS Management Console, EC2, find and select your instance
 10. Select "Actions" --> "Security" --> "Modify IAM role"
 11. In the IAM role drop down, select the one you created and attach it to the instance and click "Update IAM role"
 12. Reboot instance to take effect
 13. Configure inbound rules to allow traffic for port 8000


## 7. CodeDeploy

1.    Open the AWS CodeDeploy console by navigating to the CodeDeploy service in the AWS Management Console.
2.    Click on "Create application" and enter a unique name for your application (e.g., "django-app-deployment").
3.    Click "Compute platform" and select "EC2/On-premises."
4.    Click "Create application" to create the new CodeDeploy application.
5.    After the application is created, click on the application name to open its details page.
6.    Click on "Create deployment group" and enter a unique name for the deployment group (e.g., "django-app-deployment-group").
7.    Under "Service role," select the IAM role you created (e.g., "django-app-codedeploy-role").
8.   Under "Environment configuration", select the Amazon EC2 instance you want to deploy your Django application to.
9.    Under "Deployment settings," choose the appropriate deployment configuration for your application (e.g., "CodeDeployDefault.OneAtATime" for a single instance deployment).
10. Configure any additional deployment settings as needed, such as load balancing or blue/green deployment options.  
uncheck the Loadbalancing since we are not using a loadbalancer
11. Click "Create deployment group" to create the new deployment group.

## 8. AWS CodePipeline

1. Open the AWS CodePipeline console by navigating to the CodePipeline service in the AWS Management Console
2. Click on "Create pipeline" and enter a unique name for your pipeline (e.g., "django-app-pipeline").
3. Under "Source provider," select "AWS CodeCommit" and choose the repository you created in Part 1 (e.g., "django-app-repo").
4. Under "Build provider," select "AWS CodeBuild" and choose the build project you created in Part 3 (e.g., "django-app-build").
5. Under "Deploy provider," select "AWS CodeDeploy" and choose the application and deployment group you created in Part 6 (e.g., "django-app-deployment" and "django-app-deployment-group").
6. Configure any additional settings for your pipeline, such as artifact stores or input/output artifacts.
7. Click "Next" to proceed to the "Review" step.
8. Create a new IAM service role or choose an existing role with the necessary permissions for CodePipeline to access other AWS services like CodeCommit, CodeBuild, CodeDeploy, and ECR.
9. Attach the IAM role you created for the CodePipeline to the Pipeline you are creating
10. Review your pipeline settings and click "Create pipeline" to create the new CodePipeline.

## 9. Testing and Monitoring
1. After completing the previous steps, commit and push any changes to your CodeCommit repository to trigger the CodePipeline execution.
2. Open the AWS CodePipeline console and monitor the pipeline execution status.
3. If the pipeline execution is successful, your Django application should be deployed to the EC2 instance you set up in Part 4.
4. Verify the successful deployment by accessing your Django application through the EC2 instance's public IP address or DNS name.
5. 