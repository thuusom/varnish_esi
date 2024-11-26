#!/bin/bash

docker stop nginx-server
docker container rm nginx-server
docker run --name nginx-server \
  -p 9080:80 \
  -v $(pwd)/nginx/html:/usr/share/nginx/html:ro \
  -v $(pwd)/nginx/default.conf:/etc/nginx/conf.d/default.conf:ro \
  -d nginx:latest
