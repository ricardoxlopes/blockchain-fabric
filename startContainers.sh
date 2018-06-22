#!/bin/bash

CONTAINER_IDS=$(docker ps -a)
if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
    echo "---- No containers available for deletion ----"
else
    docker start $CONTAINER_IDS
fi