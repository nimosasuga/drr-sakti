<?php
echo "<h1>Testing Config Path</h1>";

$paths = [
    "/../config.php" => __DIR__ . '/../config.php',
    "/../../config.php" => __DIR__ . '/../../config.php',
    "/../../../config.php" => __DIR__ . '/../../../config.php',
];

foreach ($paths as $label => $fullPath) {
    $exists = file_exists($fullPath) ? "✅ EXISTS" : "❌ NOT FOUND";
    echo "<p>$label => $fullPath<br>Status: $exists</p>";
}

// Also try to find it
echo "<h2>Using find command output</h2>";
echo "Please run: find /home/n1576996/public_html -name config.php";
?>