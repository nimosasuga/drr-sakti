<?php
require 'config.php';

try {
    $stmt = $pdo->query("SELECT * FROM unit_assets ORDER BY id DESC");
    $rows = $stmt->fetchAll();
    echo json_encode($rows);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database error: '.$e->getMessage()]);
}
?>
