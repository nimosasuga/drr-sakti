<?php
include_once('../config.php');

$branch = $_GET['branch'] ?? null;

try {
    // Total units
    $stmt = $conn->prepare("SELECT COUNT(*) as count FROM unit_assets WHERE branch = :branch");
    $stmt->execute([':branch' => $branch]);
    $totalUnits = $stmt->fetch()['count'];

    // Units by type
    $stmt = $conn->prepare("
        SELECT unit_type, COUNT(*) as count 
        FROM unit_assets 
        WHERE branch = :branch 
        GROUP BY unit_type
    ");
    $stmt->execute([':branch' => $branch]);
    $byType = $stmt->fetchAll();

    // Units by status
    $stmt = $conn->prepare("
        SELECT status, COUNT(*) as count 
        FROM unit_assets 
        WHERE branch = :branch 
        GROUP BY status
    ");
    $stmt->execute([':branch' => $branch]);
    $byStatus = $stmt->fetchAll();

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'data' => [
            'total_units' => $totalUnits,
            'by_type' => $byType,
            'by_status' => $byStatus
        ]
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
?>