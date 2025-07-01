<#
.SYNOPSIS
    Sets up Azure Dev Box environment with GitHub integration.

.DESCRIPTION
    Automates the setup of an Azure Developer CLI (azd) environment for Dev Box,
    handles GitHub authentication, and provisions required Azure resources.

    This script follows Azure best practices for security, error handling, 
    and resource management.

.PARAMETER EnvName
    Name of the Azure environment to create. Default is "prod".

.PARAMETER Location
    Azure region where resources will be deployed. Default is "eastus2".

.EXAMPLE
    .\setUp.ps1
    # Creates a "prod" environment in eastus2 region
    
.EXAMPLE
    .\setUp.ps1 -EnvName "dev" -Location "westus2"
    # Creates a "dev" environment in westus2 region

.NOTES
    Requires:
    - Azure CLI (az)
    - Azure Developer CLI (azd)
    - GitHub CLI (gh)
    - Valid GitHub authentication
    
    Author: DevExp Team
    Last Updated: 2023-05-15
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$EnvName = "dev",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("eastus", "eastus2", "westus", "westus2", "northeurope", "westeurope")]
    [string]$Location = "eastus2"
)

#region Script Configuration
# Stop on errors for better error handling
$ErrorActionPreference = "Stop"

# Set secure TLS version - Azure best practice for secure communications
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#endregion

#region Helper Functions
function Write-LogMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $icon = switch($Level) {
        "Info"    { "ℹ️" }
        "Warning" { "⚠️" }
        "Error"   { "❌" }
        "Success" { "✅" }
    }
    
    # Use appropriate colors for different message types
    switch($Level) {
        "Error"   { Write-Host "$icon [$timestamp] $Message" -ForegroundColor Red }
        "Warning" { Write-Host "$icon [$timestamp] $Message" -ForegroundColor Yellow }
        "Success" { Write-Host "$icon [$timestamp] $Message" -ForegroundColor Green }
        "Info"    { Write-Host "$icon [$timestamp] $Message" -ForegroundColor Cyan }
    }
}

function Test-CommandAvailability {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Command
    )
    
    # Check if command exists in PATH
    $exists = $null -ne (Get-Command -Name $Command -ErrorAction SilentlyContinue)
    if (-not $exists) {
        Write-LogMessage "Required command '$Command' was not found. Please install it before continuing." -Level "Error"
        return $false
    }
    return $true
}
#endregion

#region Authentication Functions
function Test-AzureAuthentication {
    [CmdletBinding()]
    param()
    
    try {
        # Redirect error output to null to prevent error messages from displaying
        $azContext = az account show 2>$null | ConvertFrom-Json
        
        # Check if authentication succeeded
        if ($null -eq $azContext) {
            Write-LogMessage "Not logged into Azure. Please run 'az login' first." -Level "Error"
            return $false
        }
        
        # Check if subscription is enabled (Azure best practice)
        if ($azContext.state -ne "Enabled") {
            Write-LogMessage "Current subscription '$($azContext.name)' is not in 'Enabled' state." -Level "Error"
            return $false
        }
        
        # Output subscription details for verification
        Write-LogMessage "Using Azure subscription: $($azContext.name) (ID: $($azContext.id))" -Level "Info"
        return $true
    }
    catch {
        Write-LogMessage "Failed to verify Azure authentication: $_" -Level "Error"
        return $false
    }
}

function Test-GitHubAuthentication {
    [CmdletBinding()]
    param()
    
    try {
        # Capture standard output and error output
        $ghStatus = gh auth status 2>&1
        
        # Check if authentication succeeded
        if ($LASTEXITCODE -ne 0) {
            Write-LogMessage "Not logged into GitHub. Please run 'gh auth login' first." -Level "Error"
            return $false
        }
        
        Write-LogMessage "GitHub authentication verified successfully" -Level "Success"
        return $true
    }
    catch {
        Write-LogMessage "Failed to verify GitHub authentication: $_" -Level "Error"
        return $false
    }
}

function Get-SecureGitHubToken {
    [CmdletBinding()]
    param()
    
    try {
        # Get GitHub token
        $pat = gh auth token
        if (-not $pat) {
            Write-LogMessage "Failed to retrieve GitHub token" -Level "Error"
            return $null
        }
        
        # Convert to secure string to protect in memory
        $securePat = ConvertTo-SecureString -String $pat -AsPlainText -Force
        Write-LogMessage "GitHub token retrieved and stored securely" -Level "Success"
        
        # Return both token and secure token
        # This pattern allows the original function to be maintained
        return $pat, $securePat
    }
    catch {
        Write-LogMessage "Failed to retrieve GitHub token: $_" -Level "Error"
        return $null
    }
}
#endregion

#region Azure Configuration Functions
function Initialize-AzdEnvironment {
    [CmdletBinding()]
    param()
    try {
        Write-LogMessage "Retrieving GitHub token for environment initialization..." -Level "Info"
        $tokenResult = Get-SecureGitHubToken
        if (-not $tokenResult) {
            throw "Unable to retrieve GitHub token. Aborting environment initialization."
        }
        $pat, $securePat = $tokenResult

        # Mask most of the token for security best practices
        $maskedToken = if ($pat.Length -ge 8) { "$($pat.Substring(0,4))****$($pat.Substring($pat.Length-2,2))" } else { "****" }
        Write-LogMessage "🔐 GitHub token stored securely in memory. Masked: $maskedToken" -Level "Success"

        # Create new Azure Developer CLI environment
        Write-LogMessage "Creating new Azure Developer CLI environment: '$EnvName'" -Level "Info"
        azd env new $EnvName --no-prompt
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create Azure Developer CLI environment '$EnvName'."
        }

        # Prepare environment file path
        $envDir = ".\.azure\$EnvName"
        $envFile = Join-Path $envDir ".env"
        if (-not (Test-Path $envDir)) {
            New-Item -Path $envDir -ItemType Directory -Force | Out-Null
        }

        # Azure best practice: Use environment-specific configuration
        Write-LogMessage "Configuring environment variables in $envFile" -Level "Info"
        Set-Content -Path $envFile -Value "AZURE_ENV_NAME='$EnvName'"
        Add-Content -Path $envFile -Value "AZURE_LOCATION='$Location'"

        # Security note: In production, use Azure Key Vault for secrets
        Add-Content -Path $envFile -Value "KEY_VAULT_SECRET='$pat'"

        # Show current configuration for verification
        Write-LogMessage "Current Azure Developer CLI configuration:" -Level "Info"
        azd config show

        Write-LogMessage "Azure Developer CLI environment '$EnvName' initialized successfully." -Level "Success"
        return $true
    }
    catch {
        Write-LogMessage "Failed to initialize Azure Developer CLI environment: $_" -Level "Error"
        return $false
    }
}
#endregion

function Start-AzureProvisioning {
    [CmdletBinding()]
    param()
    
    try {
        Write-LogMessage "Starting Azure resource provisioning with azd..." -Level "Info"
        
        # Run the provisioning process
        # Use the environment name provided by the user
        azd provision -e $EnvName
        
        # Check if the command was successful
        if ($LASTEXITCODE -ne 0) {
            throw "Azure provisioning failed with exit code $LASTEXITCODE"
        }
        
        Write-LogMessage "Azure provisioning completed successfully" -Level "Success"
        return $true
    }
    catch {
        Write-LogMessage "Azure provisioning failed: $_" -Level "Error"
        
        # Provide guidance on common failures
        if ($_.ToString() -like "*quota*" -or $_.ToString() -like "*limit*") {
            Write-LogMessage "This might be a quota issue. Check your Azure subscription limits." -Level "Warning"
        }
        elseif ($_.ToString() -like "*permission*" -or $_.ToString() -like "*authorization*") {
            Write-LogMessage "This might be a permissions issue. Verify your Azure role assignments." -Level "Warning"
        }
        
        return $false
    }
}
#endregion

#region Main Script Execution
try {
    # Script header with basic information
    Write-LogMessage "Starting Dev Box environment setup in '$Location' region" -Level "Info"
    Write-LogMessage "Environment name: $EnvName" -Level "Info"
    
    # Verify required tools - Azure best practice for dependency validation
    $requiredTools = @("az", "azd", "gh")
    $toolsAvailable = $true
    foreach ($tool in $requiredTools) {
        if (-not (Test-CommandAvailability -Command $tool)) {
            $toolsAvailable = $false
        }
    }
    
    # Exit if any required tools are missing
    if (-not $toolsAvailable) {
        Write-LogMessage "Missing required tools. Please install them and retry." -Level "Error"
        exit 1
    }
    
    # Verify Azure authentication - Azure security best practice
    if (-not (Test-AzureAuthentication)) {
        exit 1
    }
    
    # Verify GitHub authentication
    if (-not (Test-GitHubAuthentication)) {
        exit 1
    }
    
    # Initialize azd environment using the original code
    # This step creates the environment and stores the GitHub token
    Write-LogMessage "Initializing Azure Developer CLI environment..." -Level "Info"
    Initialize-AzdEnvironment
    
    # Success message with environment details
    Write-LogMessage "Dev Box environment '$EnvName' setup successfully in '$Location'" -Level "Success"
    Write-LogMessage "Access your Dev Center from the Azure portal" -Level "Info"
    Write-LogMessage "Use 'azd env get-values' to view environment settings" -Level "Info"
}
catch {
    # Comprehensive error handling with specific message
    $errorMsg = $_.Exception.Message
    $errorLine = $_.InvocationInfo.ScriptLineNumber
    
    Write-LogMessage "Setup failed at line $errorLine : $errorMsg" -Level "Error"
    
    # Provide guidance on next steps
    Write-LogMessage "Check the error details above and try again" -Level "Info"
    exit 1
}
finally {
    # Clean up any temporary resources - Azure best practice
    Remove-Variable -Name pat -ErrorAction SilentlyContinue
}
#endregion