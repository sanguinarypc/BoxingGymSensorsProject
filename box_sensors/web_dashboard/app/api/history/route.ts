import { NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';

export async function GET() {
    try {
        // Point to the adjacent PHP project's history folder
        // Current dir is web_dashboard/app/api/history
        // We need to go up to box_sensors root then into web_dashboard_php
        const historyDir = path.resolve(process.cwd(), '../web_dashboard_php/history');

        if (!fs.existsSync(historyDir)) {
            return NextResponse.json([]);
        }

        const files = fs.readdirSync(historyDir)
            .filter(file => file.startsWith('match_') && file.endsWith('.json'))
            .map(file => {
                const filePath = path.join(historyDir, file);
                const stats = fs.statSync(filePath);

                // Parse friendly name from filename: match_2026-01-22_17-13-04.json -> 2026-01-22 17-13-04
                const name = file.replace('match_', '').replace('.json', '').replace('_', ' ');

                return {
                    filename: file,
                    name: name,
                    time: stats.mtime.getTime() / 1000, // Unix timestamp in seconds to match PHP
                    size: stats.size
                };
            })
            // Sort by time DESC (newest first)
            .sort((a, b) => b.time - a.time);

        return NextResponse.json(files);
    } catch (error) {
        console.error('Failed to list history:', error);
        return NextResponse.json({ error: 'Failed to list history' }, { status: 500 });
    }
}
