// Campaign Stack GUI Installer - Frontend JavaScript

let currentStep = 1;
let config = {};

// Initialize on page load
document.addEventListener('DOMContentLoaded', function() {
    // Domain type switching
    const domainRadios = document.getElementsByName('domain_type');
    domainRadios.forEach(radio => {
        radio.addEventListener('change', function() {
            document.getElementById('single-domain-fields').style.display =
                this.value === 'single' ? 'block' : 'none';
            document.getElementById('dual-domain-fields').style.display =
                this.value === 'dual' ? 'block' : 'none';
        });
    });

    // AI provider key field showing
    const aiRadios = document.getElementsByName('ai_provider');
    aiRadios.forEach(radio => {
        radio.addEventListener('change', function() {
            // Hide all API key fields
            document.getElementById('anthropic_key').style.display = 'none';
            document.getElementById('openai_key').style.display = 'none';
            document.getElementById('google_key').style.display = 'none';

            // Show relevant API key field
            if (this.value === 'anthropic') {
                document.getElementById('anthropic_key').style.display = 'block';
                document.getElementById('anthropic_key').required = true;
            } else if (this.value === 'openai') {
                document.getElementById('openai_key').style.display = 'block';
                document.getElementById('openai_key').required = true;
            } else if (this.value === 'google') {
                document.getElementById('google_key').style.display = 'block';
                document.getElementById('google_key').required = true;
            }
        });
    });

    // Button handlers
    document.getElementById('btn-check-prereqs')?.addEventListener('click', checkPrerequisites);
    document.getElementById('btn-next-1')?.addEventListener('click', () => goToStep(2));
    document.getElementById('btn-next-2')?.addEventListener('click', reviewConfig);
    document.getElementById('btn-install')?.addEventListener('click', startInstallation);
});

function goToStep(step) {
    // Hide current step
    document.querySelectorAll('.step-content').forEach(el => el.classList.remove('active'));
    document.querySelectorAll('.progress-steps .step').forEach(el => el.classList.remove('active'));

    // Mark completed steps
    for (let i = 1; i < step; i++) {
        document.querySelector(`.progress-steps .step[data-step="${i}"]`)?.classList.add('completed');
    }

    // Show new step
    document.getElementById(`step${step}`).classList.add('active');
    document.querySelector(`.progress-steps .step[data-step="${step}"]`).classList.add('active');

    currentStep = step;
    window.scrollTo(0, 0);
}

async function checkPrerequisites() {
    const button = document.getElementById('btn-check-prereqs');
    button.disabled = true;
    button.textContent = 'Checking...';

    try {
        const response = await fetch('check-prereqs.php');
        const result = await response.json();

        // Update Docker check
        updateCheckItem('check-docker', result.docker);

        // Update Docker Compose check
        updateCheckItem('check-compose', result.compose);

        // Update permissions check
        updateCheckItem('check-permissions', result.permissions);

        if (result.docker.success && result.compose.success && result.permissions.success) {
            document.getElementById('btn-next-1').style.display = 'inline-block';
            button.textContent = '✓ All Checks Passed';
            button.classList.remove('btn-primary');
            button.classList.add('btn-success');
        } else {
            button.textContent = '✗ Prerequisites Failed';
            button.classList.remove('btn-primary');
            button.classList.add('btn-secondary');
            button.disabled = false;
        }
    } catch (error) {
        console.error('Error checking prerequisites:', error);
        alert('Error checking prerequisites. See console for details.');
        button.disabled = false;
        button.textContent = 'Retry Prerequisites Check';
    }
}

function updateCheckItem(id, result) {
    const el = document.getElementById(id);
    el.className = 'check-item ' + (result.success ? 'success' : 'error');
    el.innerHTML = (result.success ? '✓' : '✗') + ' ' + result.message;
}

function reviewConfig() {
    // Gather configuration
    const form = document.getElementById('config-form');
    const formData = new FormData(form);

    config = {
        domain_type: formData.get('domain_type'),
        email: formData.get('email'),
        ai_provider: formData.get('ai_provider')
    };

    // Validate
    if (!config.email) {
        alert('Please enter an email address.');
        return;
    }

    if (config.domain_type === 'single') {
        config.domain = formData.get('domain');
        if (!config.domain) {
            alert('Please enter a domain name.');
            return;
        }
        config.public_domain = config.domain;
        config.backend_domain = config.domain;
    } else {
        config.public_domain = formData.get('public_domain');
        config.backend_domain = formData.get('backend_domain');
        if (!config.public_domain || !config.backend_domain) {
            alert('Please enter both public and backend domains.');
            return;
        }
        config.domain = config.public_domain;
    }

    // Get API keys if needed
    if (config.ai_provider === 'anthropic') {
        config.ai_key = formData.get('anthropic_key');
        if (!config.ai_key) {
            alert('Please enter your Anthropic API key.');
            return;
        }
    } else if (config.ai_provider === 'openai') {
        config.ai_key = formData.get('openai_key');
        if (!config.ai_key) {
            alert('Please enter your OpenAI API key.');
            return;
        }
    } else if (config.ai_provider === 'google') {
        config.ai_key = formData.get('google_key');
        if (!config.ai_key) {
            alert('Please enter your Google API key.');
            return;
        }
    }

    // Display review
    let reviewHTML = '<div class="review-item"><div class="review-label">Domain Configuration</div>';
    if (config.domain_type === 'single') {
        reviewHTML += `<div class="review-value">Single Domain: ${config.domain}</div></div>`;
    } else {
        reviewHTML += `<div class="review-value">Public: ${config.public_domain}<br>Backend: ${config.backend_domain}</div></div>`;
    }

    reviewHTML += `<div class="review-item"><div class="review-label">Email</div><div class="review-value">${config.email}</div></div>`;

    if (config.ai_provider !== 'none') {
        const aiNames = {
            'anthropic': 'Anthropic Claude',
            'openai': 'OpenAI ChatGPT',
            'google': 'Google Gemini',
            'ollama': 'Local Ollama'
        };
        reviewHTML += `<div class="review-item"><div class="review-label">AI Provider</div><div class="review-value">${aiNames[config.ai_provider]}</div></div>`;
    }

    document.getElementById('review-content').innerHTML = reviewHTML;
    goToStep(3);
}

async function startInstallation() {
    const button = document.getElementById('btn-install');
    const backButton = document.getElementById('btn-back-3');

    button.disabled = true;
    button.textContent = 'Installing...';
    backButton.style.display = 'none';

    document.getElementById('installation-output').style.display = 'block';
    const log = document.getElementById('install-log');

    try {
        const response = await fetch('install.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(config)
        });

        const reader = response.body.getReader();
        const decoder = new TextDecoder();

        while (true) {
            const {done, value} = await reader.read();
            if (done) break;

            const chunk = decoder.decode(value);
            log.textContent += chunk;
            log.parentElement.scrollTop = log.parentElement.scrollHeight;
        }

        // Installation complete
        button.textContent = '✓ Installation Complete';
        button.classList.remove('btn-primary');
        button.classList.add('btn-success');

        // Prepare access links
        let accessHTML = '';
        if (config.domain_type === 'single') {
            accessHTML = `
                <a href="https://${config.domain}" target="_blank" class="access-link">🌐 Visit Website: ${config.domain}</a>
                <a href="https://${config.domain}/wp-admin" target="_blank" class="access-link">🔧 WordPress Admin: ${config.domain}/wp-admin</a>
            `;
        } else {
            accessHTML = `
                <a href="https://${config.public_domain}" target="_blank" class="access-link">🌐 Public Website: ${config.public_domain}</a>
                <a href="https://${config.backend_domain}/wp-admin" target="_blank" class="access-link">🔧 WordPress Admin: ${config.backend_domain}/wp-admin</a>
            `;
        }
        accessHTML += `<a href="http://${window.location.hostname}:9000" target="_blank" class="access-link">📦 Portainer: Port 9000</a>`;

        document.getElementById('access-links').innerHTML = accessHTML;

        // Move to completion step after a short delay
        setTimeout(() => goToStep(4), 2000);

    } catch (error) {
        console.error('Installation error:', error);
        log.textContent += '\n\n❌ ERROR: Installation failed. See console for details.\n';
        button.textContent = '✗ Installation Failed';
        button.disabled = false;
        backButton.style.display = 'inline-block';
    }
}
