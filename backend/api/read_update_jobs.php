<?php
require 'config.php';

// ===== HANDLE SINGLE JOB BY ID =====
if (isset($_GET['id'])) {
    $id = (int)$_GET['id'];
    if ($id > 0) {
        try {
            $stmt = $pdo->prepare("SELECT * FROM update_jobs WHERE id = ? LIMIT 1");
            $stmt->execute([$id]);
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if ($row) {
                // Process JSON columns
                if (!empty($row['recommendations_json'])) {
                    $dec = json_decode($row['recommendations_json'], true);
                    $row['recommendations'] = $dec !== null ? $dec : [];
                } else {
                    $row['recommendations'] = [];
                }

                if (!empty($row['install_parts_json'])) {
                    $dec2 = json_decode($row['install_parts_json'], true);
                    $row['install_parts'] = $dec2 !== null ? $dec2 : [];
                } else {
                    $row['install_parts'] = [];
                }

                unset($row['recommendations_json'], $row['install_parts_json']);
                
                echo json_encode($row, JSON_UNESCAPED_UNICODE);
                exit;
            } else {
                http_response_code(404);
                echo json_encode(['success' => false, 'message' => 'Update job not found']);
                exit;
            }
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Database error: '.$e->getMessage()]);
            exit;
        }
    } else {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Invalid job ID']);
        exit;
    }
}

// ===== HANDLE MULTIPLE JOBS (LIST & DASHBOARD) =====
try {
    // 1. Cek Mode: Apakah Ambil Semua Data (untuk Dashboard) atau Pagination?
    $fetchAll = isset($_GET['all']) && $_GET['all'] === 'true';
    
    // 2. Cek Filter Branch
    $branchFilter = isset($_GET['branch']) ? $_GET['branch'] : null;

    // Persiapkan Query Dasar
    $sql = "SELECT * FROM update_jobs";
    $countSql = "SELECT COUNT(*) as total FROM update_jobs";
    $params = [];

    // Tambahkan WHERE clause jika ada branch
    if ($branchFilter) {
        $sql .= " WHERE branch = ?"; 
        $countSql .= " WHERE branch = ?";
        $params[] = $branchFilter;
    }

    $sql .= " ORDER BY id DESC";

    // Eksekusi Count Query dulu untuk Pagination info
    $countStmt = $pdo->prepare($countSql);
    $countStmt->execute($params);
    $total = $countStmt->fetch()['total'];

    // 3. Logika Limit/Offset
    if ($fetchAll) {
        // Jika mode all=true, JANGAN pakai LIMIT (Hati-hati jika data ribuan)
        // Dashboard butuh semua data untuk statistik
    } else {
        // Mode Pagination Biasa
        $page = isset($_GET['page']) ? max(1, (int)$_GET['page']) : 1;
        $limit = isset($_GET['limit']) ? min(max(1, (int)$_GET['limit']), 100) : 50;
        $offset = ($page - 1) * $limit;
        
        $sql .= " LIMIT $limit OFFSET $offset";
        
        // Hitung total pages hanya relevan jika pakai pagination
        $totalPages = ceil($total / $limit);
    }

    // Eksekusi Query Utama
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Process JSON columns
    foreach ($rows as &$r) {
        if (!empty($r['recommendations_json'])) {
            $dec = json_decode($r['recommendations_json'], true);
            $r['recommendations'] = $dec !== null ? $dec : [];
        } else {
            $r['recommendations'] = [];
        }

        if (!empty($r['install_parts_json'])) {
            $dec2 = json_decode($r['install_parts_json'], true);
            $r['install_parts'] = $dec2 !== null ? $dec2 : [];
        } else {
            $r['install_parts'] = [];
        }

        unset($r['recommendations_json'], $r['install_parts_json']);
    }
    unset($r);

    // Response structure
    $response = [
        'success' => true,
        'data' => $rows,
        'pagination' => $fetchAll ? [
            'page' => 1,
            'limit' => $total, // Total semua data
            'total' => $total,
            'total_pages' => 1
        ] : [
            'page' => $page,
            'limit' => $limit,
            'total' => $total,
            'total_pages' => $totalPages
        ]
    ];

    echo json_encode($response, JSON_UNESCAPED_UNICODE);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false, 
        'message' => 'Database error: ' . $e->getMessage()
    ]);
}
?>