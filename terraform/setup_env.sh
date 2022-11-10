export KEYVAULT_ENDPOINT=$(terraform -chdir=./terraform output -raw KEYVAULT_ENDPOINT)

echo KEYVAULT_ENDPOINT=$KEYVAULT_ENDPOINT
