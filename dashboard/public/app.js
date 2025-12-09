function updateClock() {
    const now = new Date();
    document.getElementById('clock').innerText = now.toLocaleTimeString();
}
setInterval(updateClock, 1000);

// Polling Status from PowerShell Server
async function fetchStatus() {
    try {
        const res = await fetch('/api/status');
        const data = await res.json();
        
        // Update OmniGod
        const godDot = document.getElementById('status-omnigod');
        const godSw = document.getElementById('sw-omnigod');
        
        if (data.OmniGod) {
            godDot.className = 'status-dot green';
            godDot.style.boxShadow = '0 0 10px #00ff9d';
            godSw.checked = true;
        } else {
            godDot.className = 'status-dot red';
            godDot.style.boxShadow = '0 0 10px #ff4757';
            godSw.checked = false;
        }

        // Update OmniControl
        const ctrlDot = document.getElementById('status-control');
        if (data.OmniControl) {
            ctrlDot.className = 'status-dot green';
        } else {
            ctrlDot.className = 'status-dot orange'; // Maybe running background?
        }

    } catch (e) {
        console.error("Connection lost", e);
    }
}

// Initial Fetch
fetchStatus();
setInterval(fetchStatus, 2000);

async function toggleAgent(agent) {
    // Send command to backend
    console.log("Toggling", agent);
    await fetch(`/api/toggle/${agent}`, { method: 'POST' });
}
