<?php
// public_html/appsheetcore.my.id/api/battery/battery_api.php

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Include config
require_once __DIR__ . '/../config.php';

$action = $_GET['action'] ?? null;

if (!$action) {
    http_response_code(400);
    echo json_encode(['ok' => false, 'message' => 'Action required']);
    exit;
}

// Database connection
try {
    $conn = new PDO(
        "mysql:host=$db_host;dbname=$db_name;charset=utf8mb4",
        $db_user,
        $db_pass,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_TIMEOUT => 15
        ]
    );
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'ok' => false, 
        'message' => 'Database connection failed',
        'error' => $e->getMessage()
    ]);
    exit;
}

// Route actions
switch ($action) {
    case 'read':
        readBattery($conn);
        break;
    case 'read_one':
        readOneBattery($conn);
        break;
    case 'create':
        createBattery($conn);
        break;
    case 'update':
        updateBattery($conn);
        break;
    case 'delete':
        deleteBattery($conn);
        break;
    default:
        http_response_code(400);
        echo json_encode(['ok' => false, 'message' => 'Invalid action: ' . $action]);
}

// ===== FUNCTIONS =====

function readBattery($conn) {
    try {
        $branch = $_GET['branch'] ?? null;
        
        if ($branch) {
            $query = "SELECT * FROM battery WHERE branch = ? ORDER BY date DESC";
            $stmt = $conn->prepare($query);
            $stmt->execute([$branch]);
        } else {
            $query = "SELECT * FROM battery ORDER BY date DESC";
            $stmt = $conn->prepare($query);
            $stmt->execute();
        }
        
        $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // 🔥 PERBAIKAN: Hanya parse field yang benar-benar JSON
        foreach ($data as &$item) {
            // JOB TYPE - DISIMPAN SEBAGAI STRING, JANGAN PARSE JSON
            // Debug log untuk troubleshooting
            error_log("🔍 READ - Battery ID: " . $item['id'] . ", JOB TYPE: " . $item['job_type']);
            
            // Recommendations (JSON) - perlu parsing
            if (!empty($item['recommendations_json']) && is_string($item['recommendations_json'])) {
                $decoded = json_decode($item['recommendations_json'], true);
                $item['recommendations_json'] = is_array($decoded) ? $decoded : [];
            } else {
                $item['recommendations_json'] = [];
            }
            
            // Install Parts (JSON) - perlu parsing
            if (!empty($item['install_parts_json']) && is_string($item['install_parts_json'])) {
                $decoded = json_decode($item['install_parts_json'], true);
                $item['install_parts_json'] = is_array($decoded) ? $decoded : [];
            } else {
                $item['install_parts_json'] = [];
            }
        }
        
        echo json_encode(['ok' => true, 'data' => $data, 'count' => count($data)]);
        
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['ok' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    }
}

function readOneBattery($conn) {
    try {
        $id = $_GET['id'] ?? null;
        
        if (!$id) {
            http_response_code(400);
            echo json_encode(['ok' => false, 'message' => 'ID required']);
            return;
        }
        
        $query = "SELECT * FROM battery WHERE id = ?";
        $stmt = $conn->prepare($query);
        $stmt->execute([$id]);
        $data = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($data) {
            // 🔥 PERBAIKAN: Hanya parse field JSON, biarkan job_type sebagai string
            error_log("🔍 READ ONE - Battery ID: " . $data['id'] . ", JOB TYPE: " . $data['job_type']);
            
            // Recommendations (JSON) - perlu parsing
            if (!empty($data['recommendations_json']) && is_string($data['recommendations_json'])) {
                $decoded = json_decode($data['recommendations_json'], true);
                $data['recommendations_json'] = is_array($decoded) ? $decoded : [];
            } else {
                $data['recommendations_json'] = [];
            }
            
            // Install Parts (JSON) - perlu parsing
            if (!empty($data['install_parts_json']) && is_string($data['install_parts_json'])) {
                $decoded = json_decode($data['install_parts_json'], true);
                $data['install_parts_json'] = is_array($decoded) ? $decoded : [];
            } else {
                $data['install_parts_json'] = [];
            }
        }
        
        echo json_encode(['ok' => true, 'data' => $data]);
        
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['ok' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    }
}

// ===== UPDATED FUNCTIONS =====

function createBattery($conn) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        http_response_code(400);
        echo json_encode(['ok' => false, 'message' => 'Invalid JSON input']);
        return;
    }
    
    // 🔥 JOB TYPE DISIMPAN SEBAGAI STRING BERTEKAAN, BUKAN JSON
    $jobType = isset($input['job_type']) ? $input['job_type'] : '';
    
    // Debug log untuk memastikan data yang diterima
    error_log("📝 CREATE - Received job_type: " . $jobType);
    error_log("📝 CREATE - Received data: " . json_encode($input));
    
    $recommendations = isset($input['recommendations_json']) ? json_encode($input['recommendations_json']) : json_encode([]);
    $installParts = isset($input['install_parts_json']) ? json_encode($input['install_parts_json']) : json_encode([]);
    
    try {
        $query = "INSERT INTO battery (
            branch, status_mekanik, pic, partner, in_time, out_time, vehicle, nopol, date,
            customer, location, serial_number, unit_type, 
            sn_battery, battery_type, battery_year, 
            job_type, status_unit, problem_date, rfu_date, problem, action, 
            recommendations_json, install_parts_json, category_job, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())";
        
        $stmt = $conn->prepare($query);
        $stmt->execute([
            $input['branch'],
            $input['status_mekanik'] ?? null,
            $input['pic'] ?? null,
            $input['partner'] ?? null,
            $input['in_time'] ?? null,
            $input['out_time'] ?? null,
            $input['vehicle'] ?? null,
            $input['nopol'] ?? null,
            $input['date'] ?? date('Y-m-d'),
            $input['customer'] ?? null,
            $input['location'] ?? null,
            $input['serial_number'] ?? null, // Unit SN
            $input['unit_type'] ?? null,     // Unit Type
            $input['sn_battery'] ?? null,    // Battery SN
            $input['battery_type'] ?? null,
            $input['battery_year'] ?? null,  // Battery Year
            $jobType, // 🔥 STRING BERTEKAAN
            $input['status_unit'] ?? 'RFU',
            $input['problem_date'] ?? null,
            $input['rfu_date'] ?? null,
            $input['problem'] ?? null,
            $input['action'] ?? null,
            $recommendations,
            $installParts,
            $input['category_job'] ?? null,
        ]);
        
        $lastId = $conn->lastInsertId();
        error_log("✅ CREATE - Successfully created battery ID: " . $lastId);
        
        http_response_code(201);
        echo json_encode(['ok' => true, 'message' => 'Created successfully', 'id' => $lastId]);
        
    } catch (PDOException $e) {
        error_log("❌ CREATE - Database error: " . $e->getMessage());
        http_response_code(400);
        echo json_encode(['ok' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    }
}

function updateBattery($conn) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input || empty($input['id'])) {
        http_response_code(400);
        echo json_encode(['ok' => false, 'message' => 'Invalid input or ID missing']);
        return;
    }
    
    try {
        // 🔥 JOB TYPE DISIMPAN SEBAGAI STRING BERTEKAAN, BUKAN JSON
        $jobType = isset($input['job_type']) ? $input['job_type'] : '';
        
        // Debug log untuk memastikan data yang diterima
        error_log("📝 UPDATE - Battery ID: " . $input['id'] . ", Received job_type: " . $jobType);
        
        $recommendations = isset($input['recommendations_json']) ? json_encode($input['recommendations_json']) : json_encode([]);
        $installParts = isset($input['install_parts_json']) ? json_encode($input['install_parts_json']) : json_encode([]);
        
        $query = "UPDATE battery SET
            branch = ?, status_mekanik = ?, pic = ?, partner = ?, in_time = ?, out_time = ?,
            vehicle = ?, nopol = ?, date = ?, 
            customer = ?, location = ?, serial_number = ?, unit_type = ?,
            sn_battery = ?, battery_type = ?, battery_year = ?,
            job_type = ?, status_unit = ?,
            problem_date = ?, rfu_date = ?, problem = ?, action = ?,
            recommendations_json = ?, install_parts_json = ?, category_job = ?, updated_at = NOW()
            WHERE id = ?";
        
        $stmt = $conn->prepare($query);
        $stmt->execute([
            $input['branch'] ?? null,
            $input['status_mekanik'] ?? null,
            $input['pic'] ?? null,
            $input['partner'] ?? null,
            $input['in_time'] ?? null,
            $input['out_time'] ?? null,
            $input['vehicle'] ?? null,
            $input['nopol'] ?? null,
            $input['date'] ?? null,
            $input['customer'] ?? null,
            $input['location'] ?? null,
            $input['serial_number'] ?? null, // Unit SN
            $input['unit_type'] ?? null,     // Unit Type
            $input['sn_battery'] ?? null,    // Battery SN
            $input['battery_type'] ?? null,
            $input['battery_year'] ?? null,  // Battery Year
            $jobType, // 🔥 STRING BERTEKAAN
            $input['status_unit'] ?? 'RFU',
            $input['problem_date'] ?? null,
            $input['rfu_date'] ?? null,
            $input['problem'] ?? null,
            $input['action'] ?? null,
            $recommendations,
            $installParts,
            $input['category_job'] ?? null,
            $input['id'],
        ]);
        
        $affectedRows = $stmt->rowCount();
        error_log("✅ UPDATE - Successfully updated battery ID: " . $input['id'] . ", Affected rows: " . $affectedRows);
        
        echo json_encode(['ok' => true, 'message' => 'Updated successfully']);
        
    } catch (PDOException $e) {
        error_log("❌ UPDATE - Database error: " . $e->getMessage());
        http_response_code(400);
        echo json_encode(['ok' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    }
}

function deleteBattery($conn) {
    try {
        $id = $_GET['id'] ?? null;
        
        if (!$id) {
            http_response_code(400);
            echo json_encode(['ok' => false, 'message' => 'ID required']);
            return;
        }
        
        error_log("🗑️ DELETE - Attempting to delete battery ID: " . $id);
        
        $query = "DELETE FROM battery WHERE id = ?";
        $stmt = $conn->prepare($query);
        $stmt->execute([$id]);
        
        $affectedRows = $stmt->rowCount();
        
        if ($affectedRows > 0) {
            error_log("✅ DELETE - Successfully deleted battery ID: " . $id);
            echo json_encode(['ok' => true, 'message' => 'Deleted successfully']);
        } else {
            error_log("❌ DELETE - Record not found, ID: " . $id);
            http_response_code(404);
            echo json_encode(['ok' => false, 'message' => 'Record not found']);
        }
        
    } catch (PDOException $e) {
        error_log("❌ DELETE - Database error: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['ok' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    }
}

// Helper function untuk debug
function debugLog($message) {
    $timestamp = date('Y-m-d H:i:s');
    $logMessage = "[$timestamp] $message\n";
    
    // Log ke error log (bisa dilihat di cPanel atau server logs)
    error_log($logMessage);
    
    // Juga output ke response jika dalam mode debug
    if (isset($_GET['debug'])) {
        echo "<!-- DEBUG: $message -->\n";
    }
}

?>