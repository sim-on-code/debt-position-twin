#!/bin/bash

# sh ./run_docker.sh <local|dev|uat|prod>

set -e

ENV=$1
if [ -z "$ENV" ]; then
  ENV="local"
  echo "No environment specified: local is used."
fi

pip3 install yq

if [ "$ENV" = "local" ]; then
  image="service-local:latest"
  ENV="dev"
else
  repository=$(yq -r '."microservice-chart".image.repository' ../helm/values-$ENV.yaml)
  image="${repository}:latest"
fi
export image=${image}

FILE=.env
if test -f "$FILE"; then
    rm .env
fi

keyvault=$(yq  -r '."microservice-chart".keyvault.name' ../helm/values-$ENV.yaml)
secret=$(yq  -r '."microservice-chart".envSecret' ../helm/values-$ENV.yaml)

echo "Reading secrets from Azure Key Vault: $keyvault"

for line in $(echo "$secret" | yq -r '. | to_entries[] | select(.key) | "\(.key)=\(.value)"'); do
  IFS='=' read -r -a array <<< "$line"
  response=$(az keyvault secret show --vault-name $keyvault --name "${array[1]}")
  response=$(echo "$response" | tr -d '\n')
  value=$(echo "$response" | yq -r '.value')
  value=$(echo "$value" | sed 's/\$/\$\$/g')
  value=$(echo "$value" | tr -d '\n')
  echo "${array[0]}=$value" >> .env
  
  # PRINT SECRETS
  echo -e "${array[0]} → KV_SECRET_NAME: "${array[1]}" → KV_SECRET_VALUE: $value"
done
