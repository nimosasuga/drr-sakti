<?php
header('Content-Type: application/json');
require_once 'PdfGenerator.php';

try {
    $branch = $_GET['branch'] ?? null;
    
    $pdfGenerator = new DRRPdfGenerator();
    $result = $pdfGenerator->generateBatteryPDF($branch);
    
    if ($result) {
        echo json_encode(['success' => true, 'message' => 'Battery PDF generated successfully']);
    } else {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to generate PDF']);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
}
?>
