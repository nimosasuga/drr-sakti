<?php
// delete_update_job.php
require 'config.php'; // expects $pdo + headers

$raw = file_get_contents('php://input');
$input = json_decode($raw, true);

// allow DELETE or POST for compatibility
if ((!$input || !is_array($input)) && $_SERVER['REQUEST_METHOD'] === 'POST') {
    $raw = file_get_contents('php://input');
    $input = json_decode($raw, true);
}

if (!$input || !is_array($input) || empty($input['id'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'id is required']);
    exit;
}

$id = (int)$input['id'];
if ($id <= 0) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid id']);
    exit;
}

try {
    // check exists
    $check = $pdo->prepare("SELECT id FROM update_jobs WHERE id = ? LIMIT 1");
    $check->execute([$id]);
    $exists = $check->fetch();
    if (!$exists) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Not found']);
        exit;
    }

    // delete
    $stmt = $pdo->prepare("DELETE FROM update_jobs WHERE id = ?");
    $stmt->execute([$id]);

    echo json_encode(['success' => true, 'message' => 'Deleted', 'id' => $id]);
    exit;
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database error: '.$e->getMessage()]);
    exit;
}
