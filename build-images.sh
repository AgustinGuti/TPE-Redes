#!/bin/bash

# Build user service
cd user-service
docker build -t user-service-img:latest .
cd ..

# Build product service v1
cd product-service
docker build -t product-service-img:latest .
cd ..

# Build product service v2
# cd product-service-2
# docker build -t product-service-img-v2:latest .
# cd ..

# Build sales service
cd sales-service
docker build -t sales-service-img:latest .
cd .. 