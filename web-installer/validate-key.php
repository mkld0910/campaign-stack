<?php
/**
 * API Key Validation - Web Installer
 * Validates AI provider API keys via AJAX
 */

header('Content-Type: application/json');

$provider = $_POST['provider'] ?? '';
$api_key = $_POST['api_key'] ?? '';

if (empty($provider) || empty($api_key)) {
    echo json_encode([
        'valid' => false,
        'message' => 'Missing provider or API key'
    ]);
    exit;
}

// Call the validation script
$repo_dir = dirname(__DIR__);
$script_path = $repo_dir . '/scripts/validate-api-key.sh';

if (!file_exists($script_path)) {
    echo json_encode([
        'valid' => false,
        'message' => 'Validation script not found'
    ]);
    exit;
}

// Execute validation script
$command = sprintf(
    'bash %s %s %s 2>&1',
    escapeshellarg($script_path),
    escapeshellarg($provider),
    escapeshellarg($api_key)
);

exec($command, $output, $return_code);

$output_text = implode("\n", $output);

// Return codes: 0 = valid, 1 = invalid, 2 = network error
if ($return_code === 0) {
    echo json_encode([
        'valid' => true,
        'message' => 'API key is valid',
        'output' => $output_text
    ]);
} elseif ($return_code === 1) {
    echo json_encode([
        'valid' => false,
        'message' => 'Invalid API key',
        'output' => $output_text
    ]);
} else {
    echo json_encode([
        'valid' => null,
        'message' => 'Network error - cannot validate',
        'output' => $output_text
    ]);
}
