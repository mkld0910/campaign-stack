<?php
/**
 * Management Panel Actions - Backend
 * Handles quick actions from the management panel
 */

header('Content-Type: text/plain; charset=utf-8');

$repo_dir = dirname(__DIR__);
chdir($repo_dir);

$action = $_GET['action'] ?? '';

switch ($action) {
    case 'status':
        passthru('docker compose ps 2>&1');
        break;

    case 'restart':
        echo "Restarting all services...\n\n";
        passthru('docker compose restart 2>&1');
        echo "\n✓ Services restarted\n";
        break;

    case 'logs':
        echo "Recent logs from all services:\n\n";
        passthru('docker compose logs --tail=50 2>&1');
        break;

    case 'civicrm':
        // Disable output buffering for streaming
        ob_implicit_flush(true);
        ob_end_flush();

        echo "Starting CiviCRM installation...\n\n";

        if (!file_exists('scripts/install-civicrm.sh')) {
            echo "ERROR: install-civicrm.sh not found\n";
            exit(1);
        }

        echo "This will take 3-5 minutes. Please wait...\n\n";

        $descriptorspec = [
            0 => ["pipe", "r"],
            1 => ["pipe", "w"],
            2 => ["pipe", "w"]
        ];

        $process = proc_open('bash scripts/install-civicrm.sh 2>&1', $descriptorspec, $pipes);

        if (is_resource($process)) {
            fclose($pipes[0]);

            while ($line = fgets($pipes[1])) {
                echo $line;
                flush();
            }

            fclose($pipes[1]);
            fclose($pipes[2]);

            $return_code = proc_close($process);

            if ($return_code === 0) {
                echo "\n✓ CiviCRM installation completed successfully!\n";
            } else {
                echo "\n✗ CiviCRM installation failed (exit code: $return_code)\n";
            }
        }
        break;

    default:
        echo "Invalid action\n";
        break;
}
