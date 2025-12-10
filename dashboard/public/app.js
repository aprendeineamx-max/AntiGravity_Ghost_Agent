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

        // Update Ghost Agent (Logical Status)
        const ghostSw = document.getElementById('sw-ghost');
        const ghostDot = document.querySelector('#card-ghost .status-dot');
        // Note: index.html class structure might require more specific query or ID on dot

        if (data.Ghost) {
            if (ghostDot) ghostDot.className = 'status-dot green';
            if (ghostSw) ghostSw.checked = true;
        } else {
            if (ghostDot) ghostDot.className = 'status-dot gray'; // Gray for disabled
            if (ghostSw) ghostSw.checked = false;
        }

        // Update OmniControl
        // Update OmniControl
        const ctrlDot = document.getElementById('status-control');
        const ctrlSw = document.getElementById('sw-control');

        if (data.OmniControl) {
            ctrlDot.className = 'status-dot green';
            if (ctrlSw) ctrlSw.checked = true;
        } else {
            ctrlDot.className = 'status-dot orange'; // Maybe running background?
            if (ctrlSw) ctrlSw.checked = false;
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
