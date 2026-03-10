<?php
// public_html/appsheetcore.my.id/api/database_tester.php

header('Content-Type: application/json');

function testConnection($host, $dbname, $user, $pass) {
    try {
        $conn = new PDO(
            "mysql:host=$host;dbname=$dbname;charset=utf8mb4",
            $user,
            $pass,
            [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
        );
        
        // Check required tables
        $tables = ['penarikan_units', 'unit_assets'];
        $existing_tables = [];
        
        foreach ($tables as $table) {
            $stmt = $conn->query("SHOW TABLES LIKE '$table'");
            if ($stmt->fetch()) {
                $existing_tables[] = $table;
            }
        }
        
        return [
            'success' => true,
            'database' => $dbname,
            'user' => $user,
            'existing_tables' => $existing_tables,
            'table_count' => count($existing_tables)
        ];
        
    } catch (PDOException $e) {
        return [
            'success' => false,
            'database' => $dbname,
            'user' => $user, 
            'error' => $e->getMessage()
        ];
    }
}

// Test berbagai kemungkinan konfigurasi
$tests = [
    // Pattern untuk addon domain di drrmedia.cloud
    ['localhost', 'drrmedia_drr_sakti', 'drrmedia_drr_sakti', 'drr_sakti_2024'],
    ['localhost', 'drrmedia_appsheet', 'drrmedia_appsheet', 'appsheet_2024'],
    ['localhost', 'drrmedia_main', 'drrmedia_main', 'main_2024'],
    
    // Pattern lama n1576996
    ['localhost', 'n1576996_drr_sakti', 'n1576996_drr_sakti', ''],
    ['localhost', 'n1576996_drr_sakti', 'n1576996_drr_sakti', 'password'],
    
    // Coba tanpa password
    ['localhost', 'drrmedia_drr_sakti', 'drrmedia_drr_sakti', ''],
    ['localhost', 'drr_sakti', 'drr_sakti', ''],
];

$results = [];
foreach ($tests as $test) {
    list($host, $dbname, $user, $pass) = $test;
    $results[] = testConnection($host, $dbname, $user, $pass);
}

echo json_encode([
    'test_results' => $results,
    'next_steps' => [
        '1. Login ke cPanel drrmedia.cloud',
        '2. Buka MySQL Databases', 
        '3. Lihat database users dan names yang tersedia',
        '4. Update config.php dengan kredensial yang benar'
    ]
]);
?>