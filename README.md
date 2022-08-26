# RBAC PoC
This is a small proof of concept to test Azure RBAC across resource groups.

 - Creates a resource group TestA with two key vaults, TestASecrets and TestAForbiddenSecrets.
 - Creates a resource group TestB with a VM that has a managed identity which should have access to TestASecrets.

### Expected behaviour
The managed identity in the VM should be able to access the key vault TestASecrets but not TestAForbiddenSecrets

### Current behaviour
The VM cannot access the vaults.

It works if I go the "Azure Portal" => "KeyVaults" => "TestASecrets" => "Access Control (IAM)" => "Add role assignment" and manually adds an assignment of "TestBRole" to "TestBIdentity", but I don't know how to do that kind of "roleAssignment" with ARM templates.


## Usage
### Setup
Deploy all the stack
```
make up
```
### Test
Check if the VM can access the vaults
```
make test-server-secret
```
Expected:
```
$ make test-server-secret 
az vm run-command invoke --resource-group TestB --name TestBServer --command-id RunShellScript --scripts '/root/test.sh TestASecrets' --query "value" --output tsv
ProvisioningState/succeeded     Provisioning succeeded  Info    Enable succeeded: 
[stdout]
hello TestASecrets

[stderr]
        None
az vm run-command invoke --resource-group TestB --name TestBServer --command-id RunShellScript --scripts '/root/test.sh TestAForbiddenSecrets' --query "value" --output tsv
ProvisioningState/succeeded     Provisioning succeeded  Info    Enable succeeded: 
[stdout]

[stderr]
ERROR: Caller is not authorized to perform action on resource.
If role assignments, deny assignments or role definitions were changed recently, please observe propagation time.
Caller: appid=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX;oid=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX;iss=https://sts.windows.net/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX/
Action: 'Microsoft.KeyVault/vaults/secrets/getSecret/action'
Resource: '/subscriptions/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX/resourcegroups/testa/providers/microsoft.keyvault/vaults/testaforbiddensecrets/secrets/secret'
Assignment: (not found)
Vault: TestAForbiddenSecrets;location=westus3

        None

```
### TearDown
Destroy all the stack
```
make down
```
