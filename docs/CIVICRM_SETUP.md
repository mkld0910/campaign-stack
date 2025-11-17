# CiviCRM Installation Guide

## Quick Steps

1. Login to WordPress admin: `https://yourdomain.com/wp-admin`
2. Go to Plugins → Add New
3. Search for "CiviCRM"
4. Click Install → Activate
5. Go to WordPress admin → CiviCRM
6. Complete setup wizard

## Database Privileges

CiviCRM needs TRIGGER permission:
```bash
docker exec wordpress_mysql mysql -u root -p[PASSWORD] -e "GRANT TRIGGER ON wordpress_db.* TO 'wordpress_user'@'%'; FLUSH PRIVILEGES;"
```

Then restart WordPress:
```bash
docker-compose restart wordpress_app
```

## Test Data

Create test contacts/events/donations to verify it works.

Then restart containers and verify data persists.

