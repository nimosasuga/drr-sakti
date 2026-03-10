<?php
require 'config.php';

$raw = file_get_contents('php://input');
$input = json_decode($raw, true);
if (!$input || !is_array($input) || empty($input['id'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'id is required']);
    exit;
}
$id = (int)$input['id'];

try {
    $stmt = $pdo->prepare("DELETE FROM unit_assets WHERE id = ?");
    $stmt->execute([$id]);
    echo json_encode(['success' => true, 'message' => 'Deleted']);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database error: '.$e->getMessage()]);
}
?>
