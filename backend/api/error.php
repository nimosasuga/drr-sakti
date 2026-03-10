<?php
// File: api/error.php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$error_code = isset($_GET['code']) ? intval($_GET['code']) : 404;

$error_messages = [
    400 => "Bad Request",
    401 => "Unauthorized", 
    403 => "Forbidden",
    404 => "Endpoint Not Found",
    500 => "Internal Server Error"
];

$message = $error_messages[$error_code] ?? "Unknown Error";

http_response_code($error_code);

echo json_encode([
    "success" => false,
    "error" => [
        "code" => $error_code,
        "message" => $message,
        "domain" => "appsheetcore.my.id"
    ]
], JSON_PRETTY_PRINT);
?>