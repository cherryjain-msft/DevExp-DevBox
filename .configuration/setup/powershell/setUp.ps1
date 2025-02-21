# PowerShell script to set up deployment credentials

# Define variables
$appName = "ContosoDevExDevBox"
$displayName = "ContosoDevEx GitHub Actions Enterprise App"

# Function to set up deployment credentials
function Set-Up {
    param (
        [Parameter(Mandatory = $true)]
        [string]$appName,

        [Parameter(Mandatory = $true)]
        [string]$displayName
    )

    try {
        Write-Output "Starting setup for deployment credentials..."
        # Ensure the Azure CLI is installed and available
        if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
            Write-Host "Azure CLI is not installed or not available in the PATH. It will be installed now."
            # Install Azure CLI
            winget install Microsoft.AzureCLI -e --accept-source-agreements --accept-package-agreements
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to install Azure CLI."
            }
        }
        else {
            winget upgrade Microsoft.AzureCLI -e --accept-source-agreements --accept-package-agreements
        }

        # Ensure azd is installed
        if (-not (Get-Command azd -ErrorAction SilentlyContinue)) {
            Write-Host "azd is not installed or not available in the PATH. It will be installed now."
            # Install azd
            winget install Microsoft.Azd -e --accept-source-agreements --accept-package-agreements
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to install azd."
            }
        }
        else {
            winget upgrade Microsoft.Azd -e --accept-source-agreements --accept-package-agreements
        }

        # Execute the script to generate deployment credentials
        # .\Azure\generateDeploymentCredentials.ps1 -appName $appName -displayName $displayName
        .\Azure\createUsersAndAssignRole.ps1

        Write-Host "Showing current Detaults Config..."
        azd config show

        Write-Output "Resetting azd config..."
        azd config reset --force

        azd config show
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to reset azd config."
        }
        azd config set defaults.AZURE_LOCATION "eastus"
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to set default Azure location."
        }
        azd config set defaults.WORKLOAD_NAME "Contoso"
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to set default workload name."
        }
        Write-Output "azd config reset successfully."
        azd config show
        Write-Output "Creating new environments..."
        azd env new dev --no-prompt
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create 'dev' environment."
        }
        azd env new prod --no-prompt
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create 'prod' environment."
        }
        Write-Output "Environments created successfully."

        Write-Output "Deployment credentials set up successfully."
    }
    catch {
        Write-Error "Error during setup: $_"
        return 1
    }
}

# Main script execution
try {
    Clear-Host
    Set-Up -appName $appName -displayName $displayName
}
catch {
    Write-Error "Script execution failed: $_"
    exit 1
}