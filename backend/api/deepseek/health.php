<?php
// api/deepseek/health.php
// Update: Sekarang mengecek status OpenRouter
header('Content-Type: application/json');
require_once __DIR__ . '/../config.php';

$health = [
    'status' => 'healthy',
    'timestamp' => date('Y-m-d H:i:s'),
    'provider' => 'OpenRouter (Google Gemma 3)',
    'services' => []
];

// 1. Cek Koneksi Database
try {
    $stmt = $pdo->query("SELECT 1");
    $health['services']['database'] = [
        'status' => 'up',
        'latency_ms' => 0
    ];
} catch (PDOException $e) {
    $health['status'] = 'unhealthy';
    $health['services']['database'] = [
        'status' => 'down',
        'error' => 'Connection failed'
    ];
}

// 2. Cek Koneksi OpenRouter API
// Kita ping endpoint models mereka
$ch = curl_init('https://openrouter.ai/api/v1/models');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 5);
curl_setopt($ch, CURLOPT_NOBODY, true); // Hanya cek header (lebih cepat)

$start = microtime(true);
$result = curl_exec($ch);
$latency = round((microtime(true) - $start) * 1000);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

if ($result !== false && $http_code == 200) {
    $health['services']['ai_api'] = [
        'status' => 'reachable',
        'latency_ms' => $latency,
        'target' => 'openrouter.ai'
    ];
} else {
    // Jika gagal, status jadi degraded (aplikasi masih jalan, tapi AI mati)
    $health['status'] = $health['status'] === 'healthy' ? 'degraded' : 'unhealthy';
    $health['services']['ai_api'] = [
        'status' => 'unreachable',
        'latency_ms' => null,
        'http_code' => $http_code
    ];
}

// Set Response Code
if ($health['status'] === 'healthy') {
    http_response_code(200);
} elseif ($health['status'] === 'degraded') {
    http_response_code(200); 
} else {
    http_response_code(503);
}

echo json_encode($health, JSON_PRETTY_PRINT);
?>