# Troubleshooting Guide

## Common Issues & Solutions

### 1. Website Not Accessible

**Symptom:** `Unable to connect` or connection refused

**Solutions:**

1. **Wait for SSL certificate** (most common)
   - Let's Encrypt takes 1-2 minutes
   - Wait, then refresh browser (Ctrl+Shift+R)

2. **Verify DNS points to VPS**
```bash
   nslookup yourdomain.com
```

3. **Check Traefik is running**
```bash
   docker-compose ps | grep traefik
```

### 2. WordPress Shows Blank Page

**Symptom:** Page loads but shows nothing

**Solutions:**

1. **Restart WordPress**
```bash
   docker-compose restart wordpress_app
   sleep 30
```

2. **Check WordPress logs**
```bash
   docker-compose logs wordpress_app | tail -50
```

### 3. MySQL Connection Error

**Symptom:** "Error establishing database connection"

**Solutions:**

1. **Check MySQL is running**
```bash
   docker-compose ps wordpress_mysql
```

2. **Test connection**
```bash
   docker exec wordpress_mysql mysql -u root -p[PASSWORD] -e "SELECT 1;"
```

### 4. CiviCRM Won't Install

**Symptom:** CiviCRM plugin errors

**Solutions:**

1. **Grant database privileges**
```bash
   docker exec wordpress_mysql mysql -u root -p[PASSWORD] -e "GRANT TRIGGER ON wordpress_db.* TO 'wordpress_user'@'%'; FLUSH PRIVILEGES;"
```

2. **Restart WordPress**
```bash
   docker-compose restart wordpress_app
   sleep 30
```

### 5. Backup Upload Fails

**Symptom:** Backup script errors

**Solutions:**

1. **Check Uplink CLI**
```bash
   uplink version
```

2. **Test Storj connection**
```bash
   uplink ls --access my-campaign-backup sj://campaign-backups-production/
```

3. **Check backup logs**
```bash
   tail -50 /var/log/campaign-backup.log
```

## Need More Help?

Open an issue on GitHub: https://github.com/mkld0910/campaign-stack/issues

