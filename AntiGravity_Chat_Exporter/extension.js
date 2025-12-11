const vscode = require('vscode');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

/**
 * @param {vscode.ExtensionContext} context
 */
function activate(context) {
    // DEFAULT CONFIG
    const defaults = {
        auto: true,
        interval: 10,
        exportDir: 'C:\\AntiGravityExt\\AntiGravity_Ghost_Agent\\Exports',
        formats: { json: true, md: true, html: false, csv: false },
        scope: 'all', // all, user, agent
        limit: 0, // 0 = all
        sort: 'asc', // asc (old->new), desc (new->old)
        timestamp: true,
        mode: 'overwrite' // overwrite, history
    };

    let config = context.globalState.get('exporterConfig', defaults);

    // Integrity Checks
    if (!config.formats) config.formats = defaults.formats;

    if (!fs.existsSync(config.exportDir)) {
        try { fs.mkdirSync(config.exportDir, { recursive: true }); } catch (e) { }
    }

    let loopHandle = null;
    let lastHash = '';

    // --- HELPER: FORMAT DATE ---
    const getTimestamp = () => new Date().toLocaleTimeString();

    // --- PIPELINE: TRANSFORMER ---
    const transformData = (rawJson) => {
        let messages = [];
        try {
            const parsed = JSON.parse(rawJson);
            const rawMsgs = Array.isArray(parsed) ? parsed : (parsed.requests || []);

            // Normalize
            rawMsgs.forEach(m => {
                if (m.message && m.message.text) {
                    // Request/Response Tuple
                    if (config.scope !== 'agent') {
                        messages.push({ role: 'USER', text: m.message.text, time: getTimestamp() });
                    }
                    if (config.scope !== 'user' && m.response) {
                        m.response.forEach(r => messages.push({ role: 'AGENT', text: r.value, time: getTimestamp() }));
                    }
                } else if (m.role && m.content) {
                    // Linear Format
                    const role = m.role.toUpperCase();
                    if (config.scope === 'all' || config.scope.toUpperCase() === role) {
                        messages.push({ role, text: m.content, time: getTimestamp() });
                    }
                }
            });

            // Parse Limits & Sort
            // Native is usually ASC.
            if (config.sort === 'desc') messages.reverse();

            if (config.limit > 0) {
                // If DESC, Take First N (Latest). If ASC, Take Last N (Latest)?? 
                // Usually user wants "Last 15 Messages".
                // If ASC (Old->New), taking slice(-N) gives latest.
                // If DESC (New->Old), taking slice(0, N) gives latest.
                // Let's implement simple slicing based on viewing preferences.
                // Actually user asked for "Block selection".
                // We'll just slice the array.
                messages = messages.slice(-config.limit); // Default to "Latest N" logic for sanity
                if (config.limit_strategy === 'first') messages = messages.slice(0, config.limit);
            }

        } catch (e) { console.error('Parse Error', e); }
        return messages;
    };

    // --- PIPELINE: WRITERS ---
    const writeFiles = (messages, baseName) => {
        const timeFunc = (t) => config.timestamp ? `[${t}] ` : '';

        // 1. MARKDOWN
        if (config.formats.md) {
            let content = `# Chat Export\n\n`;
            messages.forEach(m => {
                content += `### ${m.role === 'USER' ? '👤' : '🤖'} ${m.role} ${timeFunc(m.time)}\n${m.text}\n\n---\n\n`;
            });
            fs.writeFileSync(path.join(config.exportDir, baseName + '.md'), content);
        }

        // 2. HTML
        if (config.formats.html) {
            let html = `<html><body style="background:#1e1e1e;color:#ccc;font-family:sans-serif;max-width:800px;margin:2rem auto;">`;
            messages.forEach(m => {
                const color = m.role === 'USER' ? '#4ec9b0' : '#ce9178';
                const align = m.role === 'USER' ? 'right' : 'left';
                html += `<div style="text-align:${align};margin-bottom:1rem;padding:1rem;background:#252526;border-left:4px solid ${color}">
                    <div style="font-size:0.8rem;opacity:0.5;margin-bottom:0.5rem">${m.role} ${timeFunc(m.time)}</div>
                    <div style="white-space:pre-wrap">${m.text.replace(/</g, '&lt;')}</div>
                </div>`;
            });
            html += `</body></html>`;
            fs.writeFileSync(path.join(config.exportDir, baseName + '.html'), html);
        }

        // 3. CSV
        if (config.formats.csv) {
            let csv = `Role,Time,Content\n`;
            messages.forEach(m => {
                const safeText = `"${m.text.replace(/"/g, '""')}"`;
                csv += `${m.role},${m.time},${safeText}\n`;
            });
            fs.writeFileSync(path.join(config.exportDir, baseName + '.csv'), csv);
        }

        // 4. JSON (Processed)
        if (config.formats.json) {
            fs.writeFileSync(path.join(config.exportDir, baseName + '.json'), JSON.stringify(messages, null, 2));
        }
    };

    // --- PIPELINE: EXECUTOR ---
    const runExport = async (manual = false) => {
        try {
            const swapPath = path.join(config.exportDir, '.swap.json');

            // Native Dump
            await vscode.commands.executeCommand('workbench.action.chat.export', vscode.Uri.file(swapPath));

            setTimeout(() => {
                if (!fs.existsSync(swapPath)) return;

                const raw = fs.readFileSync(swapPath, 'utf8');

                // Smart Check: Hash to avoid re-writing if nothing changed
                const currentHash = crypto.createHash('md5').update(raw).digest('hex');
                if (!manual && currentHash === lastHash) return; // Skip
                lastHash = currentHash;

                // Process
                const messages = transformData(raw);

                // Naming
                const baseName = config.mode === 'history'
                    ? `Chat_${new Date().toISOString().replace(/[:.]/g, '-')}`
                    : 'Chat_History';

                writeFiles(messages, baseName);

                if (manual && config.notifications) vscode.window.setStatusBarMessage('$(check) Exported', 2000);

            }, 500); // 500ms debounce
        } catch (e) {
            console.error('Export Failed', e);
        }
    };

    const startLoop = () => {
        if (loopHandle) clearInterval(loopHandle);
        if (config.auto) loopHandle = setInterval(() => runExport(false), config.interval * 1000);
    };

    // --- UI: SETTINGS ---
    vscode.commands.registerCommand('antigravity.exporter.configure', async () => {
        const getFormatStr = () => Object.entries(config.formats).filter(x => x[1]).map(x => x[0].toUpperCase()).join('+');

        const items = [
            { label: '⚙️ Toggle Formats', description: `Current: ${getFormatStr()}`, action: 'formats' },
            { label: '🎯 Toggle Scope', description: `Current: ${config.scope.toUpperCase()}`, action: 'scope' },
            { label: '🔢 Message Limit', description: config.limit === 0 ? 'ALL' : `Last ${config.limit}`, action: 'limit' },
            { label: '🔃 Sort Order', description: config.sort === 'asc' ? 'Oldest -> Newest' : 'Newest -> Oldest', action: 'sort' },
            { label: '🕒 Timestamps', description: config.timestamp ? 'ON' : 'OFF', action: 'timestamp' },
            { label: '📜 History Mode', description: config.mode, action: 'mode' },
            { label: '📂 Export Folder', description: config.exportDir, action: 'dir' },
            { label: '🏃 Auto-Export', description: config.auto ? `ON (${config.interval}s)` : 'OFF', action: 'auto' },
            { label: '💾 EXPORT NOW', description: 'Force run', action: 'now' }
        ];

        const sel = await vscode.window.showQuickPick(items, { placeHolder: 'AntiGravity Exporter Configuration' });
        if (!sel) return;

        // Sub-Menus
        if (sel.action === 'formats') {
            const fSel = await vscode.window.showQuickPick(
                Object.keys(config.formats).map(k => ({ label: k.toUpperCase(), picked: config.formats[k] })),
                { canPickMany: true }
            );
            if (fSel) {
                Object.keys(config.formats).forEach(k => config.formats[k] = false);
                fSel.forEach(x => config.formats[x.label.toLowerCase()] = true);
            }
        }
        else if (sel.action === 'scope') {
            const s = await vscode.window.showQuickPick(['all', 'user', 'agent']);
            if (s) config.scope = s;
        }
        else if (sel.action === 'limit') {
            const n = await vscode.window.showInputBox({ prompt: '0 for ALL, or number for Limit' });
            if (n) config.limit = parseInt(n);
        }
        else if (sel.action === 'sort') {
            config.sort = config.sort === 'asc' ? 'desc' : 'asc';
        }
        else if (sel.action === 'timestamp') {
            config.timestamp = !config.timestamp;
        }
        else if (sel.action === 'mode') {
            config.mode = config.mode === 'overwrite' ? 'history' : 'overwrite';
        }
        else if (sel.action === 'dir') {
            const uri = await vscode.window.showOpenDialog({ canSelectFolders: true });
            if (uri && uri[0]) config.exportDir = uri[0].fsPath;
        }
        else if (sel.action === 'auto') {
            if (config.auto) {
                config.auto = false;
            } else {
                config.auto = true;
                const i = await vscode.window.showInputBox({ prompt: 'Interval (seconds)?', value: '10' });
                if (i) config.interval = parseInt(i);
            }
        }
        else if (sel.action === 'now') {
            runExport(true);
            return;
        }

        await context.globalState.update('exporterConfig', config);
        startLoop();
        vscode.window.showInformationMessage('Configuration Updated');
    });

    vscode.commands.registerCommand('antigravity.exportChatNow', () => runExport(true));

    startLoop();
    setTimeout(() => runExport(false), 5000);
}

function deactivate() { }
module.exports = { activate, deactivate };
