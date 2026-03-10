<?php
// public_html/appsheetcore.my.id/api/find_existing_config.php

header('Content-Type: application/json');

// Cari file config di berbagai lokasi
$possible_config_locations = [
    __DIR__ . '/config.php',
    __DIR__ . '/../config.php', 
    __DIR__ . '/../../config.php',
    __DIR__ . '/../database.php',
    __DIR__ . '/../app/config.php',
    __DIR__ . '/../../app/config.php',
    __DIR__ . '/../inc/config.php',
];

$found_configs = [];

foreach ($possible_config_locations as $location) {
    if (file_exists($location)) {
        $content = file_get_contents($location);
        
        // Extract database credentials
        if (preg_match('/\$db_?host\s*=\s*[\'"]([^\'"]*)[\'"]/', $content, $host)) {
            if (preg_match('/\$db_?name\s*=\s*[\'"]([^\'"]*)[\'"]/', $content, $name)) {
                if (preg_match('/\$db_?user\s*=\s*[\'"]([^\'"]*)[\'"]/', $content, $user)) {
                    if (preg_match('/\$db_?pass\s*=\s*[\'"]([^\'"]*)[\'"]/', $content, $pass)) {
                        $found_configs[] = [
                            'file' => $location,
                            'host' => $host[1],
                            'name' => $name[1], 
                            'user' => $user[1],
                            'pass' => $pass[1]
                        ];
                    }
                }
            }
        }
    }
}

// Test each found config
$test_results = [];
foreach ($found_configs as $config) {
    try {
        $conn = new PDO(
            "mysql:host={$config['host']};dbname={$config['name']};charset=utf8mb4",
            $config['user'],
            $config['pass'],
            [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
        );
        
        $test_results[] = [
            'config' => $config,
            'status' => 'WORKING',
            'message' => 'Database connection successful!'
        ];
        
    } catch (PDOException $e) {
        $test_results[] = [
            'config' => $config,
            'status' => 'FAILED', 
            'error' => $e->getMessage()
        ];
    }
}

echo json_encode([
    'found_configurations' => $found_configs,
    'test_results' => $test_results
], JSON_PRETTY_PRINT);
?>