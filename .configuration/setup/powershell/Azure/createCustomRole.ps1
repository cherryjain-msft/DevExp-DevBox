# Variables
$RoleName = "Contoso DevBox - Role Assignment Writer"
$SubscriptionId = "6a4029ea-399b-4933-9701-436db72883d4"

# Role Definition
$RoleDefinition = @{
    Name         = $RoleName
    IsCustom     = $true
    Description  = "Allows creating role assignments."
    Actions      = @(
        "Microsoft.Authorization/roleAssignments/write"
        "Microsoft.Authorization/roleAssignments/delete"
        "Microsoft.Authorization/roleAssignments/read"
    )
    NotActions   = @()
    DataActions  = @()
    NotDataActions = @()
    AssignableScopes = @(
        "/subscriptions/$SubscriptionId"
    )
}

# Convert to JSON
$RoleDefinitionJson = $RoleDefinition | ConvertTo-Json -Depth 10

# Write to a file
$FilePath = ".\custom-role.json"
$RoleDefinitionJson | Out-File -FilePath $FilePath -Encoding utf8

az role definition delete --name $RoleName
# Create the custom role
az role definition create --role-definition $FilePath

# Optional cleanup
Remove-Item $FilePath
