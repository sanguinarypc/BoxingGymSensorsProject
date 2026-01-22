import { NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';

export async function GET(
    request: Request,
    { params }: { params: Promise<{ filename: string }> }
) {
    try {
        const { filename } = await params;

        // Validate filename to prevent directory traversal
        if (!filename || !filename.startsWith('match_') || !filename.endsWith('.json') || filename.includes('..')) {
            return NextResponse.json({ error: 'Invalid filename' }, { status: 400 });
        }

        const historyDir = path.resolve(process.cwd(), '../web_dashboard_php/history');
        const filePath = path.join(historyDir, filename);

        if (!fs.existsSync(filePath)) {
            return NextResponse.json({ error: 'File not found' }, { status: 404 });
        }

        const content = fs.readFileSync(filePath, 'utf-8');
        const data = JSON.parse(content);

        return NextResponse.json(data);
    } catch (error) {
        console.error('Failed to read history file:', error);
        return NextResponse.json({ error: 'Failed to read history file' }, { status: 500 });
    }
}
