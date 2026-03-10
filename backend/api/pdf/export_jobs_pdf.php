<?php
header('Content-Type: application/json');
require_once 'PdfGenerator.php';

try {
    $branch = $_GET['branch'] ?? null;
    $startDate = $_GET['start_date'] ?? null;
    $endDate = $_GET['end_date'] ?? null;
    
    $dateRange = [];
    if ($startDate) $dateRange['start'] = $startDate;
    if ($endDate) $dateRange['end'] = $endDate;
    
    $pdfGenerator = new DRRPdfGenerator();
    $result = $pdfGenerator->generateJobsPDF($branch, $dateRange);
    
    if ($result) {
        echo json_encode(['success' => true, 'message' => 'Jobs PDF generated successfully']);
    } else {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to generate PDF']);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
}
?>
