<?php
// create_update_job.php
require 'config.php'; // pastikan config.php mem-provide $pdo dan header JSON/CORS

// baca input
$raw = file_get_contents('php://input');
$input = json_decode($raw, true);

if (!$input || !is_array($input)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid JSON body or empty payload']);
    exit;
}

// helper untuk ambil value atau null
function v($arr, $k) {
    return isset($arr[$k]) && $arr[$k] !== '' ? $arr[$k] : null;
}

// ambil fields (sesuaikan nama field jika beda)
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
$pm = isset($input['pm']) ? (int)($input['pm'] ? 1 : 0) : 0;
$rm = isset($input['rm']) ? (int)($input['rm'] ? 1 : 0) : 0;
$problem = v($input,'problem');
$action = v($input,'action');

// parts: accept array or json string; store as JSON string or NULL
$recommendations_raw = $input['recommendations'] ?? null;
$install_parts_raw = $input['install_parts'] ?? null;

// Process parts - handle both array input and existing JSON logic
$recommendations_json = null;
if (isset($input['recommendations'])) {
    if (is_array($input['recommendations'])) {
        $recommendations_json = json_encode($input['recommendations'], JSON_UNESCAPED_UNICODE);
    } elseif (is_string($input['recommendations']) && !empty($input['recommendations'])) {
        $recommendations_json = $input['recommendations'];
    }
}

$install_parts_json = null;
if (isset($input['install_parts'])) {
    if (is_array($input['install_parts'])) {
        $install_parts_json = json_encode($input['install_parts'], JSON_UNESCAPED_UNICODE);
    } elseif (is_string($input['install_parts']) && !empty($input['install_parts'])) {
        $install_parts_json = $input['install_parts'];
    }
}

// minimal validation (sesuaikan aturan kamu)
if (empty($serial_number) && empty($customer)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'serial_number or customer is required']);
    exit;
}

try {
    $pdo->beginTransaction();

    $sql = "INSERT INTO update_jobs
      (branch,status_mekanik,pic,partner,in_time,out_time,vehicle,nopol,`date`,serial_number,unit_type,`year`,hour_meter,nomor_lambung,customer,location,job_type,status_unit,problem_date,rfu_date,lead_time_rfu,pm,rm,`problem`,`action`,recommendations_json,install_parts_json)
      VALUES
      (:branch,:status_mekanik,:pic,:partner,:in_time,:out_time,:vehicle,:nopol,:date,:serial_number,:unit_type,:year,:hour_meter,:nomor_lambung,:customer,:location,:job_type,:status_unit,:problem_date,:rfu_date,:lead_time_rfu,:pm,:rm,:problem,:action,:recommendations_json,:install_parts_json)";

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
    ]);

    $newId = (int)$pdo->lastInsertId();
    $pdo->commit();

    http_response_code(201);
    echo json_encode(['success' => true, 'message' => 'Created', 'id' => $newId]);
    exit;
} catch (PDOException $e) {
    if ($pdo->inTransaction()) $pdo->rollBack();
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database error: '.$e->getMessage()]);
    exit;
}
