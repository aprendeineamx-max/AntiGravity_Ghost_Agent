const fs = require('fs');
const path = require('path');

const storageRoot = 'C:\\Users\\Administrator\\AppData\\Roaming\\Antigravity\\User\\workspaceStorage';

try {
    const folders = fs.readdirSync(storageRoot)
        .map(name => path.join(storageRoot, name))
        .filter(p => fs.statSync(p).isDirectory())
        .sort((a, b) => fs.statSync(b).mtimeMs - fs.statSync(a).mtimeMs);

    const latest = folders[0];
    const dbPath = path.join(latest, 'state.vscdb');
    const buffer = fs.readFileSync(dbPath);
    const content = buffer.toString('utf8');

    console.log(`Scanning for 'EXPORT NOW'...`);

    let index = content.indexOf('EXPORT NOW');
    if (index !== -1) {
        console.log('--- FOUND ---');
        // Extract a large chunk around it
        const start = Math.max(0, index - 200);
        const end = Math.min(content.length, index + 200);
        const chunk = content.substring(start, end).replace(/\n/g, ' ');
        console.log(chunk);
    } else {
        // Search cases insensitive or parts
        index = content.indexOf('Export Now');
        if (index !== -1) {
            console.log('--- FOUND (Case 2) ---');
            const start = Math.max(0, index - 200);
            const end = Math.min(content.length, index + 200);
            const chunk = content.substring(start, end).replace(/\n/g, ' ');
            console.log(chunk);
        } else {
            console.log('Not Found. DB might be encrypted or compressed.');
        }
    }

} catch (e) { console.error(e); }
