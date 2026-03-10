<?php
// update_update_job.php
require 'config.php'; // must provide $pdo and JSON/CORS headers

$raw = file_get_contents('php://input');
$input = json_decode($raw, true);

// allow POST as fallback (some clients send POST instead of PUT)
if (!$input && $_SERVER['REQUEST_METHOD'] === 'POST') {
    $raw = file_get_contents('php://input');
    $input = json_decode($raw, true);
}

if (!$input || !is_array($input)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid JSON body or empty payload']);
    exit;
}

function v($arr, $k) {
    return isset($arr[$k]) && $arr[$k] !== '' ? $arr[$k] : null;
}

// id required
$id = isset($input['id']) ? (int)$input['id'] : 0;
if ($id <= 0) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'id is required']);
    exit;
}

// map fields (same names as create)
$branch = v($input,'branch');
$status_mekanik = v($input,'status_mekanik');
$pic = v($input,'pic');
$partner = v($input,'partner');
$in_time = v($input,'in_time');
$out_time = v($input,'out_time');
$vehicle = v($input,'vehicle');
$nopol = v($input,'nopol');
$date = v($input,'date');
$serial_number = v($input,'serial_number');
$unit_type = v($input,'unit_type');
$year = v($input,'year');
$hour_meter = v($input,'hour_meter');
$nomor_lambung = v($input,'nomor_lambung');
$customer = v($input,'customer');
$location = v($input,'location');
$job_type = v($input,'job_type');
$status_unit = v($input,'status_unit');
$problem_date = v($input,'problem_date');
$rfu_date = v($input,'rfu_date');
$lead_time_rfu = v($input,'lead_time_rfu');
$pm = v($input,'pm');
$rm = v($input,'rm');
$problem = v($input,'problem');
$action = v($input,'action');
// JSON fields
// START OF FIX: Ambil data recommendations & install_parts dan ubah ke JSON string
// Data dikirim dari Flutter menggunakan key 'recommendations' dan 'install_parts'
$recommendations_data = isset($input['recommendations']) ? $input['recommendations'] : null;
$install_parts_data = isset($input['install_parts']) ? $input['install_parts'] : null;

// Konversi array PHP (dari JSON input) menjadi string JSON untuk disimpan di DB
$recommendations_json = $recommendations_data !== null ? json_encode($recommendations_data) : null;
$install_parts_json = $install_parts_data !== null ? json_encode($install_parts_data) : null;
// END OF FIX

try {
    // 1. Lakukan UPDATE
    $sql = "UPDATE update_jobs SET
      branch = :branch,
      status_mekanik = :status_mekanik,
      pic = :pic,
      partner = :partner,
      in_time = :in_time,
      out_time = :out_time,
      vehicle = :vehicle,
      nopol = :nopol,
      date = :date,
      serial_number = :serial_number,
      unit_type = :unit_type,
      year = :year,
      hour_meter = :hour_meter,
      nomor_lambung = :nomor_lambung,
      customer = :customer,
      location = :location,
      job_type = :job_type,
      status_unit = :status_unit,
      problem_date = :problem_date,
      rfu_date = :rfu_date,
      lead_time_rfu = :lead_time_rfu,
      pm = :pm,
      rm = :rm,
      problem = :problem,
      action = :action,
      recommendations_json = :recommendations_json,
      install_parts_json = :install_parts_json,
      updated_at = CURRENT_TIMESTAMP
    WHERE id = :id";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        ':branch' => $branch,
        ':status_mekanik' => $status_mekanik,
        ':pic' => $pic,
        ':partner' => $partner,
        ':in_time' => $in_time,
        ':out_time' => $out_time,
        ':vehicle' => $vehicle,
        ':nopol' => $nopol,
        ':date' => $date,
        ':serial_number' => $serial_number,
        ':unit_type' => $unit_type,
        ':year' => $year,
        ':hour_meter' => $hour_meter,
        ':nomor_lambung' => $nomor_lambung,
        ':customer' => $customer,
        ':location' => $location,
        ':job_type' => $job_type,
        ':status_unit' => $status_unit,
        ':problem_date' => $problem_date,
        ':rfu_date' => $rfu_date,
        ':lead_time_rfu' => $lead_time_rfu,
        ':pm' => $pm,
        ':rm' => $rm,
        ':problem' => $problem,
        ':action' => $action,
        ':recommendations_json' => $recommendations_json,
        ':install_parts_json' => $install_parts_json,
        ':id' => $id
    ]);

    // 2. Jika sukses, baca kembali data yang baru (SOLUSI MASALAH 1)
    if ($stmt->rowCount() > 0) {
        $selectSql = "SELECT * FROM update_jobs WHERE id = ? LIMIT 1";
        $selectStmt = $pdo->prepare($selectSql);
        $selectStmt->execute([$id]);
        $updatedJob = $selectStmt->fetch(PDO::FETCH_ASSOC);

        if ($updatedJob) {
            http_response_code(200);
            echo json_encode([
                'success' => true,
                'message' => 'Update successful',
                'data' => $updatedJob // Kirim objek Job yang diperbarui
            ]);
            exit;
        }
    }

    // Jika update gagal atau data tidak ditemukan setelah update
    http_response_code(404);
    echo json_encode(['success' => false, 'message' => 'Update failed or Job not found']);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
}

?>
