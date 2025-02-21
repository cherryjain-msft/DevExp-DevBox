# PowerShell script to delete deployment credentials

param (
    [string]$appDisplayName
)

# Function to delete deployment credentials
function Remove-DeploymentCredentials {
    param (
        [Parameter(Mandatory = $true)]
        [string]$appDisplayName
    )

    try {
        # Get the application ID using the display name
        $appId = az ad app list --display-name $appDisplayName --query "[0].appId" -o tsv

        if (-not $appId) {
            throw "Application with display name '$appDisplayName' not found."
        }

        # Delete the service principal
        Write-Output "Deleting service principal with appId: $appId"
        $spDeleteResult = az ad sp delete --id $appId
        if ($null -ne $spDeleteResult) {
            throw "Failed to delete service principal."
        }

        # Delete the application registration
        Write-Output "Deleting application registration with appId: $appId"
        $appDeleteResult = az ad app delete --id $appId
        if ($null -ne $appDeleteResult) {
            throw "Failed to delete application registration."
        }

        Write-Output "Service principal and App Registration deleted successfully."
    }
    catch {
        Write-Error "Error: $_"
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
        Write-Output "Usage: .\deleteDeploymentCredentials.ps1 -appDisplayName <appDisplayName>"
        return 1
    }
}

# Main script execution
try {
    Test-Input -appDisplayName $appDisplayName
    if ($LASTEXITCODE -eq 0) {
        Remove-DeploymentCredentials -appDisplayName $appDisplayName
    }
}
catch {
    Write-Error "Script execution failed: $_"
    exit 1
}