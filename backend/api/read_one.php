<?php
require 'config.php';

$id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
if ($id <= 0) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Missing or invalid id']);
    exit;
}

try {
    $stmt = $pdo->prepare("SELECT * FROM unit_assets WHERE id = ? LIMIT 1");
    $stmt->execute([$id]);
    $row = $stmt->fetch();
    if ($row) {
        echo json_encode($row);
    } else {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Not found']);
    }
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database error: '.$e->getMessage()]);
}
?>
