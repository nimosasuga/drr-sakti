<?php
// public_html/appsheetcore.my.id/api/charger/charger_api.php

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
        readCharger($conn);
        break;
    case 'read_one':
        readOneCharger($conn);
        break;
    case 'create':
        createCharger($conn);
        break;
    case 'update':
        updateCharger($conn);
        break;
    case 'delete':
        deleteCharger($conn);
        break;
    default:
        http_response_code(400);
        echo json_encode(['ok' => false, 'message' => 'Invalid action: ' . $action]);
}

// ===== FUNCTIONS =====

function readCharger($conn) {
    try {
        $branch = $_GET['branch'] ?? null;
        
        if ($branch) {
            $query = "SELECT * FROM charger WHERE branch = ? ORDER BY date DESC";
            $stmt = $conn->prepare($query);
            $stmt->execute([$branch]);
        } else {
            $query = "SELECT * FROM charger ORDER BY date DESC";
            $stmt = $conn->prepare($query);
            $stmt->execute();
        }
        
        $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Parse JSON fields (Only recommendations and parts)
        // NOTE: job_type dibiarkan sebagai STRING
        foreach ($data as &$item) {
            if (!empty($item['recommendations_json']) && is_string($item['recommendations_json'])) {
                $item['recommendations_json'] = json_decode($item['recommendations_json'], true) ?? [];
            }
            if (!empty($item['install_parts_json']) && is_string($item['install_parts_json'])) {
                $item['install_parts_json'] = json_decode($item['install_parts_json'], true) ?? [];
            }
        }
        
        echo json_encode(['ok' => true, 'data' => $data, 'count' => count($data)]);
        
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['ok' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    }
}

function readOneCharger($conn) {
    try {
        $id = $_GET['id'] ?? null;
        
        if (!$id) {
            http_response_code(400);
            echo json_encode(['ok' => false, 'message' => 'ID required']);
            return;
        }
        
        $query = "SELECT * FROM charger WHERE id = ?";
        $stmt = $conn->prepare($query);
        $stmt->execute([$id]);
        $data = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($data) {
            // Parse JSON fields
            if (!empty($data['recommendations_json']) && is_string($data['recommendations_json'])) {
                $data['recommendations_json'] = json_decode($data['recommendations_json'], true) ?? [];
            }
            if (!empty($data['install_parts_json']) && is_string($data['install_parts_json'])) {
                $data['install_parts_json'] = json_decode($data['install_parts_json'], true) ?? [];
            }
        }
        
        echo json_encode(['ok' => true, 'data' => $data]);
        
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['ok' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    }
}

function createCharger($conn) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        http_response_code(400);
        echo json_encode(['ok' => false, 'message' => 'Invalid JSON input']);
        return;
    }
    
    // Prepare JSON strings
    $recommendations = isset($input['recommendations_json']) ? json_encode($input['recommendations_json']) : json_encode([]);
    $installParts = isset($input['install_parts_json']) ? json_encode($input['install_parts_json']) : json_encode([]);
    
    // job_type disimpan langsung sebagai string (comma separated)
    $jobType = isset($input['job_type']) ? $input['job_type'] : ''; 

    try {
        $query = "INSERT INTO charger (
            branch, status_mekanik, pic, partner, in_time, out_time, vehicle, nopol, date,
            customer, location, serial_number, unit_type,
            sn_charger, charger_type, charger_year, 
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
            $input['serial_number'] ?? null, 
            $input['unit_type'] ?? null,     
            $input['sn_charger'] ?? null,    
            $input['charger_type'] ?? null,
            $input['charger_year'] ?? null,  
            $jobType, // Disimpan sebagai string
            $input['status_unit'] ?? 'RFU',
            $input['problem_date'] ?? null,
            $input['rfu_date'] ?? null,
            $input['problem'] ?? null,
            $input['action'] ?? null,
            $recommendations,
            $installParts,
            $input['category_job'] ?? null,
        ]);
        
        http_response_code(201);
        echo json_encode(['ok' => true, 'message' => 'Created successfully', 'id' => $conn->lastInsertId()]);
        
    } catch (PDOException $e) {
        http_response_code(400);
        echo json_encode(['ok' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    }
}

function updateCharger($conn) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input || empty($input['id'])) {
        http_response_code(400);
        echo json_encode(['ok' => false, 'message' => 'Invalid input']);
        return;
    }
    
    try {
        $recommendations = isset($input['recommendations_json']) ? json_encode($input['recommendations_json']) : json_encode([]);
        $installParts = isset($input['install_parts_json']) ? json_encode($input['install_parts_json']) : json_encode([]);
        
        // job_type disimpan sebagai string
        $jobType = isset($input['job_type']) ? $input['job_type'] : '';

        $query = "UPDATE charger SET
            branch = ?, status_mekanik = ?, pic = ?, partner = ?, in_time = ?, out_time = ?,
            vehicle = ?, nopol = ?, date = ?, 
            customer = ?, location = ?, serial_number = ?, unit_type = ?,
            sn_charger = ?, charger_type = ?, charger_year = ?,
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
            $input['serial_number'] ?? null, 
            $input['unit_type'] ?? null,     
            $input['sn_charger'] ?? null,    
            $input['charger_type'] ?? null,
            $input['charger_year'] ?? null,  
            $jobType, // String
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
        
        echo json_encode(['ok' => true, 'message' => 'Updated successfully']);
        
    } catch (PDOException $e) {
        http_response_code(400);
        echo json_encode(['ok' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    }
}

function deleteCharger($conn) {
    try {
        $id = $_GET['id'] ?? null;
        
        if (!$id) {
            http_response_code(400);
            echo json_encode(['ok' => false, 'message' => 'ID required']);
            return;
        }
        
        $query = "DELETE FROM charger WHERE id = ?";
        $stmt = $conn->prepare($query);
        $stmt->execute([$id]);
        
        if ($stmt->rowCount() > 0) {
            echo json_encode(['ok' => true, 'message' => 'Deleted successfully']);
        } else {
            http_response_code(404);
            echo json_encode(['ok' => false, 'message' => 'Record not found']);
        }
        
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['ok' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    }
}
?>