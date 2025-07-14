# PowerShell script to generate deployment credentials

param (
    [Parameter(Mandatory = $true)]
    [string]$appName,

    [Parameter(Mandatory = $true)]
    [string]$displayName
)

# Exit immediately if a command exits with a non-zero status, treat unset variables as an error, and propagate errors in pipelines.
$ErrorActionPreference = "Stop"
$WarningPreference = "Stop"

# Function to validate input parameters
function Test-Input {
    param (
        [Parameter(Mandatory = $true)]
        [string]$appName,

        [Parameter(Mandatory = $true)]
        [string]$displayName
    )

    if ([string]::IsNullOrEmpty($appName) -or [string]::IsNullOrEmpty($displayName)) {
        Write-Error "Error: Missing required parameters."
        Write-Output "Usage: .\generateDeploymentCredentials.ps1 -appName <appName> -displayName <displayName>"
        throw "Validation failed"
    }
}

# Function to generate deployment credentials
function New-DeploymentCredentials {
    param (
        [Parameter(Mandatory = $true)]
        [string]$appName,

        [Parameter(Mandatory = $true)]
        [string]$displayName
    )

    try {
        # Define the role and get the subscription ID
        $role = "Contributor"
        $subscriptionId = az account show --query id --output tsv
        if ($LASTEXITCODE -ne 0) {
            throw "Error: Failed to retrieve subscription ID."
        }

        # Create the service principal and capture the appId
        $ghSecretBody = az ad sp create-for-rbac --name $appName --display-name $displayName --role $role --scopes "/subscriptions/$subscriptionId" --json-auth --output json
        if ($LASTEXITCODE -ne 0) {
            throw "Error: Failed to create service principal."
        }

        $appId = az ad sp list --display-name $displayName --query "[0].appId" -o tsv
        if ($LASTEXITCODE -ne 0) {
            throw "Error: Failed to retrieve service principal appId."
        }

        Write-Output "Assigning User Access Administrator and Managed Identity Contributor roles..."
        # Assign User Access Administrator role
        az role assignment create --assignee $appId --role "User Access Administrator" --scope "/subscriptions/$subscriptionId"
        if ($LASTEXITCODE -ne 0) {
            throw "Error: Failed to assign User Access Administrator role."
        }

        # Assign Managed Identity Contributor role
        az role assignment create --assignee $appId --role "Managed Identity Contributor" --scope "/subscriptions/$subscriptionId"
        if ($LASTEXITCODE -ne 0) {
            throw "Error: Failed to assign Managed Identity Contributor role."
        }

        Write-Output "Role assignments completed."
        Write-Output "Service principal credentials:"
        Write-Output $ghSecretBody

        # Create users and assign roles
        New-UsersAndAssignRole -appId $appId

        # Create GitHub secret for Azure credentials
        New-GitHubSecretAzureCredentials -ghSecretBody $ghSecretBody
    }
    catch {
        Write-Error "Error: $_"
        return 1
    }
}

# Function to create users and assign roles
function New-UsersAndAssignRole {
    param (
        [Parameter(Mandatory = $true)]
        [string]$appId
    )

    try {
        Write-Output "Creating users and assigning roles..."

        # Execute the script to create users and assign roles
        .\Azure\createUsersAndAssignRole.ps1
        if ($LASTEXITCODE -ne 0) {
            throw "Error: Failed to create users and assign roles."
        }

        Write-Output "Users created and roles assigned successfully."
    }
    catch {
        Write-Error "Error: $_"
        return 1
    }
}

# Function to create a GitHub secret for Azure credentials
function New-GitHubSecretAzureCredentials {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ghSecretBody
    )

    try {
        if ([string]::IsNullOrEmpty($ghSecretBody)) {
            Write-Error "Error: Missing required parameter."
            Write-Output "Usage: .\generateDeploymentCredentials.ps1 -ghSecretBody <ghSecretBody>"
            throw "Validation failed"
        }

        Write-Output "Creating GitHub secret for Azure credentials..."

        # Execute the script to create the GitHub secret
        .\GitHub\createGitHubSecretAzureCredentials.ps1 $ghSecretBody
        if ($LASTEXITCODE -ne 0) {
            throw "Error: Failed to create GitHub secret for Azure credentials."
        }

        Write-Output "GitHub secret for Azure credentials created successfully."
    }
    catch {
        Write-Error "Error: $_"
        return 1
    }
}

# Main script execution
try {
    Test-Input -appName $appName -displayName $displayName
    New-DeploymentCredentials -appName $appName -displayName $displayName
}
catch {
    Write-Error "Script execution failed: $_"
    exit 1
}