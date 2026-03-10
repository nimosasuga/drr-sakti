<?php
require 'config.php';

// FIX: More flexible content type checking
$contentType = isset($_SERVER["CONTENT_TYPE"]) ? trim($_SERVER["CONTENT_TYPE"]) : '';

// Allow both 'application/json' and 'application/json; charset=utf-8'
if (strpos($contentType, 'application/json') === false) {
    http_response_code(415);
    echo json_encode(['success' => false, 'message' => 'Content-Type must be application/json']);
    exit;
}

$raw = file_get_contents('php://input');
$input = json_decode($raw, true);

if (json_last_error() !== JSON_ERROR_NONE) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid JSON: ' . json_last_error_msg()]);
    exit;
}

if (!$input || !is_array($input)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid JSON body or empty payload']);
    exit;
}

if (empty(trim($input['serial_number']))) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'serial_number is required and cannot be empty']);
    exit;
}

$serial = trim($input['serial_number']);

try {
    // Check if serial exists
    $check = $pdo->prepare("SELECT id, serial_number FROM unit_assets WHERE serial_number = ? LIMIT 1");
    $check->execute([$serial]);
    $existing = $check->fetch();

    if ($existing) {
        http_response_code(409);
        echo json_encode([
            'success' => false,
            'message' => 'Serial number already exists',
            'existing_id' => (int)$existing['id'],
            'existing_serial' => $existing['serial_number']
        ]);
        exit;
    }

    // Insert with transaction
    $pdo->beginTransaction();
    
    $sql = "INSERT INTO unit_assets (supported_by, customer, location, branch, serial_number, unit_type, year, status, delivery, jenis_unit, note)
            VALUES (:supported_by, :customer, :location, :branch, :serial_number, :unit_type, :year, :status, :delivery, :jenis_unit, :note)";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        ':supported_by' => !empty($input['supported_by']) ? trim($input['supported_by']) : null,
        ':customer'     => !empty($input['customer']) ? trim($input['customer']) : null,
        ':location'     => !empty($input['location']) ? trim($input['location']) : null,
        ':branch'       => !empty($input['branch']) ? trim($input['branch']) : null,
        ':serial_number'=> $serial,
        ':unit_type'    => !empty($input['unit_type']) ? trim($input['unit_type']) : null,
        ':year'         => isset($input['year']) && $input['year'] !== '' ? (int)$input['year'] : null,
        ':status'       => !empty($input['status']) ? trim($input['status']) : 'ACTIVE',
        ':delivery'     => !empty($input['delivery']) ? trim($input['delivery']) : null,
        ':jenis_unit'   => !empty($input['jenis_unit']) ? trim($input['jenis_unit']) : null,
        ':note'         => !empty($input['note']) ? trim($input['note']) : null,
    ]);

    $newId = (int)$pdo->lastInsertId();
    $pdo->commit();

    // 🔥 AUTO-GENERATE QR CODE UNTUK DATA BARU
    try {
        require_once __DIR__ . '/../admin/realtime_qr_handler.php';
        generateQRForNewData();
    } catch (Exception $qrError) {
        error_log("QR generation warning (non-fatal): " . $qrError->getMessage());
    }

    http_response_code(201);
    echo json_encode([
        'success' => true, 
        'message' => 'Unit created successfully', 
        'id' => $newId,
        'serial_number' => $serial
    ]);
    
} catch (PDOException $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    error_log("Create unit error: " . $e->getMessage());
    
    http_response_code(500);
    echo json_encode([
        'success' => false, 
        'message' => 'Database error: ' . $e->getMessage(),
        'error_code' => $e->getCode()
    ]);
}
?>