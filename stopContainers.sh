#!/bin/bash

CONTAINER_IDS=$(docker ps -q)
if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
    echo "---- No containers available for deletion ----"
else
    docker stop $CONTAINER_IDS
fi