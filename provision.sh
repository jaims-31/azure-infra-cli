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

# ── Stockage (Storage Account + Blobs)
echo ""
echo "▶ [9/9] Création du Storage Account..."

export SA_NAME="st${OWNER//-/}cli"

az storage account create \
  --name "$SA_NAME" \
  --resource-group "$RG" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --allow-blob-public-access true \
  --tags $TAGS

# Récupération automatique de la connection string
export AZURE_STORAGE_CONNECTION_STRING=$(az storage account show-connection-string \
  --name "$SA_NAME" --resource-group "$RG" --query connectionString --output tsv)

# Création des conteneurs
az storage container create --name "api-logs" --public-access off
az storage container create --name "api-config" --public-access blob

# Création des fichiers tests locaux
echo "2024-06-18 - Log test" > access-log.txt
echo '{"app":"AzureTech","version":"1.0"}' > config.json

# Upload
az storage blob upload --container-name "api-logs" --file access-log.txt --name "access-log.txt"
az storage blob upload --container-name "api-config" --file config.json --name "config.json" --content-type "application/json"

echo "✅ Storage Account '$SA_NAME' configuré avec succès."