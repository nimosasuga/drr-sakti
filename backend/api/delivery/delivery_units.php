<?php
// =============================================
// api/delivery/delivery_units.php
// =============================================

// 1. Sertakan file konfigurasi dan koneksi database
require_once __DIR__ . '/../config.php';

// Tentukan nama tabel yang akan dioperasikan
$table_name = 'delivery_units';

// Ambil aksi dari parameter GET
$action = $_GET['action'] ?? '';

// Ambil data input
$input = json_decode(file_get_contents('php://input'), true);

// Pastikan request method yang diizinkan untuk setiap action
if ($_SERVER['REQUEST_METHOD'] === 'POST' && in_array($action, ['create', 'update', 'delete'])) {
    if (!$input) {
        error_response('Invalid JSON input', 400);
    }
}

// =============================================
// Logic Handler
// =============================================

switch ($action) {
    // -----------------------------------------
    // READ Operation (Get List or Single Item)
    // -----------------------------------------
    case 'read':
        try {
            $sql = "SELECT * FROM {$table_name}";
            $params = [];

            if (isset($_GET['id']) && !empty($_GET['id'])) {
                $sql .= " WHERE id = ?";
                $params[] = $_GET['id'];
                $stmt = $pdo->prepare($sql);
                $stmt->execute($params);
                $data = $stmt->fetch();
            } elseif (isset($_GET['branch']) && !empty($_GET['branch'])) {
                $sql .= " WHERE branch = ? ORDER BY date DESC, created_at DESC";
                $params[] = $_GET['branch'];
                $stmt = $pdo->prepare($sql);
                $stmt->execute($params);
                $data = $stmt->fetchAll();
            } else {
                // Read all (Admin access only, generally)
                $sql .= " ORDER BY created_at DESC";
                $stmt = $pdo->query($sql);
                $data = $stmt->fetchAll();
            }

            success_response($data, 'Delivery Units data retrieved successfully');

        } catch (PDOException $e) {
            error_response('Database Error: ' . $e->getMessage(), 500);
        }
        break;

    // -----------------------------------------
    // CREATE Operation
    // -----------------------------------------
    case 'create':
        // Pastikan id sudah tergenerate, customer, dan date ada
        if (empty($input['id']) || empty($input['branch']) || empty($input['date'])) {
            error_response('ID, branch, and date are required fields.', 400);
        }

        try {
            $fields = array_keys($input);
            $placeholders = array_map(fn($f) => ":$f", $fields);

            $sql = "INSERT INTO {$table_name} (" . implode(', ', $fields) . ") VALUES (" . implode(', ', $placeholders) . ")";
            $stmt = $pdo->prepare($sql);
            
            // Bind parameter
            foreach ($input as $key => $value) {
                // Konversi array JSON (job_type) ke string
                $bindValue = is_array($value) ? json_encode($value) : $value;
                $stmt->bindValue(":$key", $bindValue);
            }

            $stmt->execute();
            success_response(['id' => $input['id']], 'Delivery Unit created successfully', 201);

        } catch (PDOException $e) {
            if ($e->getCode() == '23000') {
                error_response('Error: Duplicate ID or required field constraint violation.', 409);
            }
            error_response('Database Error: ' . $e->getMessage(), 500);
        }
        break;

    // -----------------------------------------
    // UPDATE Operation
    // -----------------------------------------
    case 'update':
        if (empty($input['id'])) {
            error_response('ID is required for update.', 400);
        }

        try {
            $set_clauses = [];
            $params = [];

            foreach ($input as $key => $value) {
                if ($key !== 'id') {
                    $set_clauses[] = "{$key} = ?";
                    // Konversi array JSON (job_type) ke string
                    $params[] = is_array($value) ? json_encode($value) : $value;
                }
            }
            
            if (empty($set_clauses)) {
                error_response('No fields provided for update.', 400);
            }
            
            $params[] = $input['id']; // Add ID for WHERE clause
            $sql = "UPDATE {$table_name} SET " . implode(', ', $set_clauses) . " WHERE id = ?";
            $stmt = $pdo->prepare($sql);
            
            if ($stmt->execute($params)) {
                if ($stmt->rowCount() === 0) {
                    error_response('Delivery Unit not found or no changes made.', 404);
                }
                success_response(['id' => $input['id']], 'Delivery Unit updated successfully');
            } else {
                error_response('Update failed.', 500);
            }

        } catch (PDOException $e) {
            error_response('Database Error: ' . $e->getMessage(), 500);
        }
        break;

    // -----------------------------------------
    // DELETE Operation
    // -----------------------------------------
    case 'delete':
        if (empty($input['id'])) {
            error_response('ID is required for delete.', 400);
        }

        try {
            $sql = "DELETE FROM {$table_name} WHERE id = ?";
            $stmt = $pdo->prepare($sql);
            
            if ($stmt->execute([$input['id']])) {
                if ($stmt->rowCount() === 0) {
                    error_response('Delivery Unit not found.', 404);
                }
                success_response(null, 'Delivery Unit deleted successfully');
            } else {
                error_response('Delete failed.', 500);
            }

        } catch (PDOException $e) {
            error_response('Database Error: ' . $e->getMessage(), 500);
        }
        break;

    // -----------------------------------------
    // HELPER: Generate Unique ID
    // -----------------------------------------
    case 'generate_uuid':
        // Generate UUID (diasumsikan menggunakan fungsi generate_token() dari config.php, 
        // tapi kita akan buat penomoran sederhana karena ID di penarikan_units menggunakan format 000000X)
        try {
            // Ambil nomor terakhir dan tambahkan 1
            $stmt = $pdo->query("SELECT id FROM {$table_name} ORDER BY id DESC LIMIT 1");
            $last_id = $stmt->fetchColumn();
            
            if ($last_id) {
                // Asumsi format '0000001', ambil angka di belakang, tambahkan 1, lalu format ulang
                $number = (int) $last_id + 1;
            } else {
                $number = 1;
            }
            
            $new_id = str_pad($number, 7, '0', STR_PAD_LEFT);
            success_response(['uuid' => $new_id], 'New ID generated');

        } catch (PDOException $e) {
            error_response('Error generating new ID: ' . $e->getMessage(), 500);
        }
        break;

    // -----------------------------------------
    // HELPER: Get Unique Customers by Branch
    // -----------------------------------------
    case 'get_customers':
        $branch = $_GET['branch'] ?? null;
        if (empty($branch)) {
            error_response('Branch parameter is required.', 400);
        }
        try {
            $sql = "SELECT DISTINCT customer FROM unit_assets WHERE branch = ? AND customer IS NOT NULL ORDER BY customer";
            $stmt = $pdo->prepare($sql);
            $stmt->execute([$branch]);
            $customers = $stmt->fetchAll(PDO::FETCH_COLUMN);
            success_response($customers, 'Customers retrieved successfully');
        } catch (PDOException $e) {
            error_response('Database Error: ' . $e->getMessage(), 500);
        }
        break;

    // -----------------------------------------
    // HELPER: Get Locations by Customer
    // -----------------------------------------
    case 'get_locations':
        $customer = $_GET['customer'] ?? null;
        if (empty($customer)) {
            error_response('Customer parameter is required.', 400);
        }
        try {
            $sql = "SELECT DISTINCT location FROM unit_assets WHERE customer = ? AND location IS NOT NULL ORDER BY location";
            $stmt = $pdo->prepare($sql);
            $stmt->execute([$customer]);
            $locations = $stmt->fetchAll(PDO::FETCH_COLUMN);
            success_response($locations, 'Locations retrieved successfully');
        } catch (PDOException $e) {
            error_response('Database Error: ' . $e->getMessage(), 500);
        }
        break;
        
    // -----------------------------------------
    // HELPER: Get Units by Customer & Location
    // -----------------------------------------
    case 'get_units':
        $customer = $_GET['customer'] ?? null;
        $location = $_GET['location'] ?? null;
        if (empty($customer) || empty($location)) {
            error_response('Customer and location parameters are required.', 400);
        }
        try {
            // Asumsi Units yang akan di-Delivery adalah Units yang ada di unit_assets
            $sql = "SELECT * FROM unit_assets WHERE customer = ? AND location = ? AND serial_number IS NOT NULL ORDER BY serial_number";
            $stmt = $pdo->prepare($sql);
            $stmt->execute([$customer, $location]);
            $units = $stmt->fetchAll();
            success_response($units, 'Units retrieved successfully');
        } catch (PDOException $e) {
            error_response('Database Error: ' . $e->getMessage(), 500);
        }
        break;

    default:
        error_response('Invalid action specified.', 400);
        break;
}

// Setelah selesai, pastikan semua output buffer dibersihkan
if (ob_get_level() > 0) {
    ob_end_flush();
}
?>