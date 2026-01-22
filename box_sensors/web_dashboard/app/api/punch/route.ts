import { NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';

// Simple in-memory storage for MVP
// In a real production app, this should be a database (PostgreSQL/Redis)
let recentPunches: any[] = [];

export async function GET() {
    return NextResponse.json(recentPunches);
}

export async function DELETE() {
    try {
        if (recentPunches.length > 0) {
            // Archive logic
            // Timestamp for filename: YYYY-MM-DD_HH-mm-ss
            const now = new Date();
            const format = (n: number) => n.toString().padStart(2, '0');
            const timestamp = `${now.getFullYear()}-${format(now.getMonth() + 1)}-${format(now.getDate())}_${format(now.getHours())}-${format(now.getMinutes())}-${format(now.getSeconds())}`;
            const filename = `match_${timestamp}.json`;

            // Path: c:\BoxingGymSensorsProject\box_sensors\web_dashboard -> ..\web_dashboard_php\history
            const historyDir = path.resolve(process.cwd(), '../web_dashboard_php/history');

            if (!fs.existsSync(historyDir)) {
                fs.mkdirSync(historyDir, { recursive: true });
            }

            const filePath = path.join(historyDir, filename);
            fs.writeFileSync(filePath, JSON.stringify(recentPunches, null, 2));
        }

        // Clear data
        recentPunches = [];
        return NextResponse.json({ success: true, message: 'Data reset and archived' });

    } catch (error) {
        console.error("Reset error:", error);
        return NextResponse.json({ success: false, error: 'Failed to reset' }, { status: 500 });
    }
}

export async function POST(request: Request) {
    try {
        const body = await request.json();
        const { deviceStr, oppositeDevice, punchCount, timestamp, sensorValue } = body;

        const newPunch = {
            id: Date.now().toString(),
            device: deviceStr || 'Unknown',
            punchBy: oppositeDevice || 'Unknown',
            count: punchCount,
            time: timestamp,
            force: sensorValue,
            receivedAt: new Date().toISOString()
        };

        // Add to start of list
        recentPunches.unshift(newPunch);

        // Keep only last 50 punches
        if (recentPunches.length > 50) {
            recentPunches = recentPunches.slice(0, 50);
        }

        return NextResponse.json({ success: true, punch: newPunch });
    } catch (error) {
        return NextResponse.json({ success: false, error: 'Invalid JSON' }, { status: 400 });
    }
}
