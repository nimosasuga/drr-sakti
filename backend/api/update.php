<?php
require 'config.php';

// support PUT and also POST with id in body
$raw = file_get_contents('php://input');
$input = json_decode($raw, true);
if (!$input || !is_array($input)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid JSON body or empty payload']);
    exit;
}

if (empty($input['id'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'id is required']);
    exit;
}

$id = (int)$input['id'];

try {
    // Optional: cek apakah id ada
    $check = $pdo->prepare("SELECT id FROM unit_assets WHERE id = ? LIMIT 1");
    $check->execute([$id]);
    if (!$check->fetch()) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Not found']);
        exit;
    }

    $sql = "UPDATE unit_assets SET
        supported_by = :supported_by,
        customer = :customer,
        location = :location,
        branch = :branch,
        serial_number = :serial_number,
        unit_type = :unit_type,
        year = :year,
        status = :status,
        delivery = :delivery,
        jenis_unit = :jenis_unit,
        note = :note
      WHERE id = :id";
    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        ':supported_by' => $input['supported_by'] ?? null,
        ':customer'     => $input['customer'] ?? null,
        ':location'     => $input['location'] ?? null,
        ':branch'       => $input['branch'] ?? null,
        ':serial_number'=> $input['serial_number'] ?? null,
        ':unit_type'    => $input['unit_type'] ?? null,
        ':year'         => $input['year'] ?? null,
        ':status'       => $input['status'] ?? null,
        ':delivery'     => $input['delivery'] ?? null,
        ':jenis_unit'   => $input['jenis_unit'] ?? null,
        ':note'         => $input['note'] ?? null,
        ':id'           => $id
    ]);

    echo json_encode(['success' => true, 'message' => 'Updated']);
} catch (PDOException $e) {
    // detect duplicate serial error (1062) and send friendly response
    if ($e->errorInfo[1] == 1062) {
        http_response_code(409);
        echo json_encode(['success' => false, 'message' => 'Duplicate serial_number: '.$e->getMessage()]);
    } else {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Database error: '.$e->getMessage()]);
    }
}
?>
