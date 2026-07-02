#!/bin/bash
# Configuration des variables
export OWNER="fbarry-student"            
export RG="rg-${OWNER}"              
export LOCATION="spaincentral"
export TAGS="managed_by=cli environment=tp owner=${OWNER}"
export VNET_NAME="vnet-${OWNER}-cli"
export NSG_NAME="nsg-frontend-${OWNER}-cli"

echo "▶ Création du VNet..."
az network vnet create \
  --name           "$VNET_NAME" \
  --resource-group "$RG" \
  --location       "$LOCATION" \
  --address-prefix "10.0.0.0/16" \
  --tags           $TAGS

echo "▶ Création des Subnets..."
az network vnet subnet create \
  --name "subnet-frontend" --vnet-name "$VNET_NAME" \
  --resource-group "$RG" --address-prefix "10.0.1.0/24"

az network vnet subnet create \
  --name "subnet-backend" --vnet-name "$VNET_NAME" \
  --resource-group "$RG" --address-prefix "10.0.2.0/24"

echo "▶ Création du NSG..."
az network nsg create \
  --name "$NSG_NAME" --resource-group "$RG" \
  --location "$LOCATION" --tags $TAGS

echo "▶ Ajout des règles NSG..."
az network nsg rule create \
  --name "Allow-HTTP" --nsg-name "$NSG_NAME" --resource-group "$RG" \
  --priority 100 --direction Inbound --access Allow --protocol Tcp \
  --source-address-prefix "*" --source-port-range "*" \
  --destination-address-prefix "*" --destination-port-range "80"

az network nsg rule create \
  --name "Allow-HTTPS" --nsg-name "$NSG_NAME" --resource-group "$RG" \
  --priority 110 --direction Inbound --access Allow --protocol Tcp \
  --source-address-prefix "*" --source-port-range "*" \
  --destination-address-prefix "*" --destination-port-range "443"

az network nsg rule create \
  --name "Deny-All-Inbound" --nsg-name "$NSG_NAME" --resource-group "$RG" \
  --priority 4000 --direction Inbound --access Deny --protocol "*" \
  --source-address-prefix "*" --source-port-range "*" \
  --destination-address-prefix "*" --destination-port-range "*"

echo "▶ Association du NSG au subnet-frontend..."
az network vnet subnet update \
  --name "subnet-frontend" --vnet-name "$VNET_NAME" \
  --resource-group "$RG" \
  --network-security-group "$NSG_NAME"

echo "✅ Déploiement terminé !"