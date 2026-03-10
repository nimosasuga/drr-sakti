<?php
header('Content-Type: application/json');
require_once 'PdfGenerator.php';

try {
    $branch = $_GET['branch'] ?? null;
    $customer = $_GET['customer'] ?? null;
    $status = $_GET['status'] ?? null;
    
    $filters = [];
    if ($customer) $filters['customer'] = $customer;
    if ($status) $filters['status'] = $status;
    
    $pdfGenerator = new DRRPdfGenerator();
    $result = $pdfGenerator->generateUnitsPDF($branch, $filters);
    
    if ($result) {
        echo json_encode(['success' => true, 'message' => 'PDF generated successfully']);
    } else {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to generate PDF']);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
}
?>
