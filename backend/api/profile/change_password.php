<?php
// public_html/drr.exprosa.com/api/profile/change_password.php

error_reporting(0);
ini_set('display_errors', 0);

// Include config FIRST - sama seperti login.php
require_once '../config.php';

// Start output buffering to catch any stray output
ob_start();

// Set CORS headers
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=UTF-8');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Only allow POST method
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method Not Allowed. Only POST is accepted.']);
    exit();
}

try {
    // Get POST data
    $input = json_decode(file_get_contents('php://input'), true);
    
    if ($input === null) {
        throw new Exception('Invalid JSON data');
    }

    // VALIDATION - Required fields
    $requiredFields = ['user_id', 'nrpp', 'old_password', 'new_password'];
    $missingFields = [];

    foreach ($requiredFields as $field) {
        if (!isset($input[$field]) || empty(trim($input[$field]))) {
            $missingFields[] = $field;
        }
    }

    if (!empty($missingFields)) {
        throw new Exception('Missing required fields: ' . implode(', ', $missingFields));
    }

    $userId = filter_var($input['user_id'], FILTER_VALIDATE_INT);
    $nrpp = trim($input['nrpp']);
    $oldPassword = trim($input['old_password']);
    $newPassword = trim($input['new_password']);

    // Validate user_id
    if ($userId === false || $userId <= 0) {
        throw new Exception('Invalid user_id format');
    }

    // Validate new password format
    if (strlen($newPassword) < 6) {
        throw new Exception('Password baru minimal 6 karakter');
    }

    if (!preg_match('/[0-9]/', $newPassword)) {
        throw new Exception('Password harus mengandung minimal 1 angka');
    }

    if (!preg_match('/[a-zA-Z]/', $newPassword)) {
        throw new Exception('Password harus mengandung minimal 1 huruf');
    }

    // Check if old and new password are the same
    if ($oldPassword === $newPassword) {
        throw new Exception('Password baru tidak boleh sama dengan password lama');
    }

    // DATABASE QUERY - Check user exists and verify old password
    $stmt = $pdo->prepare("SELECT id, name, nrpp, password FROM data_user WHERE id = ? AND nrpp = ? LIMIT 1");
    $stmt->execute([$userId, $nrpp]);
    $user = $stmt->fetch();

    if (!$user) {
        throw new Exception('User tidak ditemukan');
    }

    // Verify old password
    if ($user['password'] !== $oldPassword) {
        throw new Exception('Password lama tidak sesuai');
    }

    // Update password
    $updateStmt = $pdo->prepare("UPDATE data_user SET password = ?, updated_at = NOW() WHERE id = ?");
    $success = $updateStmt->execute([$newPassword, $userId]);

    if (!$success) {
        throw new Exception('Gagal mengubah password. Silakan coba lagi.');
    }

    // SUCCESS - Clean any buffered output before sending response
    ob_end_clean();
    
    echo json_encode([
        'success' => true,
        'message' => 'Password berhasil diubah',
        'data' => [
            'user_id' => (int)$user['id'],
            'name' => $user['name'],
            'nrpp' => $user['nrpp'],
            'updated_at' => date('Y-m-d H:i:s')
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
?>