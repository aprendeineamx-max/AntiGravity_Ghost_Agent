const vscode = require('vscode');
const fs = require('fs');
const path = require('path');

/**
 * @param {vscode.ExtensionContext} context
 */
function activate(context) {
    const exportsDir = 'C:\\AntiGravityExt\\AntiGravity_Ghost_Agent\\Exports';
    if (!fs.existsSync(exportsDir)) {
        try { fs.mkdirSync(exportsDir, { recursive: true }); } catch (e) { }
    }

    const exportPath = path.join(exportsDir, 'Chat_History.json');
    const exportUri = vscode.Uri.file(exportPath);

    console.log('[ChatExporter] Active. Target:', exportPath);

    // Command: Force Export
    let disposable = vscode.commands.registerCommand('antigravity.exportChatNow', async () => {
        try {
            // Attempt 1: Pass URI to bypass dialog (Undocumented API feature?)
            // If this works, it saves silently.
            // If not, it opens "Save As".
            await vscode.commands.executeCommand('workbench.action.chat.export', exportUri);

            // Log for OmniGod (just in case we need to confirm)
            console.log('[ChatExporter] Triggered Export');
            vscode.window.setStatusBarMessage('Chat Exported', 2000);
        } catch (e) {
            console.error('[ChatExporter] Export Failed:', e);
        }
    });

    context.subscriptions.push(disposable);

    // Interval: Auto-Export every 10 seconds (Pseudo Real-Time)
    // We don't want to spam it if it opens a dialog.
    // Logic: If we detect the file updated recently, we assume success.
    /*
    setInterval(async () => {
        // Only trigger if active logic dictates? 
        // For now, let's keep it manual trigger via Command 
        // OR trigger on document change if we can find the doc.
    }, 10000);
    */

    // For now, let's expose the command. The Loop will be external (OmniGod) or Internal if silent.
    // If the user wants "Real Time", we need to know if it's silent.
    // Let's try silent first.
}

function deactivate() { }

module.exports = {
    activate,
    deactivate
}
