<?php
require_once __DIR__ . '/../../vendor/autoload.php';

use TCPDF as TCPDF;

class DRRPdfGenerator {
    
    private $pdo;
    
    public function __construct() {
        // Load config
        $configCandidates = [
            __DIR__ . '/../config.php',
            __DIR__ . '/../../config.php',
            __DIR__ . '/../../api/config.php',
        ];
        foreach ($configCandidates as $c) {
            if (file_exists($c)) { 
                require_once $c; 
                $this->pdo = $conn ?? null;
                break; 
            }
        }
    }
    
    public function generateUnitsPDF($branch = null, $filters = []) {
        try {
            $sql = "SELECT * FROM unit_assets WHERE 1=1";
            $params = [];
            
            if ($branch) {
                $sql .= " AND branch = ?";
                $params[] = $branch;
            }
            
            if (!empty($filters['customer'])) {
                $sql .= " AND customer LIKE ?";
                $params[] = '%' . $filters['customer'] . '%';
            }
            
            if (!empty($filters['status'])) {
                $sql .= " AND status = ?";
                $params[] = $filters['status'];
            }
            
            $sql .= " ORDER BY customer, location, serial_number";
            
            $stmt = $this->pdo->prepare($sql);
            $stmt->execute($params);
            $units = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            $pdf = new TCPDF('L', PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false);
            $pdf->SetCreator('DRR SAKTI');
            $pdf->SetAuthor('DRR SAKTI System');
            $pdf->SetTitle('Unit Assets Report');
            $pdf->SetSubject('Unit Assets Export');
            $pdf->AddPage();
            
            $pdf->SetFont('helvetica', 'B', 16);
            $pdf->Cell(0, 10, 'DRR SAKTI - UNIT ASSETS REPORT', 0, 1, 'C');
            $pdf->SetFont('helvetica', '', 10);
            $pdf->Cell(0, 10, 'Generated on: ' . date('Y-m-d H:i:s'), 0, 1, 'C');
            
            if ($branch) {
                $pdf->Cell(0, 10, 'Branch: ' . $branch, 0, 1, 'C');
            }
            $pdf->Ln(10);
            
            $pdf->SetFont('helvetica', 'B', 9);
            $header = ['No', 'Serial Number', 'Unit Type', 'Customer', 'Location', 'Branch', 'Status', 'Year'];
            $widths = [10, 30, 30, 40, 40, 25, 25, 15];
            
            for ($i = 0; $i < count($header); $i++) {
                $pdf->Cell($widths[$i], 7, $header[$i], 1, 0, 'C');
            }
            $pdf->Ln();
            
            $pdf->SetFont('helvetica', '', 8);
            $counter = 1;
            
            foreach ($units as $unit) {
                $pdf->Cell($widths[0], 6, $counter, 'LR', 0, 'C');
                $pdf->Cell($widths[1], 6, $unit['serial_number'] ?? '-', 'LR', 0, 'L');
                $pdf->Cell($widths[2], 6, $unit['unit_type'] ?? '-', 'LR', 0, 'L');
                $pdf->Cell($widths[3], 6, $unit['customer'] ?? '-', 'LR', 0, 'L');
                $pdf->Cell($widths[4], 6, $unit['location'] ?? '-', 'LR', 0, 'L');
                $pdf->Cell($widths[5], 6, $unit['branch'] ?? '-', 'LR', 0, 'C');
                $pdf->Cell($widths[6], 6, $unit['status'] ?? '-', 'LR', 0, 'C');
                $pdf->Cell($widths[7], 6, $unit['year'] ?? '-', 'LR', 0, 'C');
                $pdf->Ln();
                $counter++;
            }
            
            $pdf->Cell(array_sum($widths), 0, '', 'T');
            $filename = 'units_export_' . date('Ymd_His') . '.pdf';
            $pdf->Output($filename, 'D');
            
            return true;
            
        } catch (Exception $e) {
            error_log("PDF Generation Error: " . $e->getMessage());
            return false;
        }
    }
    
    public function generateJobsPDF($branch = null, $dateRange = []) {
        try {
            $sql = "SELECT uj.*, ua.customer, ua.location 
                    FROM update_jobs uj 
                    LEFT JOIN unit_assets ua ON uj.serial_number = ua.serial_number 
                    WHERE 1=1";
            $params = [];
            
            if ($branch) {
                $sql .= " AND uj.branch = ?";
                $params[] = $branch;
            }
            
            if (!empty($dateRange['start'])) {
                $sql .= " AND uj.date >= ?";
                $params[] = $dateRange['start'];
            }
            
            if (!empty($dateRange['end'])) {
                $sql .= " AND uj.date <= ?";
                $params[] = $dateRange['end'];
            }
            
            $sql .= " ORDER BY uj.date DESC, uj.id DESC";
            
            $stmt = $this->pdo->prepare($sql);
            $stmt->execute($params);
            $jobs = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            $pdf = new TCPDF('L', PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false);
            $pdf->AddPage();
            
            $pdf->SetFont('helvetica', 'B', 16);
            $pdf->Cell(0, 10, 'DRR SAKTI - UPDATE JOBS REPORT', 0, 1, 'C');
            $pdf->SetFont('helvetica', '', 10);
            $pdf->Cell(0, 10, 'Generated on: ' . date('Y-m-d H:i:s'), 0, 1, 'C');
            $pdf->Ln(10);
            
            $pdf->SetFont('helvetica', 'B', 8);
            $header = ['No', 'Date', 'Serial No', 'Customer', 'Job Type', 'PIC', 'Status', 'Problem Date', 'RFU Date'];
            $widths = [10, 20, 25, 40, 30, 30, 25, 25, 25];
            
            foreach ($header as $i => $col) {
                $pdf->Cell($widths[$i], 7, $col, 1, 0, 'C');
            }
            $pdf->Ln();
            
            $pdf->SetFont('helvetica', '', 7);
            $counter = 1;
            
            foreach ($jobs as $job) {
                $jobType = $job['job_type'] ? implode(', ', json_decode($job['job_type'], true) ?? []) : '-';
                
                $pdf->Cell($widths[0], 6, $counter, 'LR', 0, 'C');
                $pdf->Cell($widths[1], 6, $job['date'] ?? '-', 'LR', 0, 'C');
                $pdf->Cell($widths[2], 6, $job['serial_number'] ?? '-', 'LR', 0, 'L');
                $pdf->Cell($widths[3], 6, $job['customer'] ?? '-', 'LR', 0, 'L');
                $pdf->Cell($widths[4], 6, $jobType, 'LR', 0, 'L');
                $pdf->Cell($widths[5], 6, $job['pic'] ?? '-', 'LR', 0, 'L');
                $pdf->Cell($widths[6], 6, $job['status_unit'] ?? '-', 'LR', 0, 'C');
                $pdf->Cell($widths[7], 6, $job['problem_date'] ?? '-', 'LR', 0, 'C');
                $pdf->Cell($widths[8], 6, $job['rfu_date'] ?? '-', 'LR', 0, 'C');
                $pdf->Ln();
                $counter++;
            }
            
            $pdf->Cell(array_sum($widths), 0, '', 'T');
            $filename = 'jobs_export_' . date('Ymd_His') . '.pdf';
            $pdf->Output($filename, 'D');
            
            return true;
            
        } catch (Exception $e) {
            error_log("Jobs PDF Error: " . $e->getMessage());
            return false;
        }
    }
    
    public function generateBatteryPDF($branch = null) {
        try {
            $sql = "SELECT * FROM battery WHERE 1=1";
            $params = [];
            
            if ($branch) {
                $sql .= " AND branch = ?";
                $params[] = $branch;
            }
            
            $sql .= " ORDER BY date DESC";
            
            $stmt = $this->pdo->prepare($sql);
            $stmt->execute($params);
            $batteries = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            $pdf = new TCPDF('L', PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false);
            $pdf->AddPage();
            
            $pdf->SetFont('helvetica', 'B', 16);
            $pdf->Cell(0, 10, 'DRR SAKTI - BATTERY MANAGEMENT REPORT', 0, 1, 'C');
            $pdf->SetFont('helvetica', '', 10);
            $pdf->Cell(0, 10, 'Generated on: ' . date('Y-m-d H:i:s'), 0, 1, 'C');
            $pdf->Ln(10);
            
            $pdf->SetFont('helvetica', 'B', 8);
            $header = ['No', 'Serial No', 'Battery Type', 'Customer', 'Location', 'Date', 'Job Type', 'Status'];
            $widths = [10, 30, 35, 45, 40, 25, 30, 25];
            
            foreach ($header as $i => $col) {
                $pdf->Cell($widths[$i], 7, $col, 1, 0, 'C');
            }
            $pdf->Ln();
            
            $pdf->SetFont('helvetica', '', 7);
            $counter = 1;
            
            foreach ($batteries as $battery) {
                $jobType = $battery['job_type'] ? implode(', ', json_decode($battery['job_type'], true) ?? []) : '-';
                
                $pdf->Cell($widths[0], 6, $counter, 'LR', 0, 'C');
                $pdf->Cell($widths[1], 6, $battery['serial_number'] ?? '-', 'LR', 0, 'L');
                $pdf->Cell($widths[2], 6, $battery['battery_type'] ?? '-', 'LR', 0, 'L');
                $pdf->Cell($widths[3], 6, $battery['customer'] ?? '-', 'LR', 0, 'L');
                $pdf->Cell($widths[4], 6, $battery['location'] ?? '-', 'LR', 0, 'L');
                $pdf->Cell($widths[5], 6, $battery['date'] ?? '-', 'LR', 0, 'C');
                $pdf->Cell($widths[6], 6, $jobType, 'LR', 0, 'L');
                $pdf->Cell($widths[7], 6, $battery['status_unit'] ?? '-', 'LR', 0, 'C');
                $pdf->Ln();
                $counter++;
            }
            
            $pdf->Cell(array_sum($widths), 0, '', 'T');
            $filename = 'battery_export_' . date('Ymd_His') . '.pdf';
            $pdf->Output($filename, 'D');
            
            return true;
            
        } catch (Exception $e) {
            error_log("Battery PDF Error: " . $e->getMessage());
            return false;
        }
    }
}
?>
