<?php
require 'config.php';

// Get parameters
$branch = $_GET['branch'] ?? '';
$exclude = $_GET['exclude'] ?? '';

if (empty($branch)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Branch parameter is required']);
    exit;
}

try {
    // Include user object
    require_once 'objects/user.php';
    $userObj = new User($pdo);
    
    $stmt = $userObj->getPartnersByBranch($branch, $exclude);
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode($users, JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
?>