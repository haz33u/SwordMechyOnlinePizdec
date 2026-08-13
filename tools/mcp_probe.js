/*
 * Probe the Studio MCP server directly, without the wrapper mcp_exec.js expects.
 *
 * mcp_exec.js / mcp_list.js spawn %LOCALAPPDATA%\Roblox\roblox-mcp-wrapper.js,
 * which does not exist on this machine. StudioMCP.exe does, and mcp.bat is the
 * launcher Roblox itself installs, so talk to that over stdio instead.
 *
 *   node tools/mcp_probe.js
 *
 * Prints the tool list plus get_studio_state, which is enough to tell whether a
 * Studio session is actually reachable.
 */
const { spawn } = require('child_process');
const path = require('path');

const bat = path.join(process.env.LOCALAPPDATA, 'Roblox', 'mcp.bat');
const proc = spawn(bat, [], { stdio: ['pipe', 'pipe', 'inherit'], shell: true });

let buf = '';
const pending = new Map();

proc.stdout.on('data', (chunk) => {
    buf += chunk.toString();
    let nl;
    while ((nl = buf.indexOf('\n')) >= 0) {
        const line = buf.slice(0, nl).trim();
        buf = buf.slice(nl + 1);
        if (!line) continue;
        let msg;
        try { msg = JSON.parse(line); } catch (e) { console.error('[raw] ' + line); continue; }
        if (msg.id !== undefined && pending.has(msg.id)) {
            const resolve = pending.get(msg.id);
            pending.delete(msg.id);
            resolve(msg);
        }
    }
});

proc.on('error', (e) => { console.error('SPAWN FAILED: ' + e.message); process.exit(1); });
proc.on('exit', (c) => { console.error('[mcp exited with code ' + c + ']'); });

let nextId = 1;
function call(method, params) {
    const id = nextId++;
    return new Promise((resolve, reject) => {
        pending.set(id, resolve);
        proc.stdin.write(JSON.stringify({ jsonrpc: '2.0', id, method, params }) + '\n');
        setTimeout(() => {
            if (pending.has(id)) {
                pending.delete(id);
                reject(new Error(`timeout waiting for ${method}`));
            }
        }, 20000);
    });
}

(async () => {
    const init = await call('initialize', {
        protocolVersion: '2024-11-05',
        capabilities: {},
        clientInfo: { name: 'mcp_probe', version: '1.0.0' },
    });
    console.log('=== initialize ===');
    console.log(JSON.stringify(init.result, null, 2));

    proc.stdin.write(JSON.stringify({ jsonrpc: '2.0', method: 'notifications/initialized' }) + '\n');

    const tools = await call('tools/list', {});
    console.log('=== tools ===');
    for (const t of (tools.result && tools.result.tools) || []) {
        console.log(t.name + ' :: ' + JSON.stringify(t.inputSchema));
    }

    const state = await call('tools/call', { name: 'get_studio_state', arguments: {} });
    console.log('=== studio state ===');
    console.log(JSON.stringify(state.result || state.error, null, 2));
    process.exit(0);
})().catch((err) => { console.error('FAILED: ' + err.message); process.exit(1); });
