<?php
// public_html/appsheetcore.my.id/api/dashboard_stats.php

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    require_once __DIR__ . '/config.php';
    
    if (!isset($db_host) || !isset($db_name) || !isset($db_user)) {
        throw new Exception('Database credentials not configured');
    }
    
    $branch = $_GET['branch'] ?? null;
    $debug = isset($_GET['debug']);
    
    if (!$branch) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Branch parameter required']);
        exit;
    }
    
    $conn = new PDO(
        "mysql:host=$db_host;dbname=$db_name;charset=utf8mb4",
        $db_user,
        $db_pass,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
    
    // Get date info
    $now = new DateTime();
    $currentMonth = (int)$now->format('m');
    $currentYear = (int)$now->format('Y');
    $previousMonth = $currentMonth == 1 ? 12 : $currentMonth - 1;
    $previousYear = $currentMonth == 1 ? $currentYear - 1 : $currentYear;
    
    if ($debug) {
        error_log("=== DEBUG DASHBOARD STATS ===");
        error_log("Branch: $branch, Current: $currentMonth/$currentYear, Previous: $previousMonth/$previousYear");
    }
    
    // ===== GET ALL JOBS =====
    $stmt = $conn->prepare("SELECT job_type, date FROM update_jobs WHERE branch = ? ORDER BY date DESC");
    $stmt->execute([$branch]);
    $allJobs = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if ($debug) {
        error_log("Total jobs found: " . count($allJobs));
    }
    
    // ===== FILTER AND COUNT =====
    $currentTroubleshooting = 0;
    $currentPreventive = 0;
    $previousTroubleshooting = 0;
    $previousPreventive = 0;
    
    foreach ($allJobs as $job) {
        $dateStr = $job['date'];
        $jobTypeStr = $job['job_type'];
        
        if (!$dateStr) {
            continue;
        }
        
        // Parse date
        $jobDate = new DateTime($dateStr);
        $jobMonth = (int)$jobDate->format('m');
        $jobYear = (int)$jobDate->format('Y');
        
        if ($debug && count($allJobs) <= 10) {
            error_log("Job: Date=$dateStr ($jobMonth/$jobYear), Types=$jobTypeStr");
        }
        
        // Parse job types (comma-separated)
        $types = array_map('trim', explode(',', $jobTypeStr));
        
        // Check for Troubleshooting
        $hasTroubleshooting = false;
        foreach ($types as $type) {
            if (stripos($type, 'TROUBLESHOOTING') !== false) {
                $hasTroubleshooting = true;
                break;
            }
        }
        
        // Check for Preventive
        $hasPreventive = false;
        foreach ($types as $type) {
            if (stripos($type, 'PREVENTIVE') !== false) {
                $hasPreventive = true;
                break;
            }
        }
        
        // Count for current month
        if ($jobMonth == $currentMonth && $jobYear == $currentYear) {
            if ($hasTroubleshooting) $currentTroubleshooting++;
            if ($hasPreventive) $currentPreventive++;
        }
        
        // Count for previous month
        if ($jobMonth == $previousMonth && $jobYear == $previousYear) {
            if ($hasTroubleshooting) $previousTroubleshooting++;
            if ($hasPreventive) $previousPreventive++;
        }
    }
    
    if ($debug) {
        error_log("Results - Current TS: $currentTroubleshooting, PM: $currentPreventive");
        error_log("Results - Previous TS: $previousTroubleshooting, PM: $previousPreventive");
    }
    
    // ===== PM STATUS =====
    $stmt = $conn->prepare("SELECT COUNT(DISTINCT serial_number) as total FROM unit_assets WHERE branch = ?");
    $stmt->execute([$branch]);
    $pmResult = $stmt->fetch(PDO::FETCH_ASSOC);
    $totalUnits = $pmResult['total'] ?? 0;
    
    $stmt = $conn->prepare("SELECT COUNT(DISTINCT serial_number) as total FROM update_jobs WHERE branch = ? AND job_type LIKE ?");
    $stmt->execute([$branch, '%PREVENTIVE%']);
    $pmResult = $stmt->fetch(PDO::FETCH_ASSOC);
    $sudahPM = $pmResult['total'] ?? 0;
    
    $belumPM = max(0, $totalUnits - $sudahPM);
    $percentage = $totalUnits > 0 ? ($sudahPM / $totalUnits) * 100 : 0;
    
    if ($debug) {
        error_log("PM Status - Total: $totalUnits, Done: $sudahPM, Remaining: $belumPM");
        error_log("=== END DEBUG ===");
    }
    
    // ===== RESPONSE =====
    echo json_encode([
        'success' => true,
        'data' => [
            'current_month' => [
                'troubleshooting' => (int)$currentTroubleshooting,
                'preventive' => (int)$currentPreventive,
                'total' => (int)($currentTroubleshooting + $currentPreventive),
            ],
            'previous_month' => [
                'troubleshooting' => (int)$previousTroubleshooting,
                'preventive' => (int)$previousPreventive,
                'total' => (int)($previousTroubleshooting + $previousPreventive),
            ],
            'pm_status' => [
                'total_units' => (int)$totalUnits,
                'sudah_pm' => (int)$sudahPM,
                'belum_pm' => (int)$belumPM,
                'percentage' => round($percentage, 2),
            ],
        ],
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage(),
        'trace' => $e->getTraceAsString(),
    ]);
}
?>