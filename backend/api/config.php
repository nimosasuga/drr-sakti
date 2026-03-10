<?php
// config.php - FIXED VERSION WITH MULTIPLE ORIGINS

// =============================================
// ERROR HANDLING & SECURITY
// =============================================

error_reporting(0);
ini_set('display_errors', 0);

if (ob_get_level() === 0) {
    ob_start();
}

// =============================================
// CORS HEADERS - SUPPORT MULTIPLE ORIGINS
// =============================================

// Daftar origin yang diizinkan
$allowed_origins = [
    'https://exprosa.com',
    'https://drr.exprosa.com',
    'http://localhost:8080',
    'http://localhost:3000',
    'http://127.0.0.1:8080',
    'http://127.0.0.1:3000'
];

// Ambil origin dari request
$origin = isset($_SERVER['HTTP_ORIGIN']) ? $_SERVER['HTTP_ORIGIN'] : '';

// Cek apakah origin diizinkan
if (in_array($origin, $allowed_origins)) {
    header("Access-Control-Allow-Origin: $origin");
}
// Tentukan bahwa respons dapat bervariasi berdasarkan header Origin. Ini penting untuk caching.
header('Vary: Origin');
header("Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Authorization, X-API-KEY");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Credentials: true");
header('Content-Type: application/json; charset=utf-8');
header('Strict-Transport-Security: max-age=31536000; includeSubDomains');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    if (ob_get_level() > 0) ob_end_clean();
    exit;
}

// Get real client IP behind Cloudflare
if (isset($_SERVER['HTTP_CF_CONNECTING_IP'])) {
    $_SERVER['REMOTE_ADDR'] = $_SERVER['HTTP_CF_CONNECTING_IP'];
}

// =============================================
// DATABASE CONFIGURATION
// =============================================

$host = 'localhost';
$db   = 'exprosal_n1576996_drr_sakti';
$user = 'exprosal_drr';
$pass = '3XZlJwwTk}zMto+H';
$charset = 'utf8mb4';

// Variabel untuk compatibility
$db_host = $host;
$db_name = $db;
$db_user = $user;
$db_pass = $pass;

$dsn = "mysql:host=$host;dbname=$db;charset=$charset";
$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES   => false,
    PDO::ATTR_PERSISTENT         => false,
    PDO::ATTR_TIMEOUT            => 30,
];

// =============================================
// DATABASE CONNECTION
// =============================================

try {
    $pdo = new PDO($dsn, $user, $pass, $options);
    
    $test_stmt = $pdo->query("SELECT 1 as connection_test");
    if (!$test_stmt || $test_stmt->fetch()['connection_test'] != 1) {
        throw new PDOException("Database test query failed");
    }
    
    $conn = $pdo;
    
    error_log("✅ Database connected successfully: " . date('Y-m-d H:i:s'));
    
} catch (PDOException $e) {
    if (ob_get_level() > 0) ob_end_clean();
    
    error_log("❌ Database connection failed: " . $e->getMessage());
    
    http_response_code(500);
    echo json_encode([
        'success' => false, 
        'message' => 'Database connection failed',
        'error_code' => $e->getCode(),
        'error_info' => 'Check database credentials and connection'
    ]);
    exit;
}

// =============================================
// SECURITY & HELPER FUNCTIONS
// =============================================

function sanitize_input($data) {
    if (is_array($data)) {
        return array_map('sanitize_input', $data);
    }
    return htmlspecialchars(trim($data), ENT_QUOTES, 'UTF-8');
}

function validate_email($email) {
    return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
}

function generate_token($length = 32) {
    return bin2hex(random_bytes($length));
}

function hash_password($password) {
    return password_hash($password, PASSWORD_DEFAULT);
}

function verify_password($password, $hash) {
    return password_verify($password, $hash);
}

function check_rate_limit($identifier, $limit = 100, $time_window = 3600) {
    $cache_file = sys_get_temp_dir() . '/rate_limit_' . md5($identifier) . '.json';
    
    if (file_exists($cache_file)) {
        $data = json_decode(file_get_contents($cache_file), true);
        if (time() - $data['timestamp'] < $time_window) {
            if ($data['count'] >= $limit) {
                return false;
            }
            $data['count']++;
        } else {
            $data = ['count' => 1, 'timestamp' => time()];
        }
    } else {
        $data = ['count' => 1, 'timestamp' => time()];
    }
    
    file_put_contents($cache_file, json_encode($data));
    return true;
}

function api_log($message, $level = 'INFO') {
    $log_dir = __DIR__ . '/logs';
    $log_file = $log_dir . '/api_' . date('Y-m-d') . '.log';
    
    if (!is_dir($log_dir)) {
        mkdir($log_dir, 0755, true);
    }
    
    $timestamp = date('Y-m-d H:i:s');
    $log_message = "[$timestamp] [$level] $message" . PHP_EOL;
    
    file_put_contents($log_file, $log_message, FILE_APPEND | LOCK_EX);
}

function get_client_ip() {
    if (isset($_SERVER['HTTP_CF_CONNECTING_IP'])) {
        return $_SERVER['HTTP_CF_CONNECTING_IP'];
    } elseif (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
        return $_SERVER['HTTP_X_FORWARDED_FOR'];
    } else {
        return $_SERVER['REMOTE_ADDR'];
    }
}

function json_response($data, $status_code = 200) {
    http_response_code($status_code);
    header('Content-Type: application/json');
    echo json_encode($data);
    exit;
}

function error_response($message, $status_code = 400) {
    json_response([
        'success' => false,
        'message' => $message,
        'timestamp' => date('Y-m-d H:i:s')
    ], $status_code);
}

function success_response($data = [], $message = 'Success') {
    json_response([
        'success' => true,
        'message' => $message,
        'data' => $data,
        'timestamp' => date('Y-m-d H:i:s')
    ], 200);
}

// =============================================
// CLOUDFLARE SPECIFIC FUNCTIONS
// =============================================

function is_cloudflare() {
    return isset($_SERVER['HTTP_CF_RAY']) || isset($_SERVER['HTTP_CF_CONNECTING_IP']);
}

function get_cloudflare_country() {
    return $_SERVER['HTTP_CF_IPCOUNTRY'] ?? 'Unknown';
}

function get_cloudflare_ray() {
    return $_SERVER['HTTP_CF_RAY'] ?? '';
}

// =============================================
// CLEAN UP AND READY FOR USE
// =============================================

if (ob_get_level() > 0) {
    ob_end_clean();
}

global $db_host, $db_name, $db_user, $db_pass, $conn;

api_log("API accessed: " . $_SERVER['REQUEST_METHOD'] . " " . $_SERVER['REQUEST_URI'] . " - IP: " . get_client_ip() . " - Origin: " . $origin);

?>