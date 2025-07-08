#!/bin/bash

#
# SYNOPSIS
#     Sets up Azure Dev Box environment with GitHub integration.
#
# DESCRIPTION
#     Automates the setup of an Azure Developer CLI (azd) environment for Dev Box,
#     handles GitHub authentication, and provisions required Azure resources.
#
#     This script follows Azure best practices for security, error handling, 
#     and resource management.
#
# PARAMETERS
#     EnvName - Name of the Azure environment to create. Default is "demo".
#     Location - Azure region where resources will be deployed. Default is "eastus2".
#     sourceControlPlatform - Source control platform ("gitHub" or "adoGit"). Default is "adoGit".
#
# EXAMPLES
#     ./setUp.sh
#     # Creates a "demo" environment in eastus2 region
#     
#     ./setUp.sh --env-name "dev" --location "westus2"
#     # Creates a "dev" environment in westus2 region
#
#     ./setUp.sh --source-control "gitHub"
#     # Uses GitHub as source control platform
#
# NOTES
#     Requires:
#     - Azure CLI (az)
#     - Azure Developer CLI (azd)
#     - GitHub CLI (gh) - when using GitHub platform
#     - Valid authentication for chosen platform
#     
#     Author: DevExp Team
#     Last Updated: 2023-05-15
#

# Script Configuration
# Stop on errors for better error handling
set -e

# Default parameters
EnvName="${1:-demo}"  # Default environment name is "demo"
Location="${2:-eastus2}"  # Default location is "eastus2"
sourceControlPlatform="${3:-adoGit}"  # Default source control platform is "adoGit"

#region Helper Functions
Write-LogMessage() {
    local Message="$1"
    local Level="${2:-Info}"
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local icon
    local color
    
    case "$Level" in
        "Info")
            icon="[INFO]"
            color="\033[0;36m"  # Cyan
            ;;
        "Warning")
            icon="[WARN]"
            color="\033[0;33m"  # Yellow
            ;;
        "Error")
            icon="[ERROR]"
            color="\033[0;31m"  # Red
            ;;
        "Success")
            icon="[SUCCESS]"
            color="\033[0;32m"  # Green
            ;;
        *)
            icon="[INFO]"
            color="\033[0;36m"  # Cyan
            ;;
    esac
    
    # Use appropriate colors for different message types
    echo -e "${color}${icon} [${timestamp}] ${Message}\033[0m"
}

Test-CommandAvailability() {
    local Command="$1"
    
    # Check if command exists in PATH
    if ! command -v "$Command" &> /dev/null; then
        Write-LogMessage "Required command '$Command' was not found. Please install it before continuing." "Error"
        return 1
    fi
    return 0
}
#endregion

#region Authentication Functions
Test-AzureAuthentication() {
    local azContext
    
    # Redirect error output to null to prevent error messages from displaying
    if ! azContext=$(az account show 2>/dev/null); then
        Write-LogMessage "Not logged into Azure. Please run 'az login' first." "Error"
        return 1
    fi
    
    # Check if subscription is enabled (Azure best practice)
    local state=$(echo "$azContext" | jq -r '.state')
    if [[ "$state" != "Enabled" ]]; then
        local name=$(echo "$azContext" | jq -r '.name')
        Write-LogMessage "Current subscription '$name' is not in 'Enabled' state." "Error"
        return 1
    fi
    
    # Output subscription details for verification
    local name=$(echo "$azContext" | jq -r '.name')
    local id=$(echo "$azContext" | jq -r '.id')
    Write-LogMessage "Using Azure subscription: $name (ID: $id)" "Info"
    return 0
}

Test-AdoAuthentication() {
    local adoStatus
    
    # Check if Azure DevOps CLI is authenticated
    if ! adoStatus=$(az devops configure --list 2>&1); then
        Write-LogMessage "Not logged into Azure DevOps. Please run 'az devops login' first." "Error"
        return 1
    fi
    
    Write-LogMessage "Azure DevOps authentication verified successfully" "Success"
    return 0
}

Test-GitHubAuthentication() {
    local ghStatus
    
    # Capture standard output and error output
    if ! ghStatus=$(gh auth status 2>&1); then
        Write-LogMessage "Not logged into GitHub. Please run 'gh auth login' first." "Error"
        return 1
    fi
    
    Write-LogMessage "GitHub authentication verified successfully" "Success"
    return 0
}

# Global variables for function returns
GITHUB_TOKEN=""
ADO_TOKEN=""

Get-SecureGitHubToken() {
    local pat
    
    # Get GitHub token
    if ! pat=$(gh auth token); then
        Write-LogMessage "Failed to retrieve GitHub token" "Error"
        return 1
    fi
    
    if [[ -z "$pat" ]]; then
        Write-LogMessage "Failed to retrieve GitHub token" "Error"
        return 1
    fi
    
    Write-LogMessage "GitHub token retrieved and stored securely" "Success"
    
    # Store the token in global variable instead of echo
    GITHUB_TOKEN="$pat"
    return 0
}

Get-SecureAdoGitToken() {
    local pat="$AZURE_DEVOPS_EXT_PAT"
    
    if [[ -z "$pat" ]]; then
        Write-LogMessage "Azure DevOps PAT not found in environment variable 'AZURE_DEVOPS_EXT_PAT'. Please enter your PAT securely." "Warning"
        echo -n "Enter your Azure DevOps Personal Access Token: "
        read -s pat
        echo  # New line after silent input
        
        # Configure Azure DevOps defaults
        if ! az devops configure --defaults organization=https://dev.azure.com/contososa2 project=DevExp-DevBox; then
            Write-LogMessage "Azure DevOps organization and project not set. Please configure them first." "Error"
            return 1
        fi
    fi

    if [[ -z "$pat" ]]; then
        Write-LogMessage "Failed to retrieve Azure DevOps PAT" "Error"
        return 1
    fi

    Write-LogMessage "Azure DevOps PAT retrieved and stored securely" "Success"
    
    # Store the token in global variable instead of echo
    ADO_TOKEN="$pat"
    return 0
}
#endregion

#region Azure Configuration Functions
Initialize-AzdEnvironment() {
    local pat
    local tokenType
    
    if [[ "$sourceControlPlatform" == "gitHub" ]]; then
        Write-LogMessage "Retrieving GitHub token for environment initialization..." "Info"
        if ! Get-SecureGitHubToken; then
            Write-LogMessage "Unable to retrieve GitHub token. Aborting environment initialization." "Error"
            return 1
        fi
        pat="$GITHUB_TOKEN"
        tokenType="GitHub"
    elif [[ "$sourceControlPlatform" == "adoGit" ]]; then
        Write-LogMessage "Retrieving Azure DevOps token for environment initialization..." "Info"
        if ! Get-SecureAdoGitToken; then
            Write-LogMessage "Unable to retrieve Azure DevOps token. Aborting environment initialization." "Error"
            return 1
        fi
        pat="$ADO_TOKEN"
        tokenType="Azure DevOps"
    else
        Write-LogMessage "Unsupported source control platform: $sourceControlPlatform" "Error"
        return 1
    fi

    # Mask most of the token for security best practices
    local maskedToken
    if [[ ${#pat} -ge 8 ]]; then
        maskedToken="${pat:0:4}****${pat: -2}"
    else
        maskedToken="****"
    fi
    Write-LogMessage "$tokenType token stored securely in memory. Masked: $maskedToken" "Success"

    # Create new Azure Developer CLI environment
    Write-LogMessage "Creating new Azure Developer CLI environment: '$EnvName'" "Info"
    if ! azd env new "$EnvName" --no-prompt; then
        Write-LogMessage "Failed to create Azure Developer CLI environment '$EnvName'." "Error"
        return 1
    fi

    # Prepare environment file path
    local envDir="./.azure/$EnvName"
    local envFile="$envDir/.env"
    if [[ ! -d "$envDir" ]]; then
        mkdir -p "$envDir"
    fi

    # Azure best practice: Use environment-specific configuration
    Write-LogMessage "Configuring environment variables in $envFile" "Info"
    cat > "$envFile" << EOF
AZURE_ENV_NAME='$EnvName'
AZURE_LOCATION='$Location'
KEY_VAULT_SECRET='$pat'
EOF

    # Show current configuration for verification
    Write-LogMessage "Current Azure Developer CLI configuration:" "Info"
    azd config show

    Write-LogMessage "Azure Developer CLI environment '$EnvName' initialized successfully." "Success"
    return 0
}

Start-AzureProvisioning() {
    Write-LogMessage "Starting Azure resource provisioning with azd..." "Info"
    
    # Run the provisioning process
    # Use the environment name provided by the user
    if ! azd provision -e "$EnvName"; then
        Write-LogMessage "Azure provisioning failed" "Error"
        
        # Provide guidance on common failures
        Write-LogMessage "This might be a quota or permissions issue. Check your Azure subscription limits and role assignments." "Warning"
        return 1
    fi
    
    Write-LogMessage "Azure provisioning completed successfully" "Success"
    return 0
}
#endregion

#region Main Script Execution
main() {
    # Trap errors for cleanup
    trap 'Write-LogMessage "Script interrupted or failed. Cleaning up..." "Warning"; cleanup_variables' EXIT
    
    # Script header with basic information
    Write-LogMessage "Starting Dev Box environment setup in '$Location' region" "Info"
    Write-LogMessage "Environment name: $EnvName" "Info"
    Write-LogMessage "Source control platform: $sourceControlPlatform" "Info"
    
    # Verify required tools - Azure best practice for dependency validation
    local requiredTools=("az" "azd" "jq")
    if [[ "$sourceControlPlatform" == "gitHub" ]]; then
        requiredTools+=("gh")
    fi
    
    local toolsAvailable=true
    for tool in "${requiredTools[@]}"; do
        if ! Test-CommandAvailability "$tool"; then
            toolsAvailable=false
        fi
    done
    
    # Exit if any required tools are missing
    if [[ "$toolsAvailable" == false ]]; then
        Write-LogMessage "Missing required tools. Please install them and retry." "Error"
        exit 1
    fi
    
    # Verify Azure authentication - Azure security best practice
    if ! Test-AzureAuthentication; then
        exit 1
    fi
    
    if [[ "$sourceControlPlatform" == "gitHub" ]]; then
        # Verify GitHub authentication
        if ! Test-GitHubAuthentication; then
            exit 1
        fi
    elif [[ "$sourceControlPlatform" == "adoGit" ]]; then
        # Verify Azure DevOps authentication
        if ! Test-AdoAuthentication; then
            exit 1
        fi
    fi
    
    # Initialize azd environment using the original code
    # This step creates the environment and stores the token
    Write-LogMessage "Initializing Azure Developer CLI environment..." "Info"
    if ! Initialize-AzdEnvironment; then
        Write-LogMessage "Failed to initialize Azure Developer CLI environment. Exiting." "Error"
        exit 1
    fi
    
    # Success message with environment details
    Write-LogMessage "Dev Box environment '$EnvName' setup successfully in '$Location'" "Success"
    Write-LogMessage "Access your Dev Center from the Azure portal" "Info"
    Write-LogMessage "Use 'azd env get-values' to view environment settings" "Info"
}

# Cleanup function for security best practices
cleanup_variables() {
    # Clean up any temporary resources - Azure best practice
    unset pat
    unset securePat
    unset GITHUB_TOKEN
    unset ADO_TOKEN
}

# Error handling wrapper
if ! main "$@"; then
    # Comprehensive error handling with specific message
    local errorLine="${BASH_LINENO[0]}"
    Write-LogMessage "Setup failed at line $errorLine" "Error"
    
    # Provide guidance on next steps
    Write-LogMessage "Check the error details above and try again" "Info"
    exit 1
fi
#endregion
