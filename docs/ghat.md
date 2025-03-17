# How to Create a Personal Access Token in GitHub

## Goal
This guide will walk you through the process of creating a Personal Access Token (PAT) in GitHub. The PAT will be used to deploy a solution to Azure.

## Context
Personal Access Tokens are used to authenticate to GitHub when using the GitHub API or the command line. They are an alternative to using passwords for authentication.

## Steps

### 1. Navigate to GitHub Settings
1. Log in to your GitHub account.
2. Click on your profile picture in the top-right corner of the page.
3. From the dropdown menu, select **Settings**.

!GitHub Settings

### 2. Access Developer Settings
1. In the left sidebar of the settings page, scroll down and click on **Developer settings**.

!Developer Settings

### 3. Create a New Token
1. Under **Developer settings**, select **Personal access tokens**.
2. Choose either **Tokens (classic)** or **Fine-grained tokens**, depending on your needs.
3. Click the **Generate new token** button. If you're creating a classic token, select **Generate new token (classic)**.

!Generate New Token

### 4. Configure Your Token
1. Set an expiration date for your token, from 7 days to never.
2. Add a note to describe the token's purpose.
3. Select the scopes that match the permissions you need. For deploying to Azure, you might need scopes like `repo`, `workflow`, and `write:packages`.

!Configure Token

### 5. Generate and Copy Your Token
1. Once you've selected your scopes, scroll down and click **Generate token**.
2. GitHub will generate your token and display it only once. Be sure to copy it immediately, as you won’t be able to view it again.

!Copy Token

### 6. Use Your Token
1. Use the generated token to authenticate to GitHub when deploying your solution to Azure.

---

This guide is based on the official GitHub documentation. If you have any questions or need further assistance, feel free to ask!

: Managing your personal access tokens - GitHub Docs