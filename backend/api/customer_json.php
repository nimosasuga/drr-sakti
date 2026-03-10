<?php
// public_html/api/customer_json.php
header('Content-Type: application/json; charset=utf-8');
ini_set('display_errors', 0);
error_reporting(0);

$configCandidates = [
    __DIR__ . '/config.php',
    __DIR__ . '/../api/config.php',
    __DIR__ . '/../config.php',
    __DIR__ . '/../../api/config.php'
];

$found = false;
foreach ($configCandidates as $c) {
    if (file_exists($c)) { require_once $c; $found = $c; break; }
}
if (!$found) {
    http_response_code(500);
    echo json_encode(['status'=>'error','message'=>'config.php not found']);
    exit;
}
if (!isset($pdo) || !($pdo instanceof PDO)) {
    http_response_code(500);
    echo json_encode(['status'=>'error','message'=>'DB not available']);
    exit;
}

$token = isset($_GET['token']) ? trim($_GET['token']) : '';
if ($token === '') {
    http_response_code(400);
    echo json_encode(['status'=>'error','message'=>'token required']);
    exit;
}

try {
    // units
    $stmt = $pdo->prepare("SELECT id, serial_number AS serial, unit_type AS unit_name, customer, location, branch
                           FROM unit_assets
                           WHERE TRIM(qr_token) = :token
                           ORDER BY customer, location, unit_type");
    $stmt->execute([':token'=>$token]);
    $units = $stmt->fetchAll(PDO::FETCH_ASSOC);

    if (!$units) {
        http_response_code(404);
        echo json_encode(['status'=>'error','message'=>'not found']);
        exit;
    }

    // jobs: prefer join by serial_number; fallback to unit_id join if serial join yields no rows
    $jobSql1 = "
      SELECT uj.*, u.serial_number, u.unit_type
      FROM update_jobs uj
      JOIN unit_assets u ON uj.serial_number = u.serial_number
      WHERE u.qr_token = :token
      ORDER BY uj.date DESC
      LIMIT 500
    ";
    $stmt2 = $pdo->prepare($jobSql1);
    $stmt2->execute([':token'=>$token]);
    $jobs = $stmt2->fetchAll(PDO::FETCH_ASSOC);

    if (!$jobs) {
        // fallback
        $jobSql2 = "
          SELECT uj.*, u.serial_number, u.unit_type
          FROM update_jobs uj
          JOIN unit_assets u ON uj.unit_id = u.id
          WHERE u.qr_token = :token
          ORDER BY uj.date DESC
          LIMIT 500
        ";
        $stmt3 = $pdo->prepare($jobSql2);
        $stmt3->execute([':token'=>$token]);
        $jobs = $stmt3->fetchAll(PDO::FETCH_ASSOC);
    }

    echo json_encode(['status'=>'success','units'=>$units,'jobs'=>$jobs], JSON_UNESCAPED_UNICODE);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['status'=>'error','message'=>'server error']);
}