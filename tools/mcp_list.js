/*
 * Print the tool list the Studio MCP wrapper exposes, with each tool's input
 * schema. Used to confirm the wrapper is talking to the running Studio and to
 * learn the exact argument names before scripting against it.
 */
const { spawn } = require('child_process');
const path = require('path');

const wrapper = path.join(process.env.LOCALAPPDATA, 'Roblox', 'roblox-mcp-wrapper.js');
const proc = spawn(process.execPath, [wrapper], { stdio: ['pipe', 'pipe', 'inherit'] });

let buf = '';
proc.stdout.on('data', (c) => {
    buf += c.toString();
    let nl;
    while ((nl = buf.indexOf('\n')) >= 0) {
        const line = buf.slice(0, nl).trim();
        buf = buf.slice(nl + 1);
        if (!line) continue;
        let m;
        try { m = JSON.parse(line); } catch (e) { continue; }
        if (m.id === 2) {
            for (const t of m.result.tools) {
                console.log('=== ' + t.name);
                console.log(JSON.stringify(t.inputSchema));
            }
            process.exit(0);
        }
    }
});

proc.stdin.write(JSON.stringify({
    jsonrpc: '2.0', id: 1, method: 'initialize',
    params: { protocolVersion: '2024-11-05', capabilities: {}, clientInfo: { name: 'mcp_list', version: '1.0.0' } },
}) + '\n');

setTimeout(() => {
    proc.stdin.write(JSON.stringify({ jsonrpc: '2.0', method: 'notifications/initialized' }) + '\n');
    proc.stdin.write(JSON.stringify({ jsonrpc: '2.0', id: 2, method: 'tools/list', params: {} }) + '\n');
}, 800);

setTimeout(() => { console.error('TIMEOUT'); process.exit(1); }, 30000);
