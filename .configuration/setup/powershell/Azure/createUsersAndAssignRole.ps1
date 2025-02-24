# PowerShell script to create user assignments and assign roles

# Get the current subscription ID
$subscriptionId = (az account show --query id -o tsv)

# Function to assign a role to a user or service principal
function Set-Role {
    param (
        [Parameter(Mandatory = $true)]
        [string]$userIdentityId,

        [Parameter(Mandatory = $true)]
        [string]$roleName,

        [Parameter(Mandatory = $true)]
        [string]$idType
    )

    try {
        Write-Output "Checking if '$roleName' role is already assigned to identityId $userIdentityId..."

        # Check if the role is already assigned
        $existingAssignment = az role assignment list --assignee $userIdentityId --role $roleName --scope /subscriptions/$subscriptionId --query "[?principalType=='$idType']" -o tsv

        if ($existingAssignment) {
            Write-Output "Role '$roleName' is already assigned to identityId $userIdentityId. Skipping assignment."
            return 0
        }

        Write-Output "Assigning '$roleName' role to identityId $userIdentityId..."

        # Attempt to assign the role
        $result = az role assignment create --assignee-object-id $userIdentityId --assignee-principal-type $idType --role $roleName --scope /subscriptions/$subscriptionId

        if ($result) {
            Write-Output "Role '$roleName' assigned successfully."
        }
        else {
            throw "Failed to assign role '$roleName' to identityId $userIdentityId."
        }
    }
    catch {
        Write-Error "Error: $_"
        return 2
    }
}

# Function to create user assignments and assign roles
function New-UserAssignments {
    try {
        # Get the current signed-in user's object ID
        $currentUser = az ad signed-in-user show --query id -o tsv

        if (-not $currentUser) {
            throw "Failed to retrieve current signed-in user's object ID."
        }

        Write-Output "Creating user assignments and assigning roles for currentUser: $currentUser"

        $roles = @(
            "DevCenter Dev Box User",
            "DevCenter Project Admin",
            "Deployment Environments Reader",
            "Deployment Environments User"
        )

        foreach ($role in $roles) {
            Set-Role -userIdentityId $currentUser -roleName $role -idType "User"
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to assign role '$role' to current user with object ID: $currentUser"
            }
        }

        Write-Output "User assignments and role assignments completed successfully for currentUser: $currentUser"
    }
    catch {
        Write-Error "Error: $_"
        return 1
    }
}

# Main script execution
New-UserAssignments