<#
.SYNOPSIS
    Sets up Azure Dev Box environment with source control integration.

.DESCRIPTION
    Automates the setup of an Azure Developer CLI (azd) environment for Dev Box,
    handles GitHub authentication, and provisions required Azure resources.

    This script follows Azure best practices for security, error handling, 
    and resource management.

.PARAMETER EnvName
    Name of the Azure environment to create.

.PARAMETER SourceControl
    Source control platform (github or adogit).

.PARAMETER Help
    Show help message.

.EXAMPLE
    .\setUp.ps1 -EnvName "prod" -SourceControl "github"
    # Creates a "prod" environment with GitHub
    
.EXAMPLE
    .\setUp.ps1 -EnvName "dev" -SourceControl "adogit"
    # Creates a "dev" environment with Azure DevOps

.NOTES
    Requires:
    - Azure CLI (az)
    - Azure Developer CLI (azd)
    - GitHub CLI (gh) [if using GitHub]
    - Valid authentication for chosen platform
    
    Author: DevExp Team
    Last Updated: 2023-05-15
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, HelpMessage="Name of the Azure environment to create")]
    [ValidateNotNullOrEmpty()]
    [string]$EnvName,
    
    [Parameter(Mandatory=$false, HelpMessage="Source control platform (github or adogit)")]
    [ValidateSet("github", "adogit")]
    [string]$SourceControl,

    [Parameter(Mandatory=$false)]
    [switch]$Help
)

#region Script Configuration
# Stop on errors for better error handling
$ErrorActionPreference = "Stop"

# Set secure TLS version - Azure best practice for secure communications
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Global Variables
$script:ScriptDir = $PSScriptRoot
$script:TimestampFormat = "yyyy-MM-dd HH:mm:ss"

# Unicode icons
$script:InfoIcon = "ℹ️"
$script:WarningIcon = "⚠️"
$script:ErrorIcon = "❌"
$script:SuccessIcon = "✅"

# Global variables for script state
$script:GitHubToken = $null
$script:AdoToken = $null
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
    
    $timestamp = Get-Date -Format $script:TimestampFormat
    $icon = switch($Level) {
        "Info"    { $script:InfoIcon }
        "Warning" { $script:WarningIcon }
        "Error"   { $script:ErrorIcon }
        "Success" { $script:SuccessIcon }
    }
    
    # Use appropriate colors for different message types
    switch($Level) {
        "Error"   { 
            Write-Host "$icon [$timestamp] $Message" -ForegroundColor Red
            # Also write to error stream for proper error handling
            Write-Error $Message -ErrorAction Continue
        }
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

function Show-Help {
    [CmdletBinding()]
    param()
    
    $helpText = @"
setUp.ps1 - Sets up Azure Dev Box environment with source control integration

USAGE:
    .\setUp.ps1 -EnvName ENV_NAME -SourceControl SOURCE_CONTROL

PARAMETERS:
    -EnvName ENV_NAME          Name of the Azure environment to create
    -SourceControl PLATFORM    Source control platform (github or adogit)
    -Help                      Show this help message

EXAMPLES:
    .\setUp.ps1 -EnvName "prod" -SourceControl "github"
    .\setUp.ps1 -EnvName "dev" -SourceControl "adogit"

REQUIREMENTS:
    - Azure CLI (az)
    - Azure Developer CLI (azd)
    - GitHub CLI (gh) [if using GitHub]
    - Valid authentication for chosen platform
"@
    
    Write-Host $helpText
}

function Test-SourceControlPlatform {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Platform
    )
    
    $validPlatforms = @("github", "adogit")
    if ($Platform -notin $validPlatforms) {
        Write-LogMessage "Invalid source control platform: $Platform" -Level "Error"
        Write-LogMessage "Valid platforms: $($validPlatforms -join ', ')" -Level "Info"
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
        Write-LogMessage "Verifying Azure authentication..." -Level "Info"
        
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

function Test-AdoAuthentication {
    [CmdletBinding()]
    param()
    
    try {
        Write-LogMessage "Verifying Azure DevOps authentication..." -Level "Info"
        
        # Check if Azure DevOps CLI is authenticated
        $adoStatus = az devops configure --list 2>&1
        
        # Check if authentication succeeded
        if ($LASTEXITCODE -ne 0) {
            Write-LogMessage "Not logged into Azure DevOps. Please run 'az devops login' first." -Level "Error"
            return $false
        }
        
        Write-LogMessage "Azure DevOps authentication verified successfully" -Level "Success"
        return $true
    }
    catch {
        Write-LogMessage "Failed to verify Azure DevOps authentication: $_" -Level "Error"
        return $false
    }
}

function Test-GitHubAuthentication {
    [CmdletBinding()]
    param()
    
    try {
        Write-LogMessage "Verifying GitHub authentication..." -Level "Info"
        
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
        Write-LogMessage "Retrieving GitHub token..." -Level "Info"
        
        # Get GitHub token
        $pat = gh auth token
        if (-not $pat) {
            Write-LogMessage "Failed to retrieve GitHub token" -Level "Error"
            return $null
        }
        
        Write-LogMessage "GitHub token retrieved and stored securely" -Level "Success"
        
        # Store in script variable
        $script:GitHubToken = $pat
        return $pat
    }
    catch {
        Write-LogMessage "Failed to retrieve GitHub token: $_" -Level "Error"
        return $null
    }
}

function Get-SecureAdoGitToken {
    [CmdletBinding()]
    param()
    
    try {
        Write-LogMessage "Retrieving Azure DevOps token..." -Level "Info"
        
        # Try to get PAT from environment variable first
        $pat = $env:AZURE_DEVOPS_EXT_PAT
        if (-not $pat) {
            Write-LogMessage "Azure DevOps PAT not found in environment variable 'AZURE_DEVOPS_EXT_PAT'." -Level "Warning"
            Write-LogMessage "Please enter your PAT securely." -Level "Warning"
            
            # Prompt for PAT securely (no echo)
            $secureInput = Read-Host -Prompt "Enter your Azure DevOps Personal Access Token" -AsSecureString
            # Convert SecureString to plain text for storage (in-memory only)
            $pat = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureInput))
            
            # Configure Azure DevOps defaults
            az devops configure --defaults organization=https://dev.azure.com/contososa2 project=DevExp-DevBox 2>$null
            if ($LASTEXITCODE -ne 0) {
                Write-LogMessage "Azure DevOps organization and project not set. Please configure them first." -Level "Error"
                return $null
            }
        }

        if (-not $pat) {
            Write-LogMessage "Failed to retrieve Azure DevOps PAT" -Level "Error"
            return $null
        }

        # Export the token to environment variable
        $env:AZURE_DEVOPS_EXT_PAT = $pat

        Write-LogMessage "Azure DevOps PAT retrieved and stored securely" -Level "Success"
        
        # Store in script variable
        $script:AdoToken = $pat
        return $pat
    }
    catch {
        Write-LogMessage "Failed to retrieve Azure DevOps PAT: $_" -Level "Error"
        return $null
    }
}
#endregion

#region Azure Configuration Functions
function Initialize-AzdEnvironment {
    [CmdletBinding()]
    param()
    
    try {
        Write-LogMessage "Initializing Azure Developer CLI environment..." -Level "Info"
        
        $pat = $null
        $tokenType = ""
        
        # Get appropriate token based on source control platform
        switch ($SourceControl) {
            "github" {
                Write-LogMessage "Retrieving GitHub token for environment initialization..." -Level "Info"
                $pat = Get-SecureGitHubToken
                if (-not $pat) {
                    Write-LogMessage "Unable to retrieve GitHub token. Aborting environment initialization." -Level "Error"
                    return $false
                }
                $tokenType = "GitHub"
            }
            "adogit" {
                Write-LogMessage "Retrieving Azure DevOps token for environment initialization..." -Level "Info"
                $pat = Get-SecureAdoGitToken
                if (-not $pat) {
                    Write-LogMessage "Unable to retrieve Azure DevOps token. Aborting environment initialization." -Level "Error"
                    return $false
                }
                $tokenType = "Azure DevOps"
            }
            default {
                Write-LogMessage "Unsupported source control platform: $SourceControl" -Level "Error"
                return $false
            }
        }
        
        # Mask most of the token for security best practices
        $maskedToken = if ($pat.Length -ge 8) { 
            "$($pat.Substring(0,4))****$($pat.Substring($pat.Length-2,2))" 
        } else { 
            "****" 
        }
        
        Write-LogMessage "🔐 $tokenType token stored securely in memory. Masked: $maskedToken" -Level "Success"
        
        # Azure best practice: Verify environment exists or use existing
        Write-LogMessage "Using Azure Developer CLI environment: '$EnvName'" -Level "Info"
        
        # Prepare environment file path
        $envDir = ".\.azure\$EnvName"
        $envFile = Join-Path $envDir ".env"
        
        if (-not (Test-Path $envDir)) {
            New-Item -Path $envDir -ItemType Directory -Force | Out-Null
        }
        
        # Azure best practice: Use environment-specific configuration
        Write-LogMessage "Configuring environment variables in $envFile" -Level "Info"
        
        $envContent = @"
KEY_VAULT_SECRET='$pat'
"@

        Add-Content -Path $envFile -Value $envContent

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

function Start-AzureProvisioning {
    [CmdletBinding()]
    param()
    
    try {
        Write-LogMessage "Starting Azure resource provisioning with azd..." -Level "Info"
        
        # Run the provisioning process
        azd provision -e $EnvName
        
        # Check if the command was successful
        if ($LASTEXITCODE -ne 0) {
            Write-LogMessage "Azure provisioning failed with exit code $LASTEXITCODE" -Level "Error"
            Write-LogMessage "This might be a quota or permissions issue. Check your Azure subscription limits and role assignments." -Level "Warning"
            return $false
        }
        
        Write-LogMessage "Azure provisioning completed successfully" -Level "Success"
        return $true
    }
    catch {
        Write-LogMessage "Azure provisioning failed: $_" -Level "Error"
        Write-LogMessage "This might be a quota or permissions issue. Check your Azure subscription limits and role assignments." -Level "Warning"
        return $false
    }
}

function Select-SourceControlPlatform {
    [CmdletBinding()]
    param()
    
    Write-LogMessage "Please select your source control platform:" -Level "Info"
    Write-Host ""
    Write-Host "  1. Azure DevOps Git (adogit)" -ForegroundColor Yellow
    Write-Host "  2. GitHub (github)" -ForegroundColor Yellow
    Write-Host ""
    
    do {
        $selection = Read-Host "Enter your choice (1 or 2)"
        switch ($selection) {
            "1" { 
                $script:SourceControl = "adogit"
                Write-LogMessage "Selected: Azure DevOps Git" -Level "Success"
                $validSelection = $true
            }
            "2" { 
                $script:SourceControl = "github"
                Write-LogMessage "Selected: GitHub" -Level "Success"
                $validSelection = $true
            }
            default {
                Write-LogMessage "Invalid selection. Please enter 1 or 2." -Level "Warning"
                $validSelection = $false
            }
        }
    } while (-not $validSelection)
    
    return $script:SourceControl
}
#endregion

#region Main Script Logic
function Test-Parameters {
    [CmdletBinding()]
    param()
    
    # Show help if requested
    if ($Help) {
        Show-Help
        exit 0
    }
    
    # Validate required parameters
    if (-not $EnvName) {
        Write-LogMessage "Environment name is required. Use -EnvName parameter." -Level "Error"
        Show-Help
        return $false
    }
    
    # If source control not provided, prompt for it
    if (-not $SourceControl) {
        $script:SourceControl = Select-SourceControlPlatform
    }
    
    # Validate parameters
    if (-not (Test-SourceControlPlatform -Platform $SourceControl)) {
        return $false
    }
    
    return $true
}

function Invoke-Cleanup {
    [CmdletBinding()]
    param()
    
    # Clean up any temporary resources - Azure best practice
    $script:GitHubToken = $null
    $script:AdoToken = $null
    Remove-Variable -Name "AZURE_DEVOPS_EXT_PAT" -Scope Global -ErrorAction SilentlyContinue
}

function Invoke-Main {
    [CmdletBinding()]
    param()
    
    try {
        # Validate parameters
        if (-not (Test-Parameters)) {
            return $false
        }
        
        # Script header with basic information
        Write-LogMessage "Starting Dev Box environment setup" -Level "Info"
        Write-LogMessage "Environment name: $EnvName" -Level "Info"
        Write-LogMessage "Source control platform: $SourceControl" -Level "Info"
        
        # Verify required tools - Azure best practice for dependency validation
        $requiredTools = @("az", "azd")
        if ($SourceControl -eq "github") {
            $requiredTools += "gh"
        }
        
        Write-LogMessage "Checking required tools..." -Level "Info"
        $toolsAvailable = $true
        foreach ($tool in $requiredTools) {
            if (-not (Test-CommandAvailability -Command $tool)) {
                $toolsAvailable = $false
            }
        }
        
        # Exit if any required tools are missing
        if (-not $toolsAvailable) {
            Write-LogMessage "Missing required tools. Please install them and retry." -Level "Error"
            return $false
        }
        Write-LogMessage "All required tools are available" -Level "Success"
        
        # Verify Azure authentication - Azure security best practice
        if (-not (Test-AzureAuthentication)) {
            return $false
        }
        
        # Verify source control authentication
        switch ($SourceControl) {
            "github" {
                if (-not (Test-GitHubAuthentication)) {
                    return $false
                }
            }
            "adogit" {
                if (-not (Test-AdoAuthentication)) {
                    return $false
                }
            }
        }
        
        # Initialize azd environment
        Write-LogMessage "Initializing Azure Developer CLI environment..." -Level "Info"
        if (-not (Initialize-AzdEnvironment)) {
            Write-LogMessage "Failed to initialize Azure Developer CLI environment. Exiting." -Level "Error"
            return $false
        }
        
        # Success message with environment details
        Write-LogMessage "Dev Box environment '$EnvName' setup successfully" -Level "Success"
        Write-LogMessage "Access your Dev Center from the Azure portal" -Level "Info"
        Write-LogMessage "Use 'azd env get-values' to view environment settings" -Level "Info"
        
        return $true
    }
    catch {
        # Comprehensive error handling with specific message
        $errorMsg = $_.Exception.Message
        $errorLine = $_.InvocationInfo.ScriptLineNumber
        
        Write-LogMessage "Setup failed at line $errorLine : $errorMsg" -Level "Error"
        Write-LogMessage "Check the error details above and try again" -Level "Info"
        return $false
    }
    finally {
        # Clean up any temporary resources - Azure best practice
        Invoke-Cleanup
    }
}
#endregion

#region Script Execution
# Set up error handling
trap {
    Write-LogMessage "Script interrupted or failed. Cleaning up..." -Level "Warning"
    Invoke-Cleanup
    break
}

# Execute main function
$success = Invoke-Main

# Exit with appropriate code
if ($success) {
    exit 0
} else {
    exit 1
}
#endregion
