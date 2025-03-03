# PowerShell script to clean up the setup by deleting users, credentials, and GitHub secrets

# Exit immediately if a command exits with a non-zero status, treat unset variables as an error, and propagate errors in pipelines.
$ErrorActionPreference = "Stop"
$WarningPreference = "Stop"

$appDisplayName = "ContosoDevEx GitHub Actions Enterprise App"
$ghSecretName = "AZURE_CREDENTIALS"

# Function to delete deployments
function Remove-Deployments {
    param (
        [string]$resourceGroupName
    )

    try {
        $deployments = az deployment sub list --query "[].name" -o tsv
        foreach ($deployment in $deployments) {
            Write-Output "Deleting deployment: $deployment"
            az deployment sub delete --name $deployment
            Write-Output "Deployment $deployment deleted."
        }
    }
    catch {
        Write-Error "Error deleting deployments: $_"
        return 1
    }
}

# Function to clean up the setup by deleting users, credentials, and GitHub secrets
function Remove-SetUp {
    param (
        [Parameter(Mandatory = $true)]
        [string]$appDisplayName,

        [Parameter(Mandatory = $true)]
        [string]$ghSecretName
    )

    try {
        # Check if required parameters are provided
        if ([string]::IsNullOrEmpty($appDisplayName) -or [string]::IsNullOrEmpty($ghSecretName)) {
            throw "Missing required parameters."
        }

        Write-Output "Starting cleanup process for appDisplayName: $appDisplayName and ghSecretName: $ghSecretName"

        # Delete deployments
        Write-Output "Deleting deployments..."
        Remove-Deployments
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to delete deployments."
        }

        # Delete users and assigned roles
        Write-Output "Deleting users and assigned roles..."
        .\.configuration\setup\powershell\Azure\deleteUsersAndAssignedRoles.ps1 -appDisplayName $appDisplayName
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to delete users and assigned roles."
        }

        # Delete deployment credentials
        Write-Output "Deleting deployment credentials..."
        .\.configuration\setup\powershell\Azure\deleteDeploymentCredentials.ps1 -appDisplayName $appDisplayName
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to delete deployment credentials."
        }

        # Delete GitHub secret for Azure credentials
        Write-Output "Deleting GitHub secret for Azure credentials..."
        .\GitHub\deleteGitHubSecretAzureCredentials.ps1 -ghSecretName $ghSecretName
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to delete GitHub secret for Azure credentials."
        }

        Write-Output "Cleanup process completed successfully for appDisplayName: $appDisplayName and ghSecretName: $ghSecretName"
    }
    catch {
        Write-Error "Error during cleanup process: $_"
        return 1
    }
}

# Main script execution
try {
    Clear-Host
    Remove-SetUp -appDisplayName $appDisplayName -ghSecretName $ghSecretName
}
catch {
    Write-Error "Script execution failed: $_"
    exit 1
}