# F5 Distributed Cloud configuration backup and restore
## Intro
The script allows to backup and restore XC configurations of HTTP and TCP Load Balancers and their components. The script can be added to the crontab for daily backups:
```
crontab -e
55 23 * * * /backup/f5_xc_backup_restore.sh backup <xc-tenant> <namespace/all> APIToken 
```

## Usage
### Backup
* Set required variables as command line arguments; api_token, tenant, namespace.
* Execute the script
  ```
  chmod +x f5_xc_backup_restore.sh
  ./f5_xc_backup_restore.sh backup <xc-tenant> <namespace/all> APIToken 
  ```
### Restore
* The restore only restores a single namespace - don't use 'all'.
* Set required variables as command line arguments; api_token, tenant, namespace.
* The script checks if the required configurations JSONs are present (health checks, origin pools and HTTP loadbalancers)
* Execute the script
  ```
  chmod +x f5_xc_backup_restore.sh
  ./f5_xc_backup_restore.sh as restore <xc-tenant> <namespace> APIToken
  ```
