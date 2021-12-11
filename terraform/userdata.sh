#!/bin/bash


# pull webapp image
docker pull intensivus/webapp:v1.0.0

# run container with port mapping - host:container
docker run -d -p 80:80 --name webapp intensivus/webapp:v1.0.0