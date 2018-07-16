#!/usr/bin/bash

bash run.sh \
-c xxx_mysql \
-i catcuts/mysql:latest-alpine3.6 \
-w $(pwd) \
-d $(pwd)/data \
-p 3307