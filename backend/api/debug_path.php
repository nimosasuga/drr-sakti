<?php
header('Content-Type: text/plain');

echo "=== PATH DEBUGGING ===\n\n";

echo "1. Current File Location:\n";
echo "   __FILE__: " . __FILE__ . "\n";
echo "   __DIR__: " . __DIR__ . "\n\n";

echo "2. Testing Different Paths:\n";

$testPaths = [
    '__DIR__ . "/../config.php"' => __DIR__ . '/../config.php',
    '__DIR__ . "/../../config.php"' => __DIR__ . '/../../config.php',
    'realpath(__DIR__ . "/../config.php")' => realpath(__DIR__ . '/../config.php') ?: 'FALSE',
    '/home/n1576996/public_html/appsheetcore.my.id/config.php' => '/home/n1576996/public_html/appsheetcore.my.id/config.php',
];

foreach ($testPaths as $label => $path) {
    $exists = file_exists($path) ? "✅ EXISTS" : "❌ NOT FOUND";
    echo "   $label\n";
    echo "   => $path\n";
    echo "   Status: $exists\n\n";
}

echo "3. Check Directory Contents:\n";

$apiDir = __DIR__;
echo "   Files in " . $apiDir . ":\n";
$files = scandir($apiDir);
foreach ($files as $file) {
    if ($file != '.' && $file != '..') {
        echo "   - $file\n";
    }
}

echo "\n4. Check Parent Directory:\n";
$parentDir = dirname(__DIR__);
echo "   Files in " . $parentDir . ":\n";
$files = scandir($parentDir);
foreach ($files as $file) {
    if ($file != '.' && $file != '..') {
        echo "   - $file\n";
    }
}
?>