<?php
// mechanic_stats.php - COMPLETE FIXED VERSION FOR CLOUDFLARE
include_once 'config.php';

// Enable error reporting untuk debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Enhanced CORS for Cloudflare compatibility
$allowed_origins = [
    'https://appsheetcore.my.id',
    'https://www.appsheetcore.my.id',
    'http://appsheetcore.my.id', // fallback
];

$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
if (in_array($origin, $allowed_origins)) {
    header("Access-Control-Allow-Origin: $origin");
} else {
    header("Access-Control-Allow-Origin: https://appsheetcore.my.id");
}

// Log start request
error_log("=== MECHANIC STATS API CALLED ===");
error_log("REQUEST METHOD: " . $_SERVER['REQUEST_METHOD']);
error_log("GET PARAMS: " . print_r($_GET, true));
error_log("CLOUDFLARE: " . (is_cloudflare() ? "YES" : "NO"));
error_log("CLIENT IP: " . get_client_ip());

// Pastikan $pdo tersedia (gunakan $pdo, bukan $conn)
if (!isset($pdo)) {
    error_log("❌ ERROR: \$pdo is not defined");
    http_response_code(500);
    echo json_encode([
        "success" => false, 
        "message" => "Database connection not established"
    ]);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    $pic = isset($_GET['pic']) ? trim($_GET['pic']) : '';
    
    error_log("📝 PIC Parameter: '$pic'");
    
    if (empty($pic)) {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "PIC parameter is required"]);
        exit;
    }
    
    try {
        // TEST KONEKSI DATABASE DULU
        error_log("🔗 Testing database connection...");
        $test_query = "SELECT 1 as test";
        $test_stmt = $pdo->prepare($test_query); // GUNAKAN $pdo
        $test_stmt->execute();
        $test_result = $test_stmt->fetch(PDO::FETCH_ASSOC);
        error_log("✅ Database connection OK: " . ($test_result['test'] ?? 'FAILED'));
        
        // Normalize input: remove spaces and convert to lowercase
        $normalized_input = strtolower(str_replace(' ', '', $pic));
        error_log("🔄 Normalized input: '$normalized_input'");
        
        // METHOD 1: Cari dengan query yang lebih simple dulu
        error_log("🔍 METHOD 1: Simple exact match");
        $find_pic_query = "
            SELECT DISTINCT pic 
            FROM update_jobs 
            WHERE pic = :pic
            LIMIT 1
        ";
        
        $stmt_find = $pdo->prepare($find_pic_query); // GUNAKAN $pdo
        $stmt_find->bindValue(':pic', $pic, PDO::PARAM_STR);
        $stmt_find->execute();
        $actual_pic = $stmt_find->fetch(PDO::FETCH_ASSOC);
        
        if (!$actual_pic) {
            error_log("🔍 METHOD 2: Case-insensitive match");
            // Coba case-insensitive
            $find_pic_query2 = "
                SELECT DISTINCT pic 
                FROM update_jobs 
                WHERE LOWER(pic) = LOWER(:pic)
                LIMIT 1
            ";
            
            $stmt_find2 = $pdo->prepare($find_pic_query2); // GUNAKAN $pdo
            $stmt_find2->bindValue(':pic', $pic, PDO::PARAM_STR);
            $stmt_find2->execute();
            $actual_pic = $stmt_find2->fetch(PDO::FETCH_ASSOC);
        }
        
        if (!$actual_pic) {
            error_log("🔍 METHOD 3: Fuzzy match dengan normalized input");
            // Coba dengan normalized input (remove spaces)
            $find_pic_query3 = "
                SELECT DISTINCT pic 
                FROM update_jobs 
                WHERE LOWER(REPLACE(pic, ' ', '')) = :normalized_input
                LIMIT 1
            ";
            
            $stmt_find3 = $pdo->prepare($find_pic_query3); // GUNAKAN $pdo
            $stmt_find3->bindValue(':normalized_input', $normalized_input, PDO::PARAM_STR);
            $stmt_find3->execute();
            $actual_pic = $stmt_find3->fetch(PDO::FETCH_ASSOC);
        }
        
        if (!$actual_pic) {
            error_log("🔍 METHOD 4: Partial match dengan LIKE");
            // Coba dengan partial match
            $find_pic_query4 = "
                SELECT DISTINCT pic 
                FROM update_jobs 
                WHERE pic LIKE CONCAT('%', :pic, '%')
                LIMIT 1
            ";
            
            $stmt_find4 = $pdo->prepare($find_pic_query4); // GUNAKAN $pdo
            $stmt_find4->bindValue(':pic', $pic, PDO::PARAM_STR);
            $stmt_find4->execute();
            $actual_pic = $stmt_find4->fetch(PDO::FETCH_ASSOC);
        }
        
        if (!$actual_pic) {
            error_log("❌ Tidak ada PIC yang cocok: '$pic'");
            
            // Coba list semua PIC yang ada untuk debugging
            $all_pics_query = "SELECT DISTINCT pic FROM update_jobs LIMIT 10";
            $all_pics_stmt = $pdo->prepare($all_pics_query); // GUNAKAN $pdo
            $all_pics_stmt->execute();
            $all_pics = $all_pics_stmt->fetchAll(PDO::FETCH_COLUMN);
            error_log("📋 Available PICs: " . implode(', ', $all_pics));
            
            echo json_encode([
                "success" => true,
                "totalJobs" => 0,
                "efficiency" => 0,
                "pendingBreakdowns" => 0,
                "jobTypes" => [],
                "month" => date('F Y'),
                "searched_pic" => $pic,
                "matched_pic" => null,
                "message" => "No matching PIC found",
                "available_pics_sample" => $all_pics,
                "cloudflare" => is_cloudflare()
            ]);
            exit;
        }
        
        $actual_pic_name = $actual_pic['pic'];
        error_log("✅ PIC ditemukan: '$actual_pic_name'");
        
        // 1. GET TOTAL JOBS - QUERY SEDERHANA DULU
        error_log("📊 Getting total jobs...");
        $query_total = "
            SELECT COUNT(*) as total_jobs
            FROM update_jobs 
            WHERE pic = :pic
            AND MONTH(date) = MONTH(CURRENT_DATE())
            AND YEAR(date) = YEAR(CURRENT_DATE())
        ";
        
        $stmt_total = $pdo->prepare($query_total); // GUNAKAN $pdo
        $stmt_total->bindParam(':pic', $actual_pic_name, PDO::PARAM_STR);
        $stmt_total->execute();
        $total_result = $stmt_total->fetch(PDO::FETCH_ASSOC);
        $total_jobs = (int)($total_result['total_jobs'] ?? 0);
        
        error_log("📈 Total jobs: $total_jobs");
        
        // 2. GET EFFICIENCY
        error_log("📈 Getting efficiency...");
        $query_efficiency = "
            SELECT 
                COUNT(*) as total,
                COUNT(CASE WHEN status_unit = 'RFU' THEN 1 END) as completed
            FROM update_jobs 
            WHERE pic = :pic
            AND MONTH(date) = MONTH(CURRENT_DATE())
            AND YEAR(date) = YEAR(CURRENT_DATE())
        ";
        
        $stmt_eff = $pdo->prepare($query_efficiency); // GUNAKAN $pdo
        $stmt_eff->bindParam(':pic', $actual_pic_name, PDO::PARAM_STR);
        $stmt_eff->execute();
        $eff_result = $stmt_eff->fetch(PDO::FETCH_ASSOC);
        
        $total_for_eff = (int)($eff_result['total'] ?? 0);
        $completed = (int)($eff_result['completed'] ?? 0);
        $efficiency = $total_for_eff > 0 ? round(($completed * 100.0 / $total_for_eff), 1) : 0;
        
        error_log("📈 Efficiency: $completed/$total_for_eff = $efficiency%");
        
        // 3. GET JOB TYPES
        error_log("📋 Getting job types...");
        $query_job_types = "
            SELECT 
                job_type,
                COUNT(*) as count
            FROM update_jobs 
            WHERE pic = :pic 
            AND MONTH(date) = MONTH(CURRENT_DATE())
            AND YEAR(date) = YEAR(CURRENT_DATE())
            GROUP BY job_type
            ORDER BY count DESC
        ";
        
        $stmt_job_types = $pdo->prepare($query_job_types); // GUNAKAN $pdo
        $stmt_job_types->bindParam(':pic', $actual_pic_name, PDO::PARAM_STR);
        $stmt_job_types->execute();
        $jobTypes = $stmt_job_types->fetchAll(PDO::FETCH_ASSOC);
        
        error_log("📊 Job types count: " . count($jobTypes));
        
        // 4. GET PENDING BREAKDOWNS
        error_log("⚠️ Getting pending breakdowns...");
        $query_pending = "
            SELECT COUNT(*) as pending_count
            FROM update_jobs 
            WHERE pic = :pic
            AND job_type = 'Breakdown'
            AND status_unit != 'RFU'
            AND MONTH(date) = MONTH(CURRENT_DATE())
            AND YEAR(date) = YEAR(CURRENT_DATE())
        ";
        
        $stmt_pending = $pdo->prepare($query_pending); // GUNAKAN $pdo
        $stmt_pending->bindParam(':pic', $actual_pic_name, PDO::PARAM_STR);
        $stmt_pending->execute();
        $pending_result = $stmt_pending->fetch(PDO::FETCH_ASSOC);
        $pending_count = (int)($pending_result['pending_count'] ?? 0);
        
        error_log("✅ Pending breakdowns: $pending_count");
        
        // 5. DEBUG: Get sample data untuk verifikasi
        error_log("🐛 Getting sample data for verification...");
        $debug_query = "
            SELECT id, date, job_type, status_unit, problem 
            FROM update_jobs 
            WHERE pic = :pic
            AND MONTH(date) = MONTH(CURRENT_DATE())
            AND YEAR(date) = YEAR(CURRENT_DATE())
            ORDER BY date DESC 
            LIMIT 3
        ";
        
        $debug_stmt = $pdo->prepare($debug_query);
        $debug_stmt->bindParam(':pic', $actual_pic_name, PDO::PARAM_STR);
        $debug_stmt->execute();
        $sample_data = $debug_stmt->fetchAll(PDO::FETCH_ASSOC);
        
        error_log("📄 Sample data count: " . count($sample_data));
        
        // RESPONSE FINAL
        $response = [
            "success" => true,
            "totalJobs" => $total_jobs,
            "efficiency" => $efficiency,
            "pendingBreakdowns" => $pending_count,
            "jobTypes" => $jobTypes,
            "month" => date('F Y'),
            "searched_pic" => $pic,
            "matched_pic" => $actual_pic_name,
            "debug" => [
                "normalized_input" => $normalized_input,
                "total_records" => $total_jobs,
                "efficiency_calc" => "$completed/$total_for_eff",
                "job_types_count" => count($jobTypes),
                "sample_data_count" => count($sample_data),
                "cloudflare" => is_cloudflare(),
                "country" => get_cloudflare_country()
            ]
        ];
        
        error_log("🎉 Sending successful response");
        echo json_encode($response);
        
    } catch (PDOException $e) {
        error_log("❌ DATABASE ERROR: " . $e->getMessage());
        error_log("❌ ERROR CODE: " . $e->getCode());
        error_log("❌ ERROR TRACE: " . $e->getTraceAsString());
        
        http_response_code(500);
        echo json_encode([
            "success" => false, 
            "message" => "Database Error: " . $e->getMessage(),
            "error_code" => $e->getCode(),
            "error_info" => $e->errorInfo ?? null,
            "cloudflare" => is_cloudflare()
        ]);
    }
    
} else {
    http_response_code(405);
    echo json_encode(["success" => false, "message" => "Method not allowed"]);
}

error_log("=== MECHANIC STATS API FINISHED ===");
?>