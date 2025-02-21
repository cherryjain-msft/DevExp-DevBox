# PowerShell script to delete user assignments and roles

param (
    [string]$appDisplayName
)


# Identity Parameters Constants
$customRoleName = "ContosoDevCenterDevBoxRole"

# Get the current subscription ID
$subscriptionId = (az account show --query id --output tsv)

# Function to delete role assignments
function Remove-RoleAssignments {
    try {
        # Deleting role assignments and role definitions
        $roles = @(
            'Owner',  
            $customRoleName, 
            'ContosoDx-identity-customRole', 
            'ContosoIpeDx-identity-customRole', 
            'Deployment Environments Reader', 
            'Deployment Environments User', 
            'DevCenter Project Admin', 
            'DevCenter Dev Box User',
            'User Access Administrator'
        )
        foreach ($roleName in $roles) {
            Write-Output "Getting the role ID for '$roleName'..."
            $roleId = az role definition list --name $roleName --query [].name --output tsv
            if ([string]::IsNullOrEmpty($roleId)) {
                Write-Output "Role ID for '$roleName' not found. Skipping role assignment deletion."
                continue
            }
            else {
                Write-Output "Role ID for '$roleName' is '$roleId'."
                Write-Output "Removing '$roleName' role assignment..."
            }
            Remove-RoleAssignment -roleId $roleId -subscription $subscriptionId
        }
    }
    catch {
        Write-Error "Error deleting role assignments: $_"
        return 1
    }
}

# Function to delete a custom role
function Remove-CustomRole {
    param (
        [Parameter(Mandatory = $true)]
        [string]$roleName
    )

    try {
        Write-Output "Deleting the '$roleName' role..."
        $roleExists = az role definition list --name $roleName

        if ([string]::IsNullOrEmpty($roleExists) -or $roleExists -eq "[]") {
            Write-Output "'$roleName' role does not exist. Skipping deletion."
            return
        }

        az role definition delete --name $roleName

        while ((az role definition list --name $roleName --query [].roleName -o tsv) -eq $roleName) {
            Write-Output "Waiting for the role to be deleted..."
            Start-Sleep -Seconds 10
        }
        Write-Output "'$roleName' role successfully deleted."
    }
    catch {
        Write-Error "Error deleting custom role $roleName $_"
        return 1
    }
}

# Function to remove a role assignment
function Remove-RoleAssignment {
    param (
        [Parameter(Mandatory = $true)]
        [string]$roleId,

        [Parameter(Mandatory = $true)]
        [string]$subscription
    )

    try {
        Write-Output "Checking the role assignments for the identity..."

        if ([string]::IsNullOrEmpty($roleId)) {
            Write-Output "Role not defined. Skipping role assignment deletion."
            return
        }

        $assignmentExists = az role assignment list --role $roleId --scope /subscriptions/$subscription
        if ([string]::IsNullOrEmpty($assignmentExists) -or $assignmentExists -eq "[]") {
            Write-Output "'$roleId' role assignment does not exist. Skipping deletion."
        }
        else {
            Write-Output "Removing '$roleId' role assignment from the identity..."
            az role assignment delete --role $roleId
            Write-Output "'$roleId' role assignment successfully removed."
        }
    }
    catch {
        Write-Error "Error removing role assignment $roleId $_"
        return 1
    }
}

# Function to validate input parameters
function Test-Input {
    param (
        [Parameter(Mandatory = $true)]
        [string]$appDisplayName
    )

    if ([string]::IsNullOrEmpty($appDisplayName)) {
        Write-Output "Error: Missing required parameter."
        Write-Output "Usage: .\deleteUsersAndAssignedRoles.ps1 -appDisplayName <appDisplayName>"
        return 1
    }
}

# Main script execution
try {
    Test-Input -appDisplayName $appDisplayName
    if ($LASTEXITCODE -eq 0) {
        Remove-RoleAssignments
        Remove-CustomRole -roleName $customRoleName
        Remove-CustomRole -roleName 'ContosoDx-identity-customRole'
        Remove-CustomRole -roleName 'ContosoIpeDx-identity-customRole'
    }
}
catch {
    Write-Error "Script execution failed: $_"
    exit 1
}