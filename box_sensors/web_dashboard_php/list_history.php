<?php
// list_history.php - Returns list of archived match files

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$dir = '../data/history';

// Serve specific file if requested
if (isset($_GET['file'])) {
    $filename = basename($_GET['file']); // Security: basename prevents directory traversal
    $filepath = $dir . '/' . $filename;

    if (file_exists($filepath) && strpos($filename, '.json') !== false) {
        echo file_get_contents($filepath);
        exit;
    } else {
        http_response_code(404);
        echo json_encode(['error' => 'File not found']);
        exit;
    }
}

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