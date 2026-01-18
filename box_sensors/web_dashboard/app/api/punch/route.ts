import { NextResponse } from 'next/server';

// Simple in-memory storage for MVP
// In a real production app, this should be a database (PostgreSQL/Redis)
let recentPunches: any[] = [];

export async function GET() {
    return NextResponse.json(recentPunches);
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
