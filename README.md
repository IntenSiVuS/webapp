# webapp

This code is used to set up infrastructure in AWS and to deploy the webapp in there.

#### Table of Contents
* [Description](#description)
* [Requirements](#requirements)
* [Usage](#usage)
* [Tools](#tools)
* [Development](#development)
  * [Testing](#testing)
  * [Code Organization](#code-organization)

## Description
The code in this repo is capable of: 
* Building a docker image with nginx and some website files inserted and push this to dockerhub. 
* Create the required infrastructure in AWS to run this dockerimage. It will create the following resources:
  * Autoscaling group with attached Launch configuration 
  * ALB Loadbalancer which passes traffic to the instances created by the ASG
  * Security Group to only allow traffic on port 80
#### About the nginx docker image
The webapp files are embedded in the docker image. This ensures the exact same version of the app is always deployed.
If you want to change it, change the files, if files are added , make sure they are part of the `COPY` command in the `Dockerfile`

#### About the AWS Resources
The Autoscaling Group is set up to have  a min of 1, max of 3 and a desired number of 2 instances running the docker image.
  
The userdata.sh contains the bash script to pull and run the docker image on the instances created by the ASG. On changing this file (for example when a new version of the webapp gets build), a instance refresh will be triggered which will do a rolling update creating and destroying  instances so that the new version will be running. 
## Requirements

To be able to easily deploy this, a few things are required. So either you will need to have these available locally,
or you would need a CICD environment which provides these:
* Docker
* Python3 with pip and pipenv
* GNU Make 
* Some environment variables to control certain things
  * `AWS_PROFILE` : The configured AWS profile to use. (by default uses the profile name "personal")

#### Testing the public endpoint

The public endpoint can be tested from anywhere by checking out the git repository and running the `make pytest` command from within the root dir of the repository

## Usage

To use this, either use the options available in the makefile individually, or if you want to make everything that you would normally have in a cicd pipeline, just run build.sh

Running the build.sh script does these things:
* format check the terraform code
* run terraform plan to plan the infrastructure to create 
* apply the terraform plan and create the infrastructure
* test if the site returns a 200 status code on the public loadbalancer url after succesful apply
## Tools
* [docker]
  * Docker, to build image within this image (dind)
* [pytest]
* [terraform]
  * [Terraform](https://www.terraform.io/docs/index.html), a popular infrastructure provisioning tool
  

## Development

### Testing

Testcases are writen in python and pytest specifically. 
Tests are in the `/tests` directory. See the `make pylint` and `make pytest` targets in the `Makefile` to see how tests are triggered

### Code Organization

* `resources` - A directory which contains the file(s) of the webapp/website to serve. With bigger apps it is better to have this in it's own repo.
* `terraform` - A directory which contains all the terraform files that will create the infrastrcuture we need to serve the webapp.
* `tests` - directory which contains the pytest tests and which will contain the test report
* `Makefile` - The file which has targets for all the steps needed to get the infra and app running.
* `Pipfile`, `pytest.ini` - To configure python and the virtual environment where the tests will be ran

### TODO / Improvements

* Currently the webapp is ran in a docker container on ec2 instances. If using free-tier resources is no requirement, then it is preferred to use ECS or EKS to run the container. Especially with EKS it would be easier to scale