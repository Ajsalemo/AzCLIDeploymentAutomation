#!/bin/bash

# Username and password for non-interactive login
AZ_USERNAME=$1
AZ_PASSWORD=$2

# Deployment arguments
DEPLOYMENT_RESOURCE_GROUP=$3
DEPLOYMENT_APP_SERVICE_PLAN=$4
DEPLOYMENT_APP_NAME=$5
DEPLOYMENT_RUNTIME_TYPE=$6
DEPLOYMENT_SOURCE_TYPE=$7
ACR_IMAGE=$8

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
    if [[ -z "$DEPLOYMENT_RESOURCE_GROUP" || -z "$DEPLOYMENT_APP_SERVICE_PLAN" || -z "$DEPLOYMENT_APP_NAME" || -z "$DEPLOYMENT_RUNTIME_TYPE" ]]; then
        echo "ERROR: Missing arguments. Arguments provided must contain the Resource Group, App Service Plan, Web App Name and Runtime type"
        exit 1
    # If the deployment type is set to Git(local git) or is empty, also default to local git
    elif [[ "$DEPLOYMENT_SOURCE_TYPE" == "" || "$DEPLOYMENT_SOURCE_TYPE" == "git" || -z "$DEPLOYMENT_SOURCE_TYPE" ]]; then
        echo "Hello world"
        echo $DEPLOYMENT_RESOURCE_GROUP
        echo $DEPLOYMENT_APP_SERVICE_PLAN
        echo $DEPLOYMENT_APP_NAME
        echo $DEPLOYMENT_RUNTIME_TYPE
        echo $DEPLOYMENT_SOURCE_TYPE
        # az webapp create -g "$DEPLOYMENT_RESOURCE_GROUP" -p "$DEPLOYMENT_APP_SERVICE_PLAN" -n "$DEPLOYMENT_APP_NAME" --runtime "$DEPLOYMENT_RUNTIME_TYPE" --deployment-local-git
    # If the deployment type is set to ACR, run the creation command with ACR and the Image to provide
    elif [ "$DEPLOYMENT_SOURCE_TYPE" == "acr" ]; then
        if [ -z "$ACR_IMAGE" ]; then
            echo "No Azure Container Registry Image provided in arguments. Defaulting to none."
            # az webapp create -g "$DEPLOYMENT_RESOURCE_GROUP" -p "$DEPLOYMENT_APP_SERVICE_PLAN" -n "$DEPLOYMENT_APP_NAME" -i "$ACR_IMAGE"
        else
            echo "Creating a Web App for Containers instance with Image: $ACR_IMAGE"
            # az webapp create -g "$DEPLOYMENT_RESOURCE_GROUP" -p "$DEPLOYMENT_APP_SERVICE_PLAN" -n "$DEPLOYMENT_APP_NAME" -i "$ACR_IMAGE"
        fi
    else
        echo "An error has occurred."
    fi
}

execute_func() {
    az_login
    az_create_webapp
}

execute_func
