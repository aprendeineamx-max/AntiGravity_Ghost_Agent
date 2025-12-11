const vscode = require('vscode');
const fs = require('fs');
const path = require('path');

/**
 * @param {vscode.ExtensionContext} context
 */
function activate(context) {
    // 1. Immediate Proof of Life (File System) & Status Bar
    try { fs.writeFileSync('C:\\AntiGravityExt\\HOOK_ALIVE.txt', `Active at ${new Date().toISOString()}`); } catch (e) { }

    const config = vscode.workspace.getConfiguration();
    config.update('workbench.colorCustomizations', {
        "statusBar.background": "#af00db",
        "statusBar.foreground": "#ffffff"
    }, vscode.ConfigurationTarget.Global);

    vscode.window.showInformationMessage('👻 ANTIGRAVITY HOOK: ONLINE & LISTENING', { modal: false });

    // 2. The Bridge: Watch for Commands from OmniGod
    const cmdPath = 'C:\\AntiGravityExt\\GHOST_CMD.txt';

    // Ensure file exists
    if (!fs.existsSync(cmdPath)) { fs.writeFileSync(cmdPath, 'IDLE'); }

    console.log(`[Ghost] Watching ${cmdPath}`);

    // Watcher Logic
    const watcher = fs.watch(cmdPath, async (eventType, filename) => {
        if (eventType === 'change') {
            try {
                const cmd = fs.readFileSync(cmdPath, 'utf8').trim();

                if (cmd === 'SUBMIT') {
                    vscode.window.showInformationMessage('👻 GHOST COMMAND: SUBMIT RECV');

                    // The Magic Internal Command
                    await vscode.commands.executeCommand('antigravity.agent.acceptAgentStep');

                    // Reset to avoid loops
                    fs.writeFileSync(cmdPath, 'IDLE');
                    console.log('[Ghost] Executed SUBMIT and reset to IDLE');
                }
            } catch (err) {
                console.error('[Ghost] Error reading command:', err);
            }
        }
    });

    context.subscriptions.push({ dispose: () => watcher.close() });

    // 3. Discovery Phase (Background)
    setTimeout(async () => {
        try {
            const commands = await vscode.commands.getCommands(true);
            fs.writeFileSync('C:\\AntiGravityExt\\AntiGravity_Hook_Discovery.log', commands.join('\n'));
        } catch (e) { }
    }, 5000);
}

function deactivate() { }

module.exports = {
    activate,
    deactivate
}
