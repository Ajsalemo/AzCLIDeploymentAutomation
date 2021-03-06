#!/bin/bash

print_help() {
    echo "Usage: <command> options [parameters]"
    echo "Options:"
    echo "  -g | required - The Resource Group to target."
    echo "  -a | required - The App Service Plan to target."
    echo "  -n | required - The name of the App Service to create."
    echo "  -t | optional - If using 'git' as your deployment source, this is required. Otherwise it is not. Example: 'node|12-lts' or 'python|3.6'."
    echo "  -s | optional - Values are either git or acr. Not specifying an option has this default to git."
    echo "  -i | optional - If using 'acr' as your deployment source, this is required. Otherwise it is not. Example: 'mycontainerregistry.azurecr.io/image:tag'"
    exit 1
}

while getopts ':g:a:n:t:s:i:' arg; do
    case $arg in
    # Deployment arguments
    g) DEPLOYMENT_RESOURCE_GROUP=$OPTARG ;;
    a) DEPLOYMENT_APP_SERVICE_PLAN=$OPTARG ;;
    n) DEPLOYMENT_APP_NAME=$OPTARG ;;
    t) DEPLOYMENT_RUNTIME_TYPE=$OPTARG ;;
    s) DEPLOYMENT_SOURCE_TYPE=$OPTARG ;;
    i) ACR_IMAGE=$OPTARG ;;
    # Parameter for help and any other arguments that aren't specified
    \?) print_help ;;
    esac

    # g - Resource Group to deploy the application into
    # a - App Service Plan to deploy the application into
    # n - Application name
    # t - Runtime type, ex: "node|12-lts" or "python|3.6"
    # s - Deployment source, either "git" for Local Git or "acr" for Azure Container Registry
    # i - If using ACR as a deployment source, then this argument is used as the Image to be specified when deploying
done

# Creating this out of function scope to be re-used later
LOGIN_AND_GET_SUB=""

# Complete the initial log in non-interactively
az_set_subscription() {
    echo "Getting subscription information.."
    # Set the subscription to the ID generated when running az account show - after the user logs in (if they need to with az cli)
    LOGIN_AND_GET_SUB=$(az account show --query "id" -o tsv)
    if [[ "$LOGIN_AND_GET_SUB" == "" || -z "$LOGIN_AND_GET_SUB" ]]; then
        echo "No subscription found. Please login with the az cli using the 'az login' command"
        exit 1
    fi
    echo "Setting subscription context to Subscription ID: $LOGIN_AND_GET_SUB.."
    az account set --subscription $LOGIN_AND_GET_SUB
    echo "Subscription set.."
}

az_create_webapp() {
    # Throw an error if any positional arguments are missing
    if [[ -z "$DEPLOYMENT_RESOURCE_GROUP" || -z "$DEPLOYMENT_APP_SERVICE_PLAN" || -z "$DEPLOYMENT_APP_NAME" ]]; then
        echo "ERROR: Missing arguments. Arguments provided must contain the Resource Group, App Service Plan, Web App Name and Runtime type"
        exit 1
    # If the deployment type is set to Git(local git) or is empty, also default to local git
    elif [[ "$DEPLOYMENT_SOURCE_TYPE" == "" || "$DEPLOYMENT_SOURCE_TYPE" == "git" || -z "$DEPLOYMENT_SOURCE_TYPE" ]]; then
        if [ -z "$DEPLOYMENT_RUNTIME_TYPE" ]; then
            echo "ERROR: When using local git as a deployment source type, a runtime type must be specified."
            exit 1
        fi
        # If deployment is set to local git and the runtime type is specified, go through with creation
        az webapp create -g "$DEPLOYMENT_RESOURCE_GROUP" -p "$DEPLOYMENT_APP_SERVICE_PLAN" -n "$DEPLOYMENT_APP_NAME" --runtime "$DEPLOYMENT_RUNTIME_TYPE" --deployment-local-git
    # If the deployment type is set to ACR, run the creation command with ACR and the Image to provide
    elif [ "$DEPLOYMENT_SOURCE_TYPE" == "acr" ]; then
        if [ -z "$ACR_IMAGE" ]; then
            echo "ERROR: No Azure Container Registry Image provided in arguments."
            echo "ERROR: An Image must be provided in the format of mycontainerregistry.azurecr.io/image:tag"
            exit 1
        else
            echo "Creating a Web App for Containers instance with Image: $ACR_IMAGE"
            echo "Logging into Azure Container Registry.."
            az webapp create -g "$DEPLOYMENT_RESOURCE_GROUP" -p "$DEPLOYMENT_APP_SERVICE_PLAN" -n "$DEPLOYMENT_APP_NAME" -i "$ACR_IMAGE"
        fi
    else
        echo "An error has occurred."
        exit 1
    fi
}

# Enable logging after creation so this doesn't have to be done through the portal
az_enable_logging() {
    echo "Enabling App Service Logs.."
    # This defaults to a log retention of 3 days and a quota of 100MB
    az webapp log config --name "$DEPLOYMENT_APP_NAME" --resource-group "$DEPLOYMENT_RESOURCE_GROUP" --docker-container-logging filesystem
}

# Extract publishing credentials for local git if Git is specified as the deployment type
az_extract_publishing_credentials() {
    if [[ "$DEPLOYMENT_SOURCE_TYPE" == "" || "$DEPLOYMENT_SOURCE_TYPE" == "git" || -z "$DEPLOYMENT_SOURCE_TYPE" ]]; then
        if [ -z "$DEPLOYMENT_RUNTIME_TYPE" ]; then
            echo "ERROR: When using local git as a deployment source type, a runtime type must be specified."
            exit 1
        fi
        PUBLISHING_CREDENTIAL_QUERY=$(az webapp deployment list-publishing-credentials --name "$DEPLOYMENT_APP_NAME" --resource-group "$DEPLOYMENT_RESOURCE_GROUP" --subscription "$LOGIN_AND_GET_SUB" --query "[publishingUserName, publishingPassword]" -o tsv)
        echo "-------------------------------- Publishing Credentials --------------------------------"
        echo "--------------------------- Output is username, password and Git clone URI ----------------------------"
        echo "----------------------------------------------------------------------------------------"
        echo "$PUBLISHING_CREDENTIAL_QUERY"
        echo "https://$DEPLOYMENT_APP_NAME.scm.azurewebsites.net:443/$DEPLOYMENT_APP_NAME.git"
    fi
}

# Parent function
execute_func() {
    az_set_subscription
    az_create_webapp
    az_enable_logging
    az_extract_publishing_credentials
}

# Main
execute_func
