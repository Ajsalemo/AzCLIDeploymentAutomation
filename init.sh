#!/bin/bash

# Username and password for non-interactive login
AZ_USERNAME=$1
AZ_PASSWORD=$2

# Deployment arguments
DEPLOYMENT_RESOURCE_GROUP=$3
DEPLOYMENT_APP_SERVICE_PLAN=$4
DEPLOYMENT_APP_NAME=$5
DEPLOYMENT_RUNTIME_TYPE=$6

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
    if [[ -z "$DEPLOYMENT_RESOURCE_GROUP" || -z "$DEPLOYMENT_APP_SERVICE_PLAN" || -z "$DEPLOYMENT_APP_NAME" || -z "$DEPLOYMENT_RUNTIME_TYPE" ]]; then
        echo "ERROR: Missing arguments. Arguments provided must contain the Resource Group, App Service Plan, Web App Name and Runtime type"
        exit 1
    else
        echo "Hello world"
        echo $DEPLOYMENT_RESOURCE_GROUP
        echo $DEPLOYMENT_APP_SERVICE_PLAN
        echo $DEPLOYMENT_APP_NAME
        echo $DEPLOYMENT_RUNTIME_TYPE
    fi
    # az webapp create -g "$DEPLOYMENT_RESOURCE_GROUP" -p "$DEPLOYMENT_APP_SERVICE_PLAN" -n "$DEPLOYMENT_APP_NAME" --runtime "$DEPLOYMENT_RUNTIME_TYPE" --deployment-local-git
}

execute_func() {
    az_login
    az_create_webapp
}

execute_func
