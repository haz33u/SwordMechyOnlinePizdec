/*
 * Run a Luau script inside the running Roblox Studio, from the command line.
 *
 * Claude Code binds its MCP servers once at session start, so a fix to the
 * wrapper does not reach an already-running session. This talks to the same
 * wrapper over stdio directly, which needs no session restart.
 *
 *   node tools/mcp_exec.js <path-to-lua-file>
 *
 * Prints whatever Studio returns, including the output of print() calls.
 */
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

const scriptPath = process.argv[2];
if (!scriptPath) {
    console.error('usage: node tools/mcp_exec.js <path-to-lua-file> [Edit|Server|Client]');
    process.exit(2);
}
const raw = fs.readFileSync(scriptPath, 'utf8');
// Edit mode is the default: the audit and install tools read ReplicatedStorage,
// which exists without entering Play, and Edit needs no running session.
const datamodel = process.argv[3] || 'Edit';

/*
 * execute_luau reports the chunk's RETURN VALUE, not its output. The tools in
 * tools/ are written for the Studio command bar, so they report through print()
 * and would come back as a bare `nil`.
 *
 * Wrapping the chunk in a function with a local `print` shadow captures those
 * lines and returns them as the value, so a command-bar script runs here
 * unmodified. Studio's own Output window still gets nothing, which is fine —
 * the point is to read the report here.
 */
const code = `
local __out = {}
local print = function(...)
	local n = select("#", ...)
	local parts = table.create(n)
	for i = 1, n do
		parts[i] = tostring((select(i, ...)))
	end
	table.insert(__out, table.concat(parts, "\\t"))
end
local __ok, __err = pcall(function()
${raw}
end)
if not __ok then
	table.insert(__out, "!! SCRIPT ERROR: " .. tostring(__err))
end
return table.concat(__out, "\\n")
`;

const wrapper = path.join(process.env.LOCALAPPDATA, 'Roblox', 'roblox-mcp-wrapper.js');
const proc = spawn(process.execPath, [wrapper], { stdio: ['pipe', 'pipe', 'inherit'] });

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
        try { msg = JSON.parse(line); } catch (e) { continue; }
        if (msg.id !== undefined && pending.has(msg.id)) {
            const resolve = pending.get(msg.id);
            pending.delete(msg.id);
            resolve(msg);
        }
    }
});

let nextId = 1;
function call(method, params) {
    const id = nextId++;
    return new Promise((resolve, reject) => {
        pending.set(id, resolve);
        proc.stdin.write(JSON.stringify({ jsonrpc: '2.0', id, method, params }) + '\n');
        // Studio can be mid-frame or showing a modal dialog; fail loudly rather
        // than hanging forever with no explanation.
        setTimeout(() => {
            if (pending.has(id)) {
                pending.delete(id);
                reject(new Error(`timeout waiting for ${method}`));
            }
        }, 120000);
    });
}

(async () => {
    await call('initialize', {
        protocolVersion: '2024-11-05',
        capabilities: {},
        clientInfo: { name: 'mcp_exec', version: '1.0.0' },
    });
    proc.stdin.write(JSON.stringify({ jsonrpc: '2.0', method: 'notifications/initialized' }) + '\n');

    const state = await call('tools/call', { name: 'get_studio_state', arguments: {} });
    if (state.result && Array.isArray(state.result.content)) {
        for (const c of state.result.content) console.error('[studio] ' + (c.text || ''));
    }

    const res = await call('tools/call', {
        name: 'execute_luau',
        arguments: { code, datamodel_type: datamodel },
    });

    if (res.error) {
        console.error('ERROR: ' + JSON.stringify(res.error, null, 2));
        process.exit(1);
    }
    const content = res.result && res.result.content;
    if (Array.isArray(content)) {
        for (const c of content) console.log(c.text !== undefined ? c.text : JSON.stringify(c));
    } else {
        console.log(JSON.stringify(res.result, null, 2));
    }
    process.exit(0);
})().catch((err) => {
    console.error('FAILED: ' + err.message);
    process.exit(1);
});
