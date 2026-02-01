<?php
// receiver.php - Handles incoming sensor data

// specific CORS headers not needed if on same domain, but good for mobile app
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");
header("Cache-Control: no-cache, must-revalidate");
header("Expires: Sat, 26 Jul 1997 05:00:00 GMT"); // Date in the past
header("Content-Type: application/json");

// Handle DELETE request (or GET with ?action=clear) to reset data
if (
    ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_GET['action']) && $_GET['action'] === 'clear') ||
    ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['action']) && $_GET['action'] === 'clear')
) {


    // Archive before clearing
    $dataDir = '../data';
    if (!is_dir($dataDir))
        mkdir($dataDir, 0777, true);

    $file = $dataDir . '/data.json';
    if (file_exists($file)) {
        $content = file_get_contents($file);
        $data = json_decode($content, true);
        if ($data && count($data) > 0) {
            // Check if there is actual data to save
            $historyDir = $dataDir . '/history';
            if (!is_dir($historyDir)) {
                mkdir($historyDir, 0777, true);
            }
            // Use timestamp of FIRST item (latest) or current time
            $timestamp = date('Y-m-d_H-i-s');
            // Check if we can get a better timestamp from data
            if (isset($data[0]['receivedAt'])) {
                // Clean up receivedAt for filename if desired, but current time is safer collision-wise
            }

            $archiveFile = $historyDir . '/match_' . $timestamp . '.json';
            file_put_contents($archiveFile, $content);
        }
    }

    file_put_contents($file, json_encode([]));
    echo json_encode(["status" => "success", "message" => "Data cleared"]);
    exit;
}

// Handle GET request - return data
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $file = '../data/data.json';
    if (file_exists($file)) {
        echo file_get_contents($file);
    } else {
        echo "[]";
    }
    exit;
}

// Handle POST request - save data
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Get raw POST data
    $json = file_get_contents('php://input');
    $data = json_decode($json, true);

    if ($data) {
        // Strict Validation: Reject if main fields are missing
        if (!isset($data['oppositeDevice']) || !isset($data['sensorValue'])) {
            http_response_code(400);
            die(json_encode(["error" => "Missing oppositeDevice or sensorValue"]));
        }

        $dataDir = '../data';
        if (!is_dir($dataDir))
            mkdir($dataDir, 0777, true);
        $file = $dataDir . '/data.json';

        // Read existing data
        $currentData = [];
        if (file_exists($file)) {
            $fileContent = file_get_contents($file);
            $currentData = json_decode($fileContent, true);
            if (!is_array($currentData)) {
                $currentData = [];
            }
        }

        // Create new record
        $newRecord = [
            'id' => uniqid(),
            'device' => $data['deviceStr'] ?? 'Unknown',
            'punchBy' => $data['oppositeDevice'] ?? 'Unknown',
            'count' => $data['punchCount'] ?? '0',
            'time' => $data['timestamp'] ?? date('H:i:s'),
            'force' => $data['sensorValue'] ?? '0',
            'round' => $data['roundId'] ?? '1',
            'receivedAt' => date('c')
        ];

        // Add to TOP of list
        array_unshift($currentData, $newRecord);

        // Keep only last 500 items (increased history)
        if (count($currentData) > 500) {
            $currentData = array_slice($currentData, 0, 500);
        }

        // Save back to file
        if (file_put_contents($file, json_encode($currentData, JSON_PRETTY_PRINT))) {
            echo json_encode(["status" => "success", "record" => $newRecord]);
        } else {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => "Failed to write file"]);
        }
    } else {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "Invalid JSON"]);
    }
    exit;
}
?>