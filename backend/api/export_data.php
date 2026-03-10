<?php
include_once('../config.php');

$branch = $_GET['branch'] ?? null;

try {
    $stmt = $conn->prepare("
        SELECT * FROM update_jobs 
        WHERE branch = :branch 
        ORDER BY date DESC
    ");
    $stmt->execute([':branch' => $branch]);
    $jobs = $stmt->fetchAll();

    // Generate CSV
    header('Content-Type: text/csv');
    header('Content-Disposition: attachment; filename="jobs_' . $branch . '_' . date('YmdHis') . '.csv"');

    $output = fopen('php://output', 'w');

    // Header row
    fputcsv($output, [
        'ID', 'Branch', 'PIC', 'Serial Number', 'Unit Type', 'Customer', 
        'Location', 'Job Type', 'Status Unit', 'Problem', 'Action', 'Date'
    ]);

    // Data rows
    foreach ($jobs as $job) {
        fputcsv($output, [
            $job['id'],
            $job['branch'],
            $job['pic'],
            $job['serial_number'],
            $job['unit_type'],
            $job['customer'],
            $job['location'],
            $job['job_type'],
            $job['status_unit'],
            $job['problem'],
            $job['action'],
            $job['date']
        ]);
    }

    fclose($output);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
?>