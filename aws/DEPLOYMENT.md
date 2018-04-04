# Deploying to docker swarm on AWS

## Setting up the swarm infrastructure 
cloudformation/docker_swarm.parameters.json
aws cloudformation create-stack --stack-name dockerswarm \
    --capabilities CAPABILITY_IAM \
    --template-url https://editions-us-east-1.s3.amazonaws.com/aws/stable/Docker.tmpl \
    --parameters file://aws/cloudformation/docker_swarm.parameters.json

## get swarm manager ips and setup ssh configs for them
    aws ec2 describe-instances --filter Name=tag:swarm-node-type,Values=manager | jq -r '.Reservations[].Instances[].PublicIpAddress' | xargs
    <ip1> <ip2> <ip3>

### add the following configs to ~/.ssh/config  
    Host dockermanager1
        Hostname <ip1>
        User docker
        ForwardAgent yes 
    Host dockermanager2
        Hostname <ip2>
        User docker
        ForwardAgent yes 
    Host dockermanager3
        Hostname <ip3>
        User docker
        ForwardAgent yes 


## build for aws deployment
This step fills in environment variables in the docker-compose file which we then use

    env $(cat environments/production | grep -v '^#' | xargs) docker-compose config docker-compose config > docker-compose-deploy.yml
    env $(cat environments/production | grep -v '^#' | xargs) docker-compose build 

# push the built files to the repository
files=(`docker-compose config | grep image | tr -d ' ' | cut -d ':' -f2 | xargs`) 
for f in $files; do docker push $f; done


# deploy the stack
  create an ssh tunnel to a manager. 
  ssh -i ~/.ssh/id_rsa.pub -NL localhost:2374:/var/run/docker.sock docker@dockermanager2 & 
env $(cat environments/production | grep -v '^#' | xargs) docker -H localhost:2374 stack deploy -c docker-compose-aws.yml drfbp






Create a tunnel to a manager host
    docker -H localhost:2374 stack deploy -c docker-compose-deploy.yml drfbp  
