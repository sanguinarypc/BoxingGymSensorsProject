const express = require('express');
const fs = require('fs');
const path = require('path');
const cors = require('cors');
const bodyParser = require('body-parser');

const app = express();
const PORT = process.env.PORT || 3000;
const DATA_FILE = path.join(__dirname, 'data.json');

// Middleware
app.use(cors()); // Allow cross-origin requests (for Flutter app)
app.use(bodyParser.json());
app.use(express.static('public')); // Serve static files (dashboard)

// Helper to read data
function readData() {
    if (!fs.existsSync(DATA_FILE)) return [];
    try {
        const raw = fs.readFileSync(DATA_FILE, 'utf8');
        return JSON.parse(raw) || [];
    } catch (e) {
        return [];
    }
}

// Helper to write data
function writeData(data) {
    fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2));
}

// API: Get Data (Live Feed)
app.get('/api/data', (req, res) => {
    // Cache busting headers
    res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
    res.setHeader('Pragma', 'no-cache');
    res.setHeader('Expires', '0');

    // Clear data action
    if (req.query.action === 'clear') {
        writeData([]);
        return res.json({ success: true, message: 'Data cleared' });
    }

    const data = readData();
    // Return most recent first (like PHP version)
    // Assuming data is appended, so reverse it
    res.json(data.reverse());
});

// API: Receive Data (from Flutter App)
app.post('/api/data', (req, res) => {
    const rawData = req.body;

    // Map Flutter keys to Dashboard keys (Matching receiver.php logic)
    // Flutter sends: deviceStr, oppositeDevice, punchCount, timestamp, sensorValue, roundId
    const newData = {
        id: rawData.id || Date.now().toString(), // Helper for React keys
        device: rawData.deviceStr || 'Unknown',
        punchBy: rawData.oppositeDevice || 'Unknown', // <--- Crucial mapping
        count: rawData.punchCount || '0',
        time: rawData.timestamp || new Date().toTimeString().split(' ')[0],
        force: rawData.sensorValue || '0',
        round: rawData.roundId || '1',
        receivedAt: new Date().toISOString()
    };

    // Validate basics (Now checking the MAPPED object)
    if (!newData.punchBy) {
        return res.status(400).json({ error: 'Invalid data' });
    }

    const currentData = readData();
    currentData.push(newData);

    // Keep file size manageable (optional, matching generic safety)
    if (currentData.length > 2000) {
        currentData.shift(); // Remove oldest
    }

    writeData(currentData);
    console.log('Received punch:', newData);
    res.json({ success: true });
});

// Start Server
app.listen(PORT, () => {
    console.log(`Server running at http://localhost:${PORT}`);
});
