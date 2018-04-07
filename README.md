docker-flask-boilerplate [![Build Status](https://travis-ci.org/kukui/docker-boilerplate.svg?branch=master)](https://travis-ci.org/kukui/docker-boilerplate)
========================
A Docker based flask restful api boilerplate for quick starting projects.
AWS Cloudformation templates for deploying to a swarm on AWS are included
as well.

## Prerequisites

### A Unix or Linux environment

Sorry I don't know anything about windows. If someone wants to help me with that
I would be very grateful.

### [Python3](https://www.python.org/downloads/)
This may work on python2 but I haven't tried. 
### [Bash](https://www.gnu.org/software/bash/)
There are several small bash scripts used in the project.
### [Gnu Make](https://www.gnu.org/software/make/)
This project uses make for development and deployment.
### [Docker and Docker Compose](https://docs.docker.com/engine/installation/#supported-platforms)
This project uses and Docker and Docker Compose to run services locally and
provides the option of deployment to a docker swarm on aws. 
### [DNSMasq(optional)](http://www.thekelleys.org.uk/dnsmasq/doc.html)
DNSMasq provides local DNS. So you don't have to constantly edit your host file.
It makes setting up new local development domains automatically resolve to localhost.

### [Docker Installation](https://docs.docker.com/install/)

Docker Installation depends on your platform. The official documentation can be found [here](https://docs.docker.com/install/)
This boilerplate has been tested with the following versions on Mac OS X.
1. Docker Engine: 17.12.0-ce 
2. Docker Compose: 1.18.0
3. Docker Machine: 0.13.0


##Setup

### DNS

You can either edit your hosts file and add the domain name or setup local dns
as follows to list for all domains in your chosen TLD. I like to use $(whoami).
If your username happens to also be a TLD use something else. 

```bash
brew install dnsmasq
mkdir -pv $(brew --prefix)/etc
sudo cp -v $(brew --prefix dnsmasq)/homebrew.mxcl.dnsmasq.plist /Library/LaunchDaemons
sudo launchctl load -w /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist
sudo mkdir -pv /etc/resolver

echo "address=/.$(whoami)/127.0.0.1" | sudo tee -a $(brew --prefix)/etc/dnsmasq.conf
echo "nameserver 127.0.0.1" | sudo tee /etc/resolver/$(whoami)

sleep 1 && open "http://some.domain.$(whoami):9021" &
python3 -m http.server 9021
```

If the page opens in your default browser your all set. DNS is working.


### Get the source code

```bash
git clone https://github.com/kukui/docker-flask-boilerplate
```

### Setup your local environment

 - `TAG`: a tag to use for selecting images to run locally
 - `DOMAIN`: the domain name of the service provided
 - `SSL`: Whether we are running SSL or not (0 or 1)

Environment settings files are loaded from a file in the [environments](environments)
directory when building docker images and at runtime.  These files are not intended
for storing sensitive information like api keys and passwords. Those should go in [secrets](secrets).
Environment variables should not be stored in the repository.

The basic working environment setup for this boilerplate is

```bash
cat > environments/local << EOF
TAG=latest
DOMAIN=flaskapp.kai
SSL=1
EOF
```

### Secrets

All sensitive keys and passwords should be stored in secrets/`SECRET`
**Do not** commit changes to these folders to your repository.
When deployed to a swarm using the `Makefile`. this directory is processed
and all secrets therein are added using [docker secret create](https://docs.docker.com/engine/swarm/secrets/#read-more-about-docker-secret-commands)


## Passing environment variables to docker

Why don't we use .env or the new docker-compose format for environment variables?
docker stack deploy does not read .env files and it does not support the less verbose 
syntax for accessing environment variables in a compose or stack file.

https://github.com/moby/moby/issues/29133
https://github.com/moby/moby/issues/30251

Our solution is to pass environment variables to build and deploy commands
in the Makefile with the following which does work consistently.

```bash
    env $(cat environments/local | grep -v '^#' | xargs) make <command>
```
## SSL
### Generate an ssl cert for local development

This is a self signed certificate for local development. Why bother?  Because
minimizing the differences between your production and development environments
is the root of all happiness.

```bash
ENVIRONMENT=local make dev-cert
```

### Accept the certificate in your browser.

The first time you visit the URL for the application you will need to accept the
self-signed certificate unless you add it as a trusted cert first. 

On Mac OSX you can add it as a trusted cert using this command.

```bash
sudo security add-trusted-cert -d -r trustRoot -k $HOME/Library/Keychains/login.keychain www/certs/`DOMAIN`.crt
```

## Building the system

```bash
    ENVIRONMENT=local make build
```

### Deploying the stack to a single node swarm locally
    ENVIRONMENT=local make swarmup 
    
### Running the stack using docker-compose
    ENVIRONMENT=local make dockerup 

##  AWS deployment

This step assumes you have an AWS account and that your shell is properly
configured with AWS credentials and an ssh key that has been added to AWS.

### Create the AWS [parameters file](aws/cloudformation/docker_swarm.parameters.json)

```bash

cat > aws/cloudformation/docker_swarm.parameters.json << EOF
[
{"ParameterKey": "ClusterSize", "ParameterValue": "5"},
{"ParameterKey": "EnableCloudStorEfs", "ParameterValue": "no"},
{"ParameterKey": "EnableCloudWatchLogs", "ParameterValue": "yes"},
{"ParameterKey": "EnableEbsOptimized", "ParameterValue": "no"},
{"ParameterKey": "EnableSystemPrune", "ParameterValue": "yes"},
{"ParameterKey": "EncryptEFS", "ParameterValue": "false"},
{"ParameterKey": "InstanceType", "ParameterValue": "t2.micro"},
{"ParameterKey": "KeyName", "ParameterValue": ""},
{"ParameterKey": "ManagerDiskSize", "ParameterValue": "20"},
{"ParameterKey": "ManagerDiskType", "ParameterValue": "standard"},
{"ParameterKey": "ManagerInstanceType", "ParameterValue": "t2.micro"},
{"ParameterKey": "ManagerSize", "ParameterValue": "3"},
{"ParameterKey": "WorkerDiskSize", "ParameterValue": "20"},
{"ParameterKey": "DBUSER", "ParameterValue": ""},
{"ParameterKey": "DBPASSWORD", "ParameterValue": ""},
{"ParameterKey": "DBNAME", "ParameterValue": ""},
{"ParameterKey": "DBCLASS", "ParameterValue": "db.t2.medium"},
{"ParameterKey": "DBALLOCATEDSTORAGE", "ParameterValue": "20"}
]
EOF
```

Edit and add your values for the KeyName, DBUSER, DBPASSWORD, and DBNAME


### Create the docker swarm stack on aws and an RDS instance
    
**WARNING**. This will cost money if you leave it running. Do some reading on AWS
and cloudformation if you're not familiar with them. This is a good starting point
but you'll certainly need to make adjustments to fit your needs.

```bash
aws cloudformation create-stack --stack-name dockerswarm \
 --capabilities CAPABILITY_IAM \
 --template-body file://aws/cloudformation/stack_with_rds.json \
 --parameters file://aws/cloudformation/docker_swarm.parameters.json \
 --disable-rollback
```

This step may take awhile. you can monitor the status with this command

```bash
aws cloudformation describe-stacks --stack-name dockerswarm | jq '.Stacks[].StackStatus'
```

#### Deploy to the AWS docker swarm
Add the database server endpoint to environments/production
    echo DB_HOST=$(aws/get-db-endpoint.sh dockerswarm) >> environments/production

Cut a release
1. Edit [RELEASE_NOTES](RELEASE_NOTES). Add a line in the format Version <Version Number> (YYYY-MM-DD)
1. Build the images from the current git branch on your machine.
2. Tag the images with: version number, commit hash, branch name, environment
3. Push the images to your container registry

```bash
    ENVIRONMENT=production make release
```

Deploy
Connect to a swarm manager over an ssh tunnel and deploy the most recent version 

```bash
    ENVIRONMENT=production make deploy
```
    
## License

All work in this repository is licensed under the MIT license. For details, see
the [LICENSE](LICENSE) file.



