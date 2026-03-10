<?php
require 'config.php';

$serial = isset($_GET['serial']) ? trim($_GET['serial']) : null;
if (!$serial) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'serial parameter required']);
    exit;
}

try {
    $stmt = $pdo->prepare("SELECT id FROM unit_assets WHERE serial_number = ? LIMIT 1");
    $stmt->execute([$serial]);
    $row = $stmt->fetch();
    if ($row) {
        echo json_encode(['exists' => true, 'id' => (int)$row['id']]);
    } else {
        echo json_encode(['exists' => false]);
    }
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database error: '.$e->getMessage()]);
}
?>
