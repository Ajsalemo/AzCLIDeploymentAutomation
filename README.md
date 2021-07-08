# AzCLIDeploymentAutomation

A script to automate the process of Azure Web App creation to a degree, created for my laziness. This was to speed up personal tasks of creation so scope/usage may not work for everyone. This will either create a Web App with a "Blessed" Image or a Web Apps for Container and specifying an existing Image in an already created ACR(Azure Container Registry).

## Usage 
Usage: <[command]> options [parameters]
- Options:
    - -r | required - The Resource Group to target.
    - -g | required - The App Service Plan to target.
    - -a | required - The name of the App Service to create.
    - -t | optional - If using 'git' as your deployment source, this is required. Otherwise it is not. Example: 'node|12-lts' or 'python|3.6'.
    - -s | optional - Values are either git or acr. Not specifying an option has this default to git.
    - -i | optional - If using 'acr' as your deployment source, this is required. Otherwise it is not. Example: 'mycontainerregistry.azurecr.io/image:tag'
