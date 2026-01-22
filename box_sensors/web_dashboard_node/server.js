const express = require('express');
const fs = require('fs');
const path = require('path');
const cors = require('cors');
const bodyParser = require('body-parser');

const app = express();
const PORT = process.env.PORT || 3000;
const DATA_FILE = path.join(__dirname, 'data.json');
const HISTORY_DIR = path.join(__dirname, 'history');

// Ensure history dir exists
if (!fs.existsSync(HISTORY_DIR)) {
    fs.mkdirSync(HISTORY_DIR);
}

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
        // Archive first
        const currentData = readData();
        if (currentData.length > 0) {
            const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
            const archivePath = path.join(HISTORY_DIR, `match_${timestamp}.json`);
            fs.writeFileSync(archivePath, JSON.stringify(currentData, null, 2));
        }

        writeData([]);
        return res.json({ success: true, message: 'Data cleared and archived' });
    }

    const data = readData();
    // Return most recent first (like PHP version)
    // Assuming data is appended, so reverse it
    res.json(data.reverse());
});

// API: List History
app.get('/api/history', (req, res) => {
    try {
        const files = fs.readdirSync(HISTORY_DIR)
            .filter(f => f.startsWith('match_') && f.endsWith('.json'))
            .map(f => {
                const stat = fs.statSync(path.join(HISTORY_DIR, f));
                return {
                    filename: f,
                    name: f.replace('match_', '').replace('.json', '').replace(/-/g, ' '),
                    time: Math.floor(stat.mtimeMs / 1000), // Unix timestamp in seconds
                    size: stat.size
                };
            })
            .sort((a, b) => b.time - a.time); // Newest first

        res.json(files);
    } catch (e) {
        res.status(500).json({ error: 'Failed to list history' });
    }
});

// API: Get History File
app.get('/api/history/:filename', (req, res) => {
    const filename = req.params.filename;
    // Security check: simple alphanumeric + dots + dashes
    if (!/^[a-zA-Z0-9_.-]+$/.test(filename)) return res.status(400).send('Invalid filename');

    const filepath = path.join(HISTORY_DIR, filename);
    if (fs.existsSync(filepath)) {
        res.sendFile(filepath);
    } else {
        res.status(404).send('Not found');
    }
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
