$env:KEYVAULT_ENDPOINT=$(terraform -chdir=terraform output -raw KEYVAULT_ENDPOINT)

echo KEYVAULT_ENDPOINT=$env:KEYVAULT_ENDPOINT
