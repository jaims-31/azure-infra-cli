#!/bin/bash
export OWNER="fbarry-student"
export RG="rg-${OWNER}"
export VNET_NAME="vnet-${OWNER}-cli"
export NSG_NAME="nsg-frontend-${OWNER}-cli"

echo "▶ Désassociation du NSG..."
az network vnet subnet update \
  --name "subnet-frontend" --vnet-name "$VNET_NAME" \
  --resource-group "$RG" --network-security-group "" 2>/dev/null || true

echo "▶ Suppression du NSG et VNet..."
az network nsg delete --name "$NSG_NAME" --resource-group "$RG"
az network vnet delete --name "$VNET_NAME" --resource-group "$RG"

echo "✅ Nettoyage terminé."