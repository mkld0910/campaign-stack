<?php
/**
 * Campaign Stack - Web-Based GUI Installer
 * For users who prefer a graphical interface over command line
 */

// Security: Only allow access from localhost or specific IPs during installation
$allowed_ips = ['127.0.0.1', '::1'];
$client_ip = $_SERVER['REMOTE_ADDR'] ?? '';

// For production, uncomment this security check:
// if (!in_array($client_ip, $allowed_ips)) {
//     die('Access denied. GUI installer only accessible from localhost.');
// }

// Check if already installed
$env_file = '../.env';
$already_installed = file_exists($env_file);

?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Campaign Stack - GUI Installer</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="container">
        <header>
            <h1>🚀 Campaign Stack</h1>
            <p class="subtitle">Web-Based GUI Installer</p>
        </header>

        <?php if ($already_installed): ?>
            <div class="alert alert-warning">
                <strong>⚠️ Installation Detected</strong>
                <p>A .env file already exists. This suggests Campaign Stack is already installed.</p>
                <p>To reinstall, please run the cleanup script first:</p>
                <code>bash cleanup-and-reset.sh</code>
            </div>
            <div class="nav-buttons">
                <a href="manage.php" class="btn btn-primary">Go to Management Panel</a>
            </div>
        <?php else: ?>

        <div class="progress-steps">
            <div class="step active" data-step="1">
                <div class="step-number">1</div>
                <div class="step-label">Prerequisites</div>
            </div>
            <div class="step" data-step="2">
                <div class="step-number">2</div>
                <div class="step-label">Configuration</div>
            </div>
            <div class="step" data-step="3">
                <div class="step-number">3</div>
                <div class="step-label">Installation</div>
            </div>
            <div class="step" data-step="4">
                <div class="step-number">4</div>
                <div class="step-label">Complete</div>
            </div>
        </div>

        <div id="step1" class="step-content active">
            <h2>Step 1: Prerequisites Check</h2>
            <p>Checking if your system meets the requirements...</p>

            <div class="check-list">
                <div class="check-item" id="check-docker">
                    <span class="spinner">⏳</span> Checking Docker...
                </div>
                <div class="check-item" id="check-compose">
                    <span class="spinner">⏳</span> Checking Docker Compose...
                </div>
                <div class="check-item" id="check-permissions">
                    <span class="spinner">⏳</span> Checking file permissions...
                </div>
            </div>

            <div class="nav-buttons">
                <button id="btn-check-prereqs" class="btn btn-primary">Run Prerequisites Check</button>
                <button id="btn-next-1" class="btn btn-success" style="display:none;">Continue to Configuration →</button>
            </div>
        </div>

        <div id="step2" class="step-content">
            <h2>Step 2: Configure Your Campaign</h2>
            <form id="config-form">
                <div class="form-section">
                    <h3>Domain Configuration</h3>

                    <div class="form-group">
                        <label>
                            <input type="radio" name="domain_type" value="single" checked>
                            Single Domain (default)
                        </label>
                        <p class="help-text">Same domain for public site and admin (e.g., janedoeforcongress.com)</p>
                    </div>

                    <div class="form-group">
                        <label>
                            <input type="radio" name="domain_type" value="dual">
                            Dual Domain (advanced)
                        </label>
                        <p class="help-text">Separate domains for public site and admin backend</p>
                    </div>

                    <div id="single-domain-fields">
                        <div class="form-group">
                            <label for="domain">Domain Name *</label>
                            <input type="text" id="domain" name="domain" placeholder="janedoeforcongress.com" required>
                            <p class="help-text">Your campaign website domain</p>
                        </div>
                    </div>

                    <div id="dual-domain-fields" style="display:none;">
                        <div class="form-group">
                            <label for="public_domain">Public Domain *</label>
                            <input type="text" id="public_domain" name="public_domain" placeholder="janedoeforcongress.com">
                            <p class="help-text">What visitors see</p>
                        </div>

                        <div class="form-group">
                            <label for="backend_domain">Backend Domain *</label>
                            <input type="text" id="backend_domain" name="backend_domain" placeholder="admin.it.com">
                            <p class="help-text">Admin interface URL</p>
                        </div>
                    </div>

                    <div class="form-group">
                        <label for="email">Email Address *</label>
                        <input type="email" id="email" name="email" placeholder="admin@janedoeforcongress.com" required>
                        <p class="help-text">For SSL certificates from Let's Encrypt</p>
                    </div>
                </div>

                <div class="form-section">
                    <h3>AI Provider (Optional)</h3>

                    <div class="form-group">
                        <label>
                            <input type="radio" name="ai_provider" value="none" checked>
                            Skip AI Provider
                        </label>
                        <p class="help-text">Don't install any AI CLI tool (recommended for simplicity)</p>
                    </div>

                    <div class="form-group">
                        <label>
                            <input type="radio" name="ai_provider" value="anthropic">
                            Anthropic Claude
                        </label>
                        <p class="help-text">Most capable, ~$3-15 per 1M tokens</p>
                        <input type="password" id="anthropic_key" name="anthropic_key" placeholder="sk-ant-..." style="display:none; margin-top: 8px;">
                    </div>

                    <div class="form-group">
                        <label>
                            <input type="radio" name="ai_provider" value="openai">
                            OpenAI ChatGPT
                        </label>
                        <p class="help-text">Powerful, ~$0.50-60 per 1M tokens</p>
                        <input type="password" id="openai_key" name="openai_key" placeholder="sk-..." style="display:none; margin-top: 8px;">
                    </div>

                    <div class="form-group">
                        <label>
                            <input type="radio" name="ai_provider" value="google">
                            Google Gemini
                        </label>
                        <p class="help-text">Cheapest, ~$0.25-0.50 per 1M tokens</p>
                        <input type="password" id="google_key" name="google_key" placeholder="API key..." style="display:none; margin-top: 8px;">
                    </div>

                    <div class="form-group">
                        <label>
                            <input type="radio" name="ai_provider" value="ollama">
                            Local Ollama
                        </label>
                        <p class="help-text">FREE, runs offline on your server</p>
                    </div>
                </div>

                <div class="nav-buttons">
                    <button type="button" class="btn btn-secondary" onclick="goToStep(1)">← Back</button>
                    <button type="button" id="btn-next-2" class="btn btn-success">Review Installation →</button>
                </div>
            </form>
        </div>

        <div id="step3" class="step-content">
            <h2>Step 3: Review & Install</h2>

            <div class="review-section">
                <h3>Configuration Summary</h3>
                <div id="review-content"></div>
            </div>

            <div id="installation-output" style="display:none;">
                <h3>Installation Progress</h3>
                <div class="terminal">
                    <pre id="install-log"></pre>
                </div>
            </div>

            <div class="nav-buttons">
                <button type="button" class="btn btn-secondary" onclick="goToStep(2)" id="btn-back-3">← Back</button>
                <button type="button" id="btn-install" class="btn btn-primary btn-large">🚀 Start Installation</button>
            </div>
        </div>

        <div id="step4" class="step-content">
            <h2>🎉 Installation Complete!</h2>

            <div class="success-message">
                <p>Your Campaign Stack is now deployed and ready to use!</p>
            </div>

            <div class="access-info">
                <h3>Access Your Services</h3>
                <div id="access-links"></div>
            </div>

            <div class="next-steps">
                <h3>Next Steps</h3>
                <ol>
                    <li>Wait 1-2 minutes for SSL certificates to be issued</li>
                    <li>Visit your WordPress site and complete the setup</li>
                    <li>Install CiviCRM (optional): <code>bash scripts/install-civicrm.sh</code></li>
                    <li>Configure backups and email settings</li>
                </ol>
            </div>

            <div class="nav-buttons">
                <a href="manage.php" class="btn btn-primary">Go to Management Panel</a>
                <button type="button" class="btn btn-secondary" onclick="window.location.reload()">Close Installer</button>
            </div>
        </div>

        <?php endif; ?>

        <footer>
            <p>Campaign Stack v2.3 | <a href="https://github.com/mkld0910/campaign-stack" target="_blank">Documentation</a></p>
            <p class="security-note">🔒 For security, disable this installer after setup by removing the web-installer directory</p>
        </footer>
    </div>

    <script src="script.js"></script>
</body>
</html>
