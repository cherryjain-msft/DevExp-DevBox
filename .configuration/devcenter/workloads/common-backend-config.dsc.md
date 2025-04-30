---
title: Backend Development Environment Configuration
tags: 
 - devbox
 - resources
description: Backend Development Environment Configuration
---

# Microsoft Dev Box landing zone accelerator Backend Development Environment Configuration

## Overview

This documentation provides a comprehensive explanation of the Microsoft Dev Box landing zone accelerator backend development environment configuration defined in common-backend-config.dsc.yaml. This configuration deploys a standardized development environment using Desired State Configuration (DSC) to ensure consistency across developer workstations.

## Table of Contents

- Introduction
- Configuration Properties
- Azure Command-Line Tools
  - Azure CLI
  - Azure Developer CLI (azd)
  - Bicep CLI
  - Azure Data CLI
- Local Development Emulators
  - Azure Storage Emulator
  - Azure Cosmos DB Emulator
- Implementation Guide
- Security Considerations
- References

## Introduction

The Microsoft Dev Box landing zone accelerator backend development configuration installs essential tools for Azure backend development, providing a standardized environment with:

- Azure command-line tools for resource management and deployment
- Local development emulators for Azure services
- Source control integration tools

This configuration follows infrastructure-as-code principles, ensuring consistent developer experiences while adhering to Azure best practices.

## Configuration Properties

```yaml
properties:
  configurationVersion: "0.2.0"
  resources:
    # Resources defined below
```

| Property | Value | Description |
|----------|-------|-------------|
| `configurationVersion` | "0.2.0" | Specifies the DSC schema version used |

## Azure Command-Line Tools

### Azure CLI

```yaml
- resource: Microsoft.WinGet.DSC/WinGetPackage
  id: Microsoft.AzureCLI
  directives:
    allowPrerelease: true
    description: Install Azure CLI for managing Azure resources from the command line
  settings:
    id: Microsoft.AzureCLI
```

**Description:**  
Azure CLI is the foundation for Azure management and serves as a dependency for other Azure tools. It provides command-line access to nearly all Azure service operations.

**Key Features:**
- Unified authentication with Microsoft Entra ID (formerly Azure AD)
- Support for service principals and managed identities
- JSON-based output for automation and scripting
- Cross-platform compatibility for consistent workflows

**Security Best Practices:**
- Use 'az login --tenant' to explicitly specify tenants
- Leverage managed identities where available
- Apply RBAC with principle of least privilege
- Use service principals with certificate-based authentication for automation
- Regularly update CLI using 'az upgrade' command
- Avoid storing credentials in CLI cache in shared environments
- Configure CLI to use your organization's approved proxy if required

**Common Development Scenarios:**
- Resource provisioning via templates and scripts
- Querying resource status and configurations
- Integrated deployment workflows with CI/CD
- Management of secrets and connection strings

### Azure Developer CLI (azd)

```yaml
- resource: Microsoft.WinGet.DSC/WinGetPackage
  id: Microsoft.Azd
  directives:
    allowPrerelease: true
    description: Install Azure Developer CLI (azd) for end-to-end application development
  settings:
    id: Microsoft.Azd
  dependsOn:
    - Microsoft.AzureCLI # AZD requires Azure CLI to function properly
```

**Description:**  
Azure Developer CLI (azd) simplifies application development workflow with templates and integrated deployment capabilities.

**Key Features:**
- End-to-end application development lifecycle management
- Built-in templates for common Azure architectural patterns
- Automated environment provisioning with infrastructure as code
- Integration with GitHub Actions and Azure DevOps for CI/CD
- Application monitoring and logging setup

**Development Best Practices:**
- Use environment variables for secrets ('azd env set')
- Leverage service templates for consistent architecture
- Implement standardized application structures
- Follow Azure landing zone principles for environments
- Store azd environment configurations in version control
- Use azd pipeline integration for repeatable deployments
- Include .env.template file but exclude .env files from source control

**Common Development Scenarios:**
- Setting up complete development environments
- Implementing production-ready services with best practices
- Consistent local-to-cloud development experience
- Orchestrating multi-service deployments

### Bicep CLI

```yaml
- resource: Microsoft.WinGet.DSC/WinGetPackage
  id: Microsoft.Bicep
  directives:
    allowPrerelease: true
    description: Install Bicep CLI for Infrastructure as Code development on Azure
  settings:
    id: Microsoft.Bicep
  dependsOn:
    - Microsoft.AzureCLI # Bicep extensions use Azure CLI for deployment
```

**Description:**  
Bicep provides a domain-specific language for deploying Azure resources with improved syntax over ARM templates.

**Key Features:**
- Native integration with Azure Resource Manager
- Support for all Azure resource types and apiVersions
- Resource visualization capabilities
- Module composition for reusable infrastructure
- Built-in functions for dynamic deployments

**IaC Best Practices:**
- Use modules for reusable components
- Implement parameterization for environment flexibility
- Apply Azure Policy as Code for governance
- Use symbolic references instead of string manipulation
- Implement deployment validation with 'what-if'
- Structure Bicep modules with clear separation of concerns
- Validate Bicep files with 'bicep build' before deployment
- Use linting tools to enforce conventions and best practices
- Test deployments in isolation before integrating

**Common Development Scenarios:**
- Defining infrastructure as code for Azure environments
- Creating reusable infrastructure modules
- Setting up complex multi-resource deployments
- Implementing infrastructure governance

### Azure Data CLI

```yaml
- resource: Microsoft.WinGet.DSC/WinGetPackage
  id: Microsoft.Azure.DataCLI
  directives:
    allowPrerelease: true
    description: Install Azure Data CLI for managing Azure data services
  settings:
    id: Microsoft.Azure.DataCLI
```

**Description:**  
Azure Data CLI offers specialized commands for working with Azure data services including databases, storage, and analytics.

**Key Features:**
- Management of SQL Database, SQL Managed Instance, and PostgreSQL
- Support for Synapse Analytics workspace operations
- Data migration tooling and automation
- Integrated data governance capabilities
- Azure Arc data services management

**Data Best Practices:**
- Implement proper data tiering strategies
- Apply column and row level security where needed
- Configure backup and disaster recovery
- Use connection pooling for database access
- Implement proper indexing strategies
- Follow data residency and sovereignty requirements
- Implement automated data classification and protection
- Use dedicated service endpoints for data services
- Enable advanced threat protection for sensitive data

**Common Development Scenarios:**
- Database creation and configuration
- Data migration between environments
- Query performance optimization
- Data masking and security implementation
- Hybrid data estate management with Arc

## Local Development Emulators

### Azure Storage Emulator

```yaml
- resource: Microsoft.WinGet.DSC/WinGetPackage
  id: Microsoft.Azure.StorageEmulator
  directives:
    allowPrerelease: true
    description: Install Azure Storage Emulator for local development
  settings:
    id: Microsoft.Azure.StorageEmulator
```

**Description:**  
Azure Storage Emulator provides a local environment for testing Azure Storage applications without requiring an Azure subscription for development.

**Key Features:**
- Local emulation of Blob, Queue, and Table storage
- Development connection string compatibility with Azure Storage
- Support for Azure Storage SDK integration
- Local debugging of storage-dependent applications
- Reduced development costs by minimizing cloud resource usage

**Development Best Practices:**
- Use consistent connection strings between local and cloud
- Validate local operations match cloud behavior
- Implement proper exception handling for both environments
- Test with both emulator and actual Azure resources before deployment
- Create automated tests that work with both environments
- Consider using Azurite (newer emulator) for feature parity
- Configure proper data persistence for development data
- Document how to initialize the emulator in your project

**Common Development Scenarios:**
- Building applications using Azure Storage
- Performing rapid iterative development
- Unit and integration testing without cloud dependencies
- Offline development scenarios
- Cost optimization during development phases

**Installation Notes:**
- May require administrator privileges
- Consider validating emulator is running after installation
- May need to configure firewall exceptions
- Check SQL Server dependency is met (LocalDB)

### Azure Cosmos DB Emulator

```yaml
- resource: Microsoft.WinGet.DSC/WinGetPackage
  id: Microsoft.Azure.CosmosEmulator
  directives:
    allowPrerelease: true
    description: Install Azure Cosmos DB Emulator for local NoSQL database development
  settings:
    id: Microsoft.Azure.CosmosEmulator
```

**Description:**  
Azure Cosmos DB Emulator provides a local instance of the Cosmos DB service supporting multiple data models (SQL, MongoDB, Gremlin, etc.).

**Key Features:**
- Support for SQL, MongoDB, Table, Gremlin, and Cassandra APIs
- Local development of multi-region applications
- Built-in data explorer for query development
- Export functionality for data migration
- Simulated consistency levels matching Azure Cosmos DB

**Development Best Practices:**
- Use consistent connection logic between emulator and cloud
- Test with various consistency levels before deployment
- Simulate production request patterns for performance testing
- Create parameterized applications that work with both environments
- Ensure partition key strategies are validated locally
- Use environment-specific configuration for connection strings
- Implement retry logic that works in both environments
- Consider resource limits differences between emulator and cloud
- Validate performance with realistic data volumes

**Security Considerations:**
- The emulator uses a well-known certificate and key for development
- Never use the emulator's certificate in production environments
- Data persistence is local and requires backup consideration
- Consider implementing application-level encryption for sensitive data
- Be aware of differences in security features between emulator and cloud

**Installation Requirements:**
- Requires significant disk space (~2GB)
- May conflict with other applications using port 8081
- Consider configuring the emulator to start automatically
- May require system restart

## Security Considerations

When using this configuration, consider these security best practices:

1. **Managed Identities:**
   - Configure applications to use managed identities instead of service principals with credentials
   - Scope managed identities to specific resources using RBAC

2. **Connection String Management:**
   - Never hardcode connection strings in applications
   - Use Azure Key Vault for storing secrets
   - Use distinct connection strings for development and production

3. **Emulator Limitations:**
   - Emulators don't implement all security features of Azure services
   - Do not store sensitive data in development emulators
   - Be aware that emulator certificates should never be used in production

4. **Local Development Network Security:**
   - Configure firewalls appropriately for local emulator ports
   - Use secure development networks separated from production
   - Implement IP restrictions for local development APIs

5. **Tool Authentication:**
   - Implement credential rotation policies
   - Use separate development identities from production
   - Enable conditional access policies for development tools

## References

- [Azure CLI Documentation](https://learn.microsoft.com/en-us/cli/azure/)
- [Azure Developer CLI Documentation](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/)
- [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Azure Data CLI Documentation](https://learn.microsoft.com/en-us/sql/azdata/install/deploy-install-azdata)
- [Azure Storage Emulator Documentation](https://learn.microsoft.com/en-us/azure/storage/common/storage-use-emulator)
- [Azure Cosmos DB Emulator Documentation](https://learn.microsoft.com/en-us/azure/cosmos-db/local-emulator)
- [Azure Dev Box Documentation](https://learn.microsoft.com/en-us/azure/dev-box/overview-what-is-microsoft-dev-box)
- [DSC Configuration Schema](https://aka.ms/configuration-dsc-schema/0.2)
- [DevExp-DevBox Repository](https://github.com/Evilazaro/DevExp-DevBox/)

---

*This documentation is part of the Microsoft Dev Box landing zone accelerator Accelerator project. For more information, visit the [GitHub Repository](https://github.com/Evilazaro/DevExp-DevBox/).*