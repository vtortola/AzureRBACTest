SHELL := /bin/bash
location := westus3

testA:
	az deployment sub create --location $(location) --name TestA --template-file ./templates/resourceGroup.json --parameters name=TestA

testA_down:
	az group delete --name TestA --yes

secret:
	az deployment group create --resource-group TestA --name TestASecrets  --template-file ./templates/secrets.json --parameters name=Secrets
	az deployment group create --resource-group TestA --name TestASecrets  --template-file ./templates/secrets.json --parameters name=ForbiddenSecrets

test-owner-secret:
# make sure your user account has the "Key Vault Administrator" role or this will fail
	az keyvault secret show --name "secret" --vault-name "TestASecrets" --query "value"
	az keyvault secret show --name "secret" --vault-name "TestAForbiddenSecrets" --query "value"

testB:
	az deployment sub create --location $(location) --name TestB --template-file ./templates/resourceGroup.json --parameters name=TestB

testB_down:
	az group delete --name TestB --yes

server:
	az deployment group create --resource-group TestB --name TestBServer --template-file ./templates/server.json --parameters cloudInit="`base64 ./cloud-init/init.yml`" userData="`base64 ./cloud-init/userData.sh`"
	az vm run-command invoke --resource-group TestB --name TestBServer --command-id RunShellScript --scripts 'cloud-init status --wait' --query "value" --output tsv

server-relogin:
	az vm run-command invoke --resource-group TestB --name TestBServer --command-id RunShellScript --scripts 'az logout && az login --identity' --query "value" --output tsv

test-server-secret:
	az vm run-command invoke --resource-group TestB --name TestBServer --command-id RunShellScript --scripts '/root/test.sh TestASecrets' --query "value" --output tsv
	az vm run-command invoke --resource-group TestB --name TestBServer --command-id RunShellScript --scripts '/root/test.sh TestAForbiddenSecrets' --query "value" --output tsv

test-command:
	az vm run-command invoke --resource-group TestB --name TestBServer --command-id RunShellScript --scripts '$(command)' --query "value" --output tsv


up: testA secret testB server
down: testB_down testA_down