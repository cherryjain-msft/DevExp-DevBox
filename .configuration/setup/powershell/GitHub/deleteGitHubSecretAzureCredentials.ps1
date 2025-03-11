# PowerShell script to delete GitHub secret for Azure credentials

param (
    [Parameter(Mandatory = $true)]
    [string]$ghSecretName
)

# Exit immediately if a command exits with a non-zero status, treat unset variables as an error, and propagate errors in pipelines.
$ErrorActionPreference = "Stop"
$WarningPreference = "Stop"

# Function to validate input parameters
function Test-Input {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ghSecretName
    )

    try {
        # Check if required parameters are provided
        if ([string]::IsNullOrEmpty($ghSecretName)) {
            throw "Missing required parameters."
        }
    }
    catch {
        Write-Error "Error: $_"
        Write-Output "Usage: .\deleteGitHubSecretAzureCredentials.ps1 -ghSecretName <ghSecretName>"
        return 1
    }
}

# Function to log in to GitHub using the GitHub CLI
function Connect-ToGitHub {
    Write-Output "Logging in to GitHub using GitHub CLI..."

    try {
        # Attempt to log in to GitHub
        gh auth login
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to log in to GitHub."
        }

        Write-Output "Successfully logged in to GitHub."
    }
    catch {
        Write-Error "Error: $_"
        return 1
    }
}

# Function to delete a GitHub secret
function Remove-GitHubSecret {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ghSecretName
    )

    try {
        Write-Output "Deleting GitHub secret: $ghSecretName"

        # Delete the GitHub secret
        gh secret remove $ghSecretName
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to delete GitHub secret: $ghSecretName"
        }

        Write-Output "GitHub secret: $ghSecretName deleted successfully."
    }
    catch {
        Write-Error "Error: $_"
        return 1
    }
}

# Main script execution
try {
    Test-Input -ghSecretName $ghSecretName
    if ($LASTEXITCODE -eq 0) {
        Connect-ToGitHub
        if ($LASTEXITCODE -eq 0) {
            Remove-GitHubSecret -ghSecretName $ghSecretName
        }
    }
}
catch {
    Write-Error "Script execution failed: $_"
    exit 1
}