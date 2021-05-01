#!/bin/bash

AZ_USERNAME=$1
AZ_PASSWORD=$2

# Complete the initial log in non-interactively
az_login() {
    echo "Logging in.."
    # Gets the first subscription ID in the list of available subs
    LOGIN_AND_GET_SUB=$(az login -u "$AZ_USERNAME" -p "$AZ_PASSWORD" --query "[[0].id]" -o tsv) 
    echo "Setting subscription context to Subscription ID: $LOGIN_AND_GET_SUB.."
    az account set --subscription $LOGIN_AND_GET_SUB
    echo "Logged in.."
}

execute_func() {
    az_login
}

execute_func
