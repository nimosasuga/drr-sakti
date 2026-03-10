<?php
// login.php - FIXED VERSION

error_reporting(0);
ini_set('display_errors', 0);

// Include config FIRST
require_once 'config.php';

// Start output buffering to catch any stray output
ob_start();

try {
    // SUPPORT BOTH GET (for testing) AND POST (for app)
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        $nrpp = $_GET['nrpp'] ?? '';
        $password = $_GET['password'] ?? '';
    } else {
        $input = json_decode(file_get_contents('php://input'), true);
        $nrpp = $input['nrpp'] ?? '';
        $password = $input['password'] ?? '';
    }

    // VALIDATION
    if (empty($nrpp) || empty($password)) {
        throw new Exception('NRPP and password are required');
    }

    // DATABASE QUERY
    $stmt = $pdo->prepare("SELECT id, name, nrpp, password, status_user, branch FROM data_user WHERE nrpp = ? LIMIT 1");
    $stmt->execute([$nrpp]);
    $user = $stmt->fetch();

    if (!$user) {
        throw new Exception('Invalid NRPP or password');
    }

    // PASSWORD CHECK
    if ($user['password'] !== $password) {
        throw new Exception('Invalid NRPP or password');
    }

    // SUCCESS - Clean any buffered output before sending response
    ob_end_clean();
    
    echo json_encode([
        'success' => true,
        'message' => 'Login successful',
        'user' => [
            'id' => (int)$user['id'],
            'name' => $user['name'],
            'nrpp' => $user['nrpp'],
            'status_user' => $user['status_user'],
            'branch' => $user['branch'],
            'token' => base64_encode($user['nrpp'] . '|' . time())
        ]
    ], JSON_UNESCAPED_UNICODE);
    exit;

} catch (Exception $e) {
    // Clean any buffered output before sending error response
    ob_end_clean();
    
    http_response_code(400);
    echo json_encode([
        'success' => false, 
        'message' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
    exit;
}