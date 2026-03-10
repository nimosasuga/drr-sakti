<?php
// debug/api_debug.php
// TEMPORARY. Remove after use.

ini_set('display_errors', 1);
error_reporting(E_ALL);
$logFile = '/tmp/drr_api_debug.log';
file_put_contents($logFile, "[".date('c')."] API debug start\n", FILE_APPEND);

header('Content-Type: text/plain; charset=utf-8');

$configCandidates = [
    __DIR__ . '/../api/config.php',
    __DIR__ . '/../../api/config.php',
    __DIR__ . '/../config.php',
    __DIR__ . '/config.php',
];

$found=false;
foreach($configCandidates as $c){
    file_put_contents($logFile, "Check: $c\n", FILE_APPEND);
    if (file_exists($c)){ require_once $c; $found=$c; break; }
}
if (!$found){ echo "config not found\n"; file_put_contents($logFile, "config not found\n", FILE_APPEND); exit; }
if (!isset($pdo) || !($pdo instanceof PDO)) { echo "pdo missing\n"; file_put_contents($logFile, "pdo missing\n", FILE_APPEND); exit; }

$token = isset($_GET['token']) ? trim($_GET['token']) : '';
echo "Token: {$token}\n";
file_put_contents($logFile, "Token: {$token}\n", FILE_APPEND);

try {
    $stmt = $pdo->prepare("SELECT id FROM unit_assets WHERE TRIM(qr_token)=:token LIMIT 2000");
    $stmt->execute([':token'=>$token]);
    $ids = $stmt->fetchAll(PDO::FETCH_COLUMN);
    echo "Unit count: ".count($ids)."\n";
    file_put_contents($logFile, "Unit count: ".count($ids)."\n", FILE_APPEND);

    // show first 30 ids
    echo "Unit IDs sample: ".implode(',', array_slice($ids,0,30))."\n";

    // attempt to fetch jobs via IN clause (if many ids may exceed param limits)
    if (count($ids) > 0) {
        $ph = implode(',', array_fill(0, count($ids), '?'));
        $sql = "SELECT COUNT(*) FROM update_jobs WHERE unit_id IN ($ph)";
        $stmt2 = $pdo->prepare($sql);
        $stmt2->execute($ids);
        $countJobs = $stmt2->fetchColumn();
        echo "Jobs count for unit_ids: {$countJobs}\n";
        file_put_contents($logFile, "Jobs count: {$countJobs}\n", FILE_APPEND);
    } else {
        echo "No unit ids\n";
    }
} catch (Exception $e) {
    echo "EXC: ".$e->getMessage()."\n";
    file_put_contents($logFile, "EXC: ".$e->getMessage()."\n".$e->getTraceAsString(), FILE_APPEND);
}