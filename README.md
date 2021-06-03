# URL Shorten

## Introduction 

This code demonstrates a basic algorithm for creating a shortened URL.    To demonstrate this it 
was done using Node.Js.   A scripting language is quicker to write this 
prototype.  

When approaching this problem there was two options that were evaluated
1. shorten a sub-domain and leverage the power of DNS globally.  
2. use URL path parameters

### Subdomain 

This seemed overkill for the task required, but would have meant URLs would be forwared using
global DNS infrastructure instead of application.  The down side to this approach
would have been time required to propagate DNS changes.   To manage this a * wildcard
could have been used in the DNS to use the application to resolve short Ids 
until DNS resolves globally.   Additionally a service like AWS Route 53 had limit of 10,000 subdomains per zone

### URL path parameters

This is the more common approach to solve this problem, typically with a small url and Id as a path 
parameter.  This demo went with this approach


## Architecture decisions

A couple of considerations were taken in relation to the architecture design

1. Once a shortened URL is clicked the redirect needs to be fast
2. Available of the re-direct service is important as users do not know the actual url and rely on it working
3. Latency of the creation a shortened URL is not as important as latency on click of the shortened URL

### Latency - Redis

Redis was choosen to ensure low latency of the shortened URL Id to the URL that will be re-directed to.
Although its slightly slower to create a new shortened URL, we gain the advantage 
in reading the data. 

### Availability - Docker on ECK

The application was deployed to amazon with initial 2 containers behind the load balancer.  This
could have been extended with availability and a redis cluster but was felt this was overkill
for the problem being solved. 

### Shorten Id

There is a number of options for shorten URL including hashing for lookups or encoding. These 
can create conflicts.  By using redis with a 10 char id meant the id could be always be unique.

## Local Development

To support local development a docker cant be started up with redis.
To start the container 

``` 
cd dev-env && docker-compose up
 ```

## Starting the Application

To run the application you need to have both node and npm installed.  

```bash
npm install
export REDIS_HOST=localhost
export REDIS_PORT=6379
npm start
```

## Testing

3 acceptance tests were written to
1. create new shortened URL
2. verify shortened URL created works
3. checks if invalid shortened URL passed in 404 is returned

With more time unit tests and more acceptance tests would have been added to include more URL testing.

To run the tests

```bash
npm test
```

## Deploy

The application is deployed to AWS using terraform.  You will need to have terraform and aws-cli installed  to run
 the deployment 

On AWS the terraform script

1. Sets up required resources - cluster, repository vpc, security group, subnet
2. Creating redis on elastic cache
3. Create task definition on ECS
4. Assign IAM policy
5. Setup load balancer and security groups around it

To run the deployment you need to perform the following steps:

```
cd build
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
terraform apply
```

This will create the infrastructure and you will need take the endpoint from the Elastic Cache service to set as an environment variable 
for the application to start __REDIS_HOST__

To deploy the application you will need to run

```
cd build
./deploy.sh
```

This will deploy the container to the repository  as the latest and to deploy the container on AWS run

```
cd build
terraform apply
```

I did have one issue with terraform where it gave an error recognising security group that had been created, which due to time constraints I was not able to resolve 
 
