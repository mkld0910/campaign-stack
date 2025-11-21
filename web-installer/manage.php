<?php
/**
 * Campaign Stack - Management Panel
 * Simple GUI for post-installation management
 */

$env_file = '../.env';
$is_installed = file_exists($env_file);

if (!$is_installed) {
    header('Location: index.php');
    exit;
}

// Load environment variables
$env_vars = parse_ini_file($env_file);
$public_domain = $env_vars['PUBLIC_DOMAIN'] ?? 'Not Set';
$backend_domain = $env_vars['BACKEND_DOMAIN'] ?? 'Not Set';
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Campaign Stack - Management Panel</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="container">
        <header>
            <h1>📊 Campaign Stack</h1>
            <p class="subtitle">Management Panel</p>
        </header>

        <div class="step-content active">
            <h2>System Status</h2>

            <div class="access-info">
                <h3>Your Services</h3>
                <a href="https://<?php echo htmlspecialchars($public_domain); ?>" target="_blank" class="access-link">
                    🌐 Public Website: <?php echo htmlspecialchars($public_domain); ?>
                </a>
                <a href="https://<?php echo htmlspecialchars($backend_domain); ?>/wp-admin" target="_blank" class="access-link">
                    🔧 WordPress Admin: <?php echo htmlspecialchars($backend_domain); ?>/wp-admin
                </a>
                <a href="http://<?php echo $_SERVER['HTTP_HOST']; ?>:9000" target="_blank" class="access-link">
                    📦 Portainer (Docker Management): Port 9000
                </a>
                <a href="https://wiki.<?php echo htmlspecialchars($public_domain); ?>" target="_blank" class="access-link">
                    📚 Wiki.js: wiki.<?php echo htmlspecialchars($public_domain); ?>
                </a>
            </div>

            <div class="form-section">
                <h3>Quick Actions</h3>

                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px; margin-top: 20px;">
                    <button onclick="checkServices()" class="btn btn-primary" style="width: 100%;">
                        🔍 Check Service Status
                    </button>

                    <button onclick="installCiviCRM()" class="btn btn-success" style="width: 100%;">
                        📊 Install CiviCRM
                    </button>

                    <button onclick="restartServices()" class="btn btn-secondary" style="width: 100%;">
                        🔄 Restart All Services
                    </button>

                    <button onclick="viewLogs()" class="btn btn-secondary" style="width: 100%;">
                        📋 View Docker Logs
                    </button>
                </div>
            </div>

            <div id="output-section" style="display: none;">
                <h3>Command Output</h3>
                <div class="terminal">
                    <pre id="command-output"></pre>
                </div>
            </div>

            <div class="next-steps">
                <h3>Documentation</h3>
                <ul style="list-style: none; padding: 0;">
                    <li><a href="https://github.com/mkld0910/campaign-stack" target="_blank">📖 Full Documentation</a></li>
                    <li><a href="../docs/SETUP.md" target="_blank">🔧 Setup Guide</a></li>
                    <li><a href="../docs/TROUBLESHOOTING.md" target="_blank">🐛 Troubleshooting</a></li>
                    <li><a href="../docs/BACKUP.md" target="_blank">💾 Backup Configuration</a></li>
                </ul>
            </div>

            <div class="alert alert-warning" style="margin-top: 30px;">
                <strong>🔒 Security Notice</strong>
                <p>For production use, remove or password-protect the web-installer directory:</p>
                <code>sudo rm -rf /srv/campaign-stack/web-installer</code>
            </div>
        </div>

        <footer>
            <p>Campaign Stack v2.3 | <a href="https://github.com/mkld0910/campaign-stack" target="_blank">GitHub</a></p>
        </footer>
    </div>

    <script>
        function showOutput(show = true) {
            document.getElementById('output-section').style.display = show ? 'block' : 'none';
        }

        function setOutput(text) {
            document.getElementById('command-output').textContent = text;
        }

        async function runAction(action, description) {
            showOutput(true);
            setOutput(`Running: ${description}...\n`);

            try {
                const response = await fetch('action.php?action=' + action);
                const text = await response.text();
                setOutput(text);
            } catch (error) {
                setOutput('Error: ' + error.message);
            }
        }

        function checkServices() {
            runAction('status', 'Check Service Status');
        }

        function restartServices() {
            if (confirm('Are you sure you want to restart all services? This will cause brief downtime.')) {
                runAction('restart', 'Restart Services');
            }
        }

        function viewLogs() {
            runAction('logs', 'View Recent Logs');
        }

        async function installCiviCRM() {
            if (!confirm('Install CiviCRM? This will take 3-5 minutes.')) {
                return;
            }

            showOutput(true);
            setOutput('Starting CiviCRM installation...\nThis may take several minutes.\n\n');

            try {
                const response = await fetch('action.php?action=civicrm');
                const reader = response.body.getReader();
                const decoder = new TextDecoder();

                while (true) {
                    const {done, value} = await reader.read();
                    if (done) break;

                    const chunk = decoder.decode(value);
                    document.getElementById('command-output').textContent += chunk;
                    document.getElementById('command-output').parentElement.scrollTop =
                        document.getElementById('command-output').parentElement.scrollHeight;
                }
            } catch (error) {
                setOutput('Error: ' + error.message);
            }
        }
    </script>
</body>
</html>
