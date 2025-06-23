#!/bin/bash

tenant=$2
namespace_provider=$3
api_token=$4

# Generate timestamp
timestamp=$(date +"%Y%m%d")

# Set log file path with timestamp
log_file="script_log_${timestamp}.txt"
> $log_file

# Function to log messages
log() {
    echo "$(date +"%Y-%m-%d %T") $1" >> "$log_file"
}

# Check if the number of arguments provided is equal to 4
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 [backup/restore xc-tenant namespace APITOKEN]"
    log "Usage: $0 [backup/restore xc-tenant namespace APITOKEN]"
    exit 1
fi

# Check if the first argument provided is either "backup" or "restore"
if [ "$1" != "backup" ] && [ "$1" != "restore" ]; then
    echo "Error: Invalid argument. Please provide 'backup' or 'restore'."
    log "Error: Invalid argument. Please provide 'backup' or 'restore'."
    exit 1
fi

# Retrieve namespaces based on input
if [ "$namespace_provider" == "all" ]; then
    response=$(curl -s -o /dev/null -w "%{http_code}" -X GET -H "Authorization: APIToken $api_token" "https://$tenant.console.ves.volterra.io/api/web/namespaces")
    
    if [ "$response" -ne 200 ]; then
        log "Error: Unable to connect to the namespaces API, HTTP status code $response"
        exit 1
    fi

    namespaces=$(curl -s -X GET -H "Authorization: APIToken $api_token" "https://$tenant.console.ves.volterra.io/api/web/namespaces" | jq -r .[][].name)
    log "Collecting data from all namespaces"
elif [ -n "$namespace_provider" ]; then
    namespaces=$namespace_provider
    log "Starting data collection for specific namespace: $namespaces"
else
    log "No namespace provided! Use 'all' for all namespaces or specify a single namespace."
    exit 1
fi

log "Starting data collection."
# Loop through each namespace 
for namespace in $namespaces; do
    # Script specific directories
    load_balancers_dir="./${namespace}/load_balancers-${namespace}"
    tcp_load_balancers_dir="./${namespace}/tcp_load_balancers-${namespace}"
    origin_pools_dir="./${namespace}/origin_pools-${namespace}"
    health_checks_dir="./${namespace}/health_checks-${namespace}"
    service_policies_dir="./${namespace}/service_policies-${namespace}"
    app_firewalls_dir="./${namespace}/app_firewalls-${namespace}"

    log "Starting data collection from namespace: $namespace"
    mkdir -p $load_balancers_dir $tcp_load_balancers_dir $origin_pools_dir $health_checks_dir $service_policies_dir $app_firewalls_dir
    echo "Working directories created successfully for namespace: $namespace"
    log "Working directories created successfully for namespace: $namespace"

    load_balancers_list="$(curl -s -X GET -H "Authorization: APIToken $api_token" https://$tenant.console.ves.volterra.io/api/config/namespaces/$namespace/http_loadbalancers | jq -r .[][].name)"
    tcp_load_balancers_list="$(curl -s -X GET -H "Authorization: APIToken $api_token" https://$tenant.console.ves.volterra.io/api/config/namespaces/$namespace/tcp_loadbalancers | jq -r .[][].name)"
    origin_pools_list="$(curl -s -X GET -H "Authorization: APIToken $api_token" https://$tenant.console.ves.volterra.io/api/config/namespaces/$namespace/origin_pools | jq -r .[][].name)"
    health_checks_list="$(curl -s -X GET -H "Authorization: APIToken $api_token" https://$tenant.console.ves.volterra.io/api/config/namespaces/$namespace/healthchecks | jq -r .[][].name)"
    service_policies_list="$(curl -s -X GET -H "Authorization: APIToken $api_token" https://$tenant.console.ves.volterra.io/api/config/namespaces/$namespace/service_policys | jq -r '.items[] | select(.namespace != "shared") | .name')"
    app_firewalls_list="$(curl -s -X GET -H "Authorization: APIToken $api_token" https://$tenant.console.ves.volterra.io/api/config/namespaces/$namespace/app_firewalls | jq -r '.items[] | select(.namespace != "shared") | .name')"

    if [ "$1" = "backup" ]; then
        log "=== Starting Backup for namespace: $namespace ==="
        for load_balancer in $load_balancers_list; do
            log "Backing up HTTP Load Balancer: $load_balancer"
            echo "Backing up HTTP Load Balancer: $load_balancer"
            curl -s -X GET -H "Authorization: APIToken $api_token" https://$tenant.console.ves.volterra.io/api/config/namespaces/$namespace/http_loadbalancers/$load_balancer | jq 'del(.resource_version)' > $load_balancers_dir/$load_balancer.json
        done
        for tcp_load_balancer in $tcp_load_balancers_list; do
            log "Backing up TCP Load Balancer: $tcp_load_balancer"
            echo "Backing up TCP Load Balancer: $tcp_load_balancer"
            curl -s -X GET -H "Authorization: APIToken $api_token" https://$tenant.console.ves.volterra.io/api/config/namespaces/$namespace/tcp_loadbalancers/$tcp_load_balancer | jq 'del(.resource_version)' > $tcp_load_balancers_dir/$tcp_load_balancer.json
        done
        for origin_pool in $origin_pools_list; do
            log "Backing up Origin Pool: $origin_pool"
            echo "Backing up Origin Pool: $origin_pool"
            curl -s -X GET -H "Authorization: APIToken $api_token" https://$tenant.console.ves.volterra.io/api/config/namespaces/$namespace/origin_pools/$origin_pool | jq 'del(.resource_version)' > $origin_pools_dir/$origin_pool.json
        done
        for health_check in $health_checks_list; do
            log "Backing up Health Check: $health_check"
            echo "Backing up Health Check: $health_check"
            curl -s -X GET -H "Authorization: APIToken $api_token" https://$tenant.console.ves.volterra.io/api/config/namespaces/$namespace/healthchecks/$health_check | jq 'del(.resource_version)' > $health_checks_dir/$health_check.json
        done
        for service_policy in $service_policies_list; do
            log "Backing up Service Policy: $service_policy"
            echo "Backing up Service Policy: $service_policy"
            curl -s -X GET -H "Authorization: APIToken $api_token" https://$tenant.console.ves.volterra.io/api/config/namespaces/$namespace/service_policys/$service_policy | jq 'del(.resource_version)' > $service_policies_dir/$service_policy.json
        done
        for app_firewall in $app_firewalls_list; do
            log "Backing up App Firewall: $app_firewall"
            echo "Backing up App Firewall: $app_firewall"
            curl -s -X GET -H "Authorization: APIToken $api_token" https://$tenant.console.ves.volterra.io/api/config/namespaces/$namespace/app_firewalls/$app_firewall | jq 'del(.resource_version)' > $app_firewalls_dir/$app_firewall.json
        done
    fi

    if [ "$1" = "restore" ]; then
        log "=== Starting Restore for namespace: $namespace ==="
        echo "=== Starting Restore for namespace: $namespace ==="
        if [ "$3" = "all" ]; then
        echo "Illegal argument "ALL" for restore. Use specific namespace!"
        log "Illegal argument "ALL" for restore. Use specific namespace!"
        exit 1
        fi
        for dir in "$health_checks_dir" "$origin_pools_dir" "$load_balancers_dir"; do
            if ! compgen -G "$dir/*.json" > /dev/null; then
                echo "!!! FOLDER $dir DOES NOT CONTAIN ANY .json FILES, ABORTING !!!"
                log "!!! FOLDER $dir DOES NOT CONTAIN ANY .json FILES, ABORTING !!!"
                exit 1
            fi
        done
    
        for f in "$health_checks_dir"/*.json; do
            name=$(jq -r '.metadata.name' "$f")
            log "Restoring Health Check: $name"
            echo "Restoring Health Check: $name"
            curl -s -X POST -H "Authorization: APIToken $api_token" https://$tenant.console.ves.volterra.io/api/config/namespaces/$namespace/healthchecks -d "@$f"
        done
        for f in "$origin_pools_dir"/*.json; do
            name=$(jq -r '.metadata.name' "$f")
            log "Restoring Origin Pool: $name"
            echo "Restoring Origin Pool: $name"
            curl -s -X POST -H "Authorization: APIToken $api_token" https://$tenant.console.ves.volterra.io/api/config/namespaces/$namespace/origin_pools -d "@$f"
        done
        for f in "$service_policies_dir"/*.json; do
            name=$(jq -r '.metadata.name' "$f")
            log "Restoring Service Policy: $name"
            echo "Restoring Service Policy: $name"
            curl -s -X POST -H "Authorization: APIToken $api_token" https://$tenant.console.ves.volterra.io/api/config/namespaces/$namespace/service_policys -d "@$f"
        done
        for f in "$app_firewalls_dir"/*.json; do
            name=$(jq -r '.metadata.name' "$f")
            log "Restoring App Firewall: $name"
            echo "Restoring App Firewall: $name"
            curl -s -X POST -H "Authorization: APIToken $api_token" https://$tenant.console.ves.volterra.io/api/config/namespaces/$namespace/app_firewalls -d "@$f"
        done
        for f in "$tcp_load_balancers_dir"/*.json; do
            name=$(jq -r '.metadata.name' "$f")
            log "Restoring TCP Load Balancer: $name"
            echo "Restoring TCP Load Balancer: $name"
            curl -s -X POST -H "Authorization: APIToken $api_token" https://$tenant.console.ves.volterra.io/api/config/namespaces/$namespace/tcp_loadbalancers -d "@$f"
        done
        for f in "$load_balancers_dir"/*.json; do
            name=$(jq -r '.metadata.name' "$f")
            log "Restoring HTTP Load Balancer: $name"
            echo "Restoring HTTP Load Balancer: $name"
            curl -s -X POST -H "Authorization: APIToken $api_token" https://$tenant.console.ves.volterra.io/api/config/namespaces/$namespace/http_loadbalancers -d "@$f"
        done
    fi
done
