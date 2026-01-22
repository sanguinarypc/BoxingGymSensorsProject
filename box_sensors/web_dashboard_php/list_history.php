<?php
// list_history.php - Returns list of archived match files

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$dir = 'history';
$files = [];

if (is_dir($dir)) {
    $scanned = scandir($dir);
    foreach ($scanned as $file) {
        if ($file !== '.' && $file !== '..' && strpos($file, '.json') !== false) {
            // Check if it follows our pattern match_...
            if (strpos($file, 'match_') === 0) {
                // Get timestamp/size
                $path = $dir . '/' . $file;
                $files[] = [
                    'filename' => $file, // filename for fetching
                    'name' => str_replace(['match_', '.json', '_'], ['', '', ' '], $file), // Display Name
                    'time' => filemtime($path),
                    'size' => filesize($path)
                ];
            }
        }
    }
}

// Sort by time DESC (newest first)
usort($files, function ($a, $b) {
    return $b['time'] - $a['time'];
});

echo json_encode($files);
?>