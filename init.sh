#!/bin/bash

print_help() {
    echo "Usage: <command> options [parameters]"
    echo "Options:"
    echo "  -u | required - Username to sign in with for AZ CLI."
    echo "  -p | required - Password to sign in with for AZ CLI."
    echo "  -r | required - The Resource Group to target."
    echo "  -g | required - The App Service Plan to target."
    echo "  -a | required - The name of the App Service to create."
    echo "  -t | optional - If using 'git' as your deployment source, this is required. Otherwise it is not. Example: 'node|12-lts' or 'python|3.6'."
    echo "  -s | optional - Values are either git or acr. Not specifying an option has this default to git."
    echo "  -i | optional - If using 'acr' as your deployment source, this is required. Otherwise it is not. Example: 'mycontainerregistry.azurecr.io/image:tag'"
    exit 1
}

while getopts ':u:p:r:g:a:t:s:i:' arg; do
    case $arg in
        # Username and password args for non interative deployments
        u) AZ_USERNAME=$OPTARG ;;
        p) AZ_PASSWORD=$OPTARG ;;
        # Deployment arguments
        r) DEPLOYMENT_RESOURCE_GROUP=$OPTARG ;;
        g) DEPLOYMENT_APP_SERVICE_PLAN=$OPTARG ;;
        a) DEPLOYMENT_APP_NAME=$OPTARG ;;
        t) DEPLOYMENT_RUNTIME_TYPE=$OPTARG ;;
        s) DEPLOYMENT_SOURCE_TYPE=$OPTARG ;;
        i) ACR_IMAGE=$OPTARG ;;
        # Parameter for help and any other arguments that aren't specified
        \?) print_help ;;
    esac

    # u - Username for az cli login
    # p - Password for az cl login
    # r - Resource Group to deploy the application into
    # g - App Service Plan to deploy the application into
    # a - Application name
    # t - Runtime type, ex: "node|12-lts" or "python|3.6"
    # s - Deployment source, either "git" for Local Git or "acr" for Azure Container Registry
    # i - If using ACR as a deployment source, then this argument is used as the Image to be specified when deploying
done

# Complete the initial log in non-interactively
az_login() {
    if [ -z "$AZ_USERNAME" ]; then
        echo "ERROR: Username must be supplied"
        exit 1
    elif [ -z "$AZ_PASSWORD" ]; then
        echo "ERROR: Password must be supplied"
        exit 1
    else
        echo "Logging in.."
        # Gets the first subscription ID in the list of available subs
        # NOTE: The sub being targeted in the 0 index may not correlate to others using this same command
        LOGIN_AND_GET_SUB=$(az login -u "$AZ_USERNAME" -p "$AZ_PASSWORD" --query "[[0].id]" -o tsv)
        echo "Setting subscription context to Subscription ID: $LOGIN_AND_GET_SUB.."
        az account set --subscription $LOGIN_AND_GET_SUB
        echo "Logged in.."
    fi
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

# Parent function
execute_func() {
    az_login
    az_create_webapp
}

# Main
execute_func
