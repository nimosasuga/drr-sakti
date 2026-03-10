<?php
require 'config.php';

$branch = isset($_GET['branch']) ? trim($_GET['branch']) : '';
if (empty($branch)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Branch parameter required']);
    exit;
}

try {
    $stmt = $pdo->prepare("SELECT * FROM update_jobs WHERE branch = ? ORDER BY id DESC");
    $stmt->execute([$branch]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Process JSON columns
    foreach ($rows as &$r) {
        if (!empty($r['recommendations_json'])) {
            $dec = json_decode($r['recommendations_json'], true);
            $r['recommendations'] = $dec !== null ? $dec : [];
        } else {
            $r['recommendations'] = [];
        }

        if (!empty($r['install_parts_json'])) {
            $dec2 = json_decode($r['install_parts_json'], true);
            $r['install_parts'] = $dec2 !== null ? $dec2 : [];
        } else {
            $r['install_parts'] = [];
        }

        unset($r['recommendations_json'], $r['install_parts_json']);
    }
    unset($r);

    echo json_encode($rows, JSON_UNESCAPED_UNICODE);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database error: '.$e->getMessage()]);
}
?>