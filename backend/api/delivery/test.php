<?php
header('Content-Type: application/json');
echo json_encode([
    'ok' => true,
    'message' => 'PHP is working!',
    'php_version' => phpversion(),
]);
?>