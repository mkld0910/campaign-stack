<?php
/**
 * Prerequisites Check - Backend
 * Checks Docker, Docker Compose, and file permissions
 */

header('Content-Type: application/json');

$result = [
    'docker' => checkDocker(),
    'compose' => checkDockerCompose(),
    'permissions' => checkPermissions()
];

echo json_encode($result);

function checkDocker() {
    exec('docker --version 2>&1', $output, $return_code);

    if ($return_code === 0) {
        return [
            'success' => true,
            'message' => 'Docker installed: ' . trim($output[0])
        ];
    }

    return [
        'success' => false,
        'message' => 'Docker not found. Please install Docker first.'
    ];
}

function checkDockerCompose() {
    exec('docker compose version 2>&1', $output, $return_code);

    if ($return_code === 0) {
        return [
            'success' => true,
            'message' => 'Docker Compose installed: ' . trim($output[0])
        ];
    }

    return [
        'success' => false,
        'message' => 'Docker Compose not found. Please install Docker Compose V2.'
    ];
}

function checkPermissions() {
    $repo_dir = dirname(__DIR__);

    // Check if we can read compose.yaml
    if (!is_readable($repo_dir . '/compose.yaml')) {
        return [
            'success' => false,
            'message' => 'Cannot read compose.yaml. Check file permissions.'
        ];
    }

    // Check if we can write to repo directory
    if (!is_writable($repo_dir)) {
        return [
            'success' => false,
            'message' => 'Cannot write to campaign-stack directory. Check permissions.'
        ];
    }

    // Check if install script exists and is executable
    $install_script = $repo_dir . '/install-campaign-stack.sh';
    if (!file_exists($install_script)) {
        return [
            'success' => false,
            'message' => 'install-campaign-stack.sh not found.'
        ];
    }

    return [
        'success' => true,
        'message' => 'File permissions OK, installation script found.'
    ];
}
