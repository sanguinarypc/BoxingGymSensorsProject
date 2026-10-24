const assert = require('node:assert/strict');
const { fork } = require('node:child_process');
const { once } = require('node:events');
const http = require('node:http');
const { gzipSync } = require('node:zlib');

// Run only against an isolated child on a random loopback port, never production.
if (process.argv[2] === '--fixture') {
    const { createRequire } = require('node:module');
    const path = require('node:path');
    const load = createRequire(path.resolve(process.env.DASHBOARD_TEST_ROOT || path.join(__dirname, '..'), 'package.json'));
    const express = load('express');
    const app = express();
    app.use(process.argv[3] === 'express'
        ? express.json({ limit: '1mb' })
        : load('body-parser').json({ limit: '1mb' }));
    app.post('/', (req, res) => res.json(req.body));
    app.get('/health', (req, res) => res.sendStatus(200));
    app.use((err, req, res, next) => res.sendStatus(400));
    const server = app.listen(0, '127.0.0.1', () => {
        process.send(server.address().port);
    });
} else {
    const { test } = require('node:test');
    for (const parser of ['body-parser', 'express']) {
        test(`${parser}: survives trailing gzip request bytes`, { timeout: 8000 }, async (t) => {
            const child = fork(__filename, ['--fixture', parser], {
                stdio: ['ignore', 'ignore', 'pipe', 'ipc']
            });
            let errors = '';
            child.stderr.on('data', (chunk) => { errors += chunk; });
            t.after(() => child.kill());
            const port = await Promise.race([
                once(child, 'message').then(([value]) => value),
                once(child, 'exit').then(([code]) => {
                    throw new Error(`Fixture exited ${code}: ${errors}`);
                })
            ]);
            // A zero terminates the gzip member; later bytes reach the finished decoder.
            // See the upstream regression for GHSA-27r3-jxmh-p828.
            const body = Buffer.concat([
                gzipSync('{"ok":true}'), Buffer.from([0]), Buffer.alloc(100 * 1024, 0x58)
            ]);
            const request = http.request({
                host: '127.0.0.1', port, method: 'POST', path: '/',
                headers: {
                    'Content-Type': 'application/json',
                    'Content-Encoding': 'gzip',
                    'Content-Length': body.length
                }
            });
            request.on('error', () => {});
            const responseDone = new Promise((resolve) => {
                request.on('response', (response) => {
                    response.resume();
                    response.on('end', () => resolve(response.statusCode));
                });
                request.on('error', () => resolve(null));
            });
            t.after(() => request.destroy());
            request.end(body);
            const responseStatus = await responseDone;
            await new Promise((resolve) => setTimeout(resolve, 250));
            assert.equal(child.exitCode, null, `Parser crashed: ${errors}`);
            assert.equal(responseStatus, 200);
            const status = await new Promise((resolve, reject) => {
                const health = http.get({ host: '127.0.0.1', port, path: '/health' }, (response) => {
                    response.resume();
                    resolve(response.statusCode);
                });
                health.on('error', reject);
                health.setTimeout(1500, () => health.destroy(new Error('Health timeout')));
            });
            assert.equal(status, 200);
        });
    }
}
