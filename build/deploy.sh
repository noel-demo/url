cd ..
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 557385570909.dkr.ecr.us-east-1.amazonaws.com
docker build -t demo-url-ecr-repo .
docker tag demo-url-ecr-repo:latest 557385570909.dkr.ecr.us-east-1.amazonaws.com/demo-url-ecr-repo:latest
docker push 557385570909.dkr.ecr.us-east-1.amazonaws.com/demo-url-ecr-repo:latest


