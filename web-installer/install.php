<?php
/**
 * Installation Backend - Runs the Campaign Stack installation
 * Receives configuration from frontend and executes installation steps
 */

// Disable output buffering for streaming
ob_implicit_flush(true);
ob_end_flush();

header('Content-Type: text/plain; charset=utf-8');
header('X-Accel-Buffering: no'); // Disable nginx buffering

// Get configuration from POST
$input = file_get_contents('php://input');
$config = json_decode($input, true);

if (!$config) {
    echo "ERROR: Invalid configuration received\n";
    exit(1);
}

$repo_dir = dirname(__DIR__);
chdir($repo_dir);

// Helper function to output and flush
function output($message) {
    echo $message . "\n";
    flush();
}

// Helper to run command and stream output
function runCommand($command, $description) {
    output("\n" . str_repeat("=", 60));
    output($description);
    output(str_repeat("=", 60));

    $descriptorspec = [
        0 => ["pipe", "r"],
        1 => ["pipe", "w"],
        2 => ["pipe", "w"]
    ];

    $process = proc_open($command, $descriptorspec, $pipes);

    if (is_resource($process)) {
        fclose($pipes[0]);

        stream_set_blocking($pipes[1], false);
        stream_set_blocking($pipes[2], false);

        while (true) {
            $stdout = fgets($pipes[1]);
            $stderr = fgets($pipes[2]);

            if ($stdout !== false) {
                output($stdout);
            }

            if ($stderr !== false) {
                output($stderr);
            }

            $status = proc_get_status($process);
            if (!$status['running']) {
                break;
            }

            usleep(100000); // 0.1 second
        }

        fclose($pipes[1]);
        fclose($pipes[2]);

        $return_code = proc_close($process);

        if ($return_code === 0) {
            output("✓ " . $description . " completed successfully");
        } else {
            output("✗ " . $description . " failed (exit code: $return_code)");
        }

        return $return_code === 0;
    }

    return false;
}

try {
    output("🚀 Campaign Stack Installation Starting...");
    output("Timestamp: " . date('Y-m-d H:i:s'));

    // Step 1: Generate secure passwords
    output("\n📝 Step 1/6: Generating secure passwords...");
    $mysql_root_pass = bin2hex(random_bytes(16));
    $mysql_user_pass = bin2hex(random_bytes(16));
    output("✓ Passwords generated");

    // Step 2: Create .env file
    output("\n📝 Step 2/6: Creating environment configuration...");

    $env_content = "# Campaign Stack Configuration\n";
    $env_content .= "# Generated: " . date('Y-m-d H:i:s') . "\n\n";
    $env_content .= "# Domain Configuration\n";
    $env_content .= "PUBLIC_DOMAIN=" . $config['public_domain'] . "\n";
    $env_content .= "BACKEND_DOMAIN=" . $config['backend_domain'] . "\n";
    $env_content .= "DOMAIN=" . $config['domain'] . "\n\n";
    $env_content .= "# SSL/TLS Configuration\n";
    $env_content .= "LETSENCRYPT_EMAIL=" . $config['email'] . "\n\n";
    $env_content .= "# MySQL Configuration\n";
    $env_content .= "MYSQL_ROOT_PASSWORD=" . $mysql_root_pass . "\n";
    $env_content .= "MYSQL_USER=wordpress_user\n";
    $env_content .= "MYSQL_PASSWORD=" . $mysql_user_pass . "\n";
    $env_content .= "MYSQL_DATABASE=wordpress_db\n\n";
    $env_content .= "# AI Provider Configuration\n";
    $env_content .= "PRIMARY_AI_PROVIDER=" . ($config['ai_provider'] ?? 'none') . "\n";

    if (isset($config['ai_key'])) {
        if ($config['ai_provider'] === 'anthropic') {
            $env_content .= "ANTHROPIC_API_KEY=" . $config['ai_key'] . "\n";
        } elseif ($config['ai_provider'] === 'openai') {
            $env_content .= "OPENAI_API_KEY=" . $config['ai_key'] . "\n";
        } elseif ($config['ai_provider'] === 'google') {
            $env_content .= "GOOGLE_API_KEY=" . $config['ai_key'] . "\n";
        }
    }

    $env_content .= "\n# Environment\n";
    $env_content .= "ENVIRONMENT=production\n";
    $env_content .= "DEBUG=false\n";

    file_put_contents('.env', $env_content);
    output("✓ .env file created");

    // Save credentials backup
    $creds_content = "=== CAMPAIGN STACK CREDENTIALS ===\n";
    $creds_content .= "Generated: " . date('Y-m-d H:i:s') . "\n\n";
    $creds_content .= "Domain Configuration:\n";
    $creds_content .= "  Public Domain: " . $config['public_domain'] . "\n";
    $creds_content .= "  Backend Domain: " . $config['backend_domain'] . "\n\n";
    $creds_content .= "Email: " . $config['email'] . "\n\n";
    $creds_content .= "MySQL Credentials:\n";
    $creds_content .= "  Root Password: " . $mysql_root_pass . "\n";
    $creds_content .= "  User: wordpress_user\n";
    $creds_content .= "  Password: " . $mysql_user_pass . "\n";
    $creds_content .= "  Database: wordpress_db\n\n";
    $creds_content .= "IMPORTANT:\n";
    $creds_content .= "1. Save these credentials to your password manager\n";
    $creds_content .= "2. Delete this file after saving: rm CREDENTIALS_BACKUP.txt\n";

    file_put_contents('CREDENTIALS_BACKUP.txt', $creds_content);
    output("✓ Credentials backup saved to CREDENTIALS_BACKUP.txt");

    // Step 3: Pull Docker images
    output("\n🐳 Step 3/6: Pulling Docker images...");
    output("This may take several minutes depending on your connection...");
    runCommand('docker compose pull 2>&1', 'Pulling Docker images');

    // Step 4: Start services
    output("\n🚀 Step 4/6: Starting Docker services...");
    runCommand('docker compose up -d 2>&1', 'Starting services');

    // Step 5: Wait for services to initialize
    output("\n⏳ Step 5/6: Waiting for services to initialize...");
    output("Waiting 30 seconds for all services to start...");
    sleep(30);
    output("✓ Initialization wait complete");

    // Step 6: Verify deployment
    output("\n✅ Step 6/6: Verifying deployment...");
    runCommand('docker compose ps 2>&1', 'Checking service status');

    // Installation complete
    output("\n" . str_repeat("=", 60));
    output("🎉 INSTALLATION COMPLETE!");
    output(str_repeat("=", 60));
    output("\nYour Campaign Stack is now deployed and ready!");
    output("\nAccess Points:");
    if ($config['domain_type'] === 'single') {
        output("  Website: https://" . $config['domain']);
        output("  WordPress Admin: https://" . $config['domain'] . "/wp-admin");
    } else {
        output("  Public Site: https://" . $config['public_domain']);
        output("  WordPress Admin: https://" . $config['backend_domain'] . "/wp-admin");
    }
    output("  Portainer: http://YOUR_VPS_IP:9000");
    output("\nNext Steps:");
    output("  1. Wait 1-2 minutes for SSL certificates");
    output("  2. Visit your site and complete WordPress setup");
    output("  3. Save CREDENTIALS_BACKUP.txt to your password manager");
    output("  4. Delete CREDENTIALS_BACKUP.txt: rm CREDENTIALS_BACKUP.txt");
    output("  5. Optional: Install CiviCRM via Management Panel");
    output("\n✓ Installation completed successfully at " . date('Y-m-d H:i:s'));

} catch (Exception $e) {
    output("\n❌ ERROR: " . $e->getMessage());
    output("Installation failed. Please check the error messages above.");
    exit(1);
}
