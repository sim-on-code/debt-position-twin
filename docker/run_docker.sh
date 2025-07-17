#!/bin/bash

# In caso di errore, esci
set -e

# Lettura parametro ambiente (default: local → tradotto in dev)
ENV=$1
if [ -z "$ENV" ]; then
  ENV="local"
  echo "No environment specified: using 'local'"
fi

# Installazione yq (necessaria nel runner GitHub)
pip3 install yq

# Se 'local', usa valori da 'dev'
if [ "$ENV" = "local" ]; then
  ENV="dev"
fi

# Estrai nome del Key Vault dal file helm
VAULT=$(yq -r '."microservice-chart".keyvault.name' ../helm/values-$ENV.yaml)

if [[ -z "$VAULT" || "$VAULT" == "null" ]]; then
  echo "❌ Nessun Key Vault trovato in values-$ENV.yaml"
  exit 1
fi

echo "🔍  Secrets in vault: $VAULT"
az keyvault secret list --vault-name "$VAULT" -o table
