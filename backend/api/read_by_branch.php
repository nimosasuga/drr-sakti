<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Include files
include_once 'config/database.php';
include_once 'objects/unit.php';

try {
    $database = new Database();
    $db = $database->getConnection();

    $unit = new Unit($db);

    // Get branch from query parameter
    $branch = isset($_GET['branch']) ? $_GET['branch'] : '';

    if (!empty($branch)) {
        // Get units by branch
        $stmt = $unit->readByBranch($branch);
        $num = $stmt->rowCount();

        if ($num > 0) {
            $units_arr = array();
            $units_arr["data"] = array();
            
            while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                extract($row);
                
                $unit_item = array(
                    "id" => $id,
                    "supported_by" => $supported_by,
                    "customer" => $customer,
                    "location" => $location,
                    "branch" => $branch,
                    "serial_number" => $serial_number,
                    "unit_type" => $unit_type,
                    "year" => $year,
                    "status" => $status,
                    "delivery" => $delivery,
                    "jenis_unit" => $jenis_unit,
                    "note" => $note,
                    "created_at" => $created_at,
                    "updated_at" => $updated_at
                );
                
                array_push($units_arr["data"], $unit_item);
            }
            
            http_response_code(200);
            echo json_encode($units_arr);
        } else {
            http_response_code(200);
            echo json_encode(array("data" => array()));
        }
    } else {
        http_response_code(400);
        echo json_encode(array("message" => "Branch parameter is required."));
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(array(
        "message" => "Server error: " . $e->getMessage(),
        "error" => true
    ));
}
?>