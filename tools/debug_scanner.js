// 🕵️ DEBUG SCANNER - Run this in VS Code 'Developer Tools' Console
(function () {
    console.clear();
    console.log('%c🛡️ ANTIGRAVITY DIAGNOSTIC TOOL 🛡️', 'color: cyan; font-size: 16px; font-weight: bold;');

    // 1. Define what we are looking for
    const targets = [
        { name: 'SETUP Button', selector: '.monaco-button', text: 'setup' },
        { name: 'ALLOW Button', selector: '.monaco-button', text: 'allow' },
        { name: 'ACCEPT Button', selector: '.monaco-button', text: 'accept' },
        { name: 'TRUST Button', selector: '.monaco-button', text: 'trust' },
        { name: 'CHAT Widgets', selector: '.chat-notification-widget', text: '' }
    ];

    let foundTotal = 0;

    // 2. Scan function
    targets.forEach(t => {
        const elements = Array.from(document.querySelectorAll(t.selector));
        const matches = elements.filter(el =>
            (el.innerText || '').toLowerCase().includes(t.text) ||
            (el.title || '').toLowerCase().includes(t.text)
        );

        if (matches.length > 0) {
            console.log(`%c[MATCH] Found ${matches.length} x ${t.name}`, 'color: lime');
            matches.forEach(el => {
                console.log('   📍 Location:', el);
                console.log('   📄 Text:', el.innerText);
                // Highlight found elements visually for the user
                el.style.border = "4px solid red";
                el.style.boxShadow = "0 0 20px red";
            });
            foundTotal += matches.length;
        } else {
            console.log(`%c[MISSING] No visible ${t.name}`, 'color: gray');
        }
    });

    console.log(`%c--------------------------------------------------`, 'color: cyan');
    if (foundTotal > 0) {
        console.log(`%c✅ VERIFIED: Ghost Agent CAN see ${foundTotal} targets.`, 'color: lime; font-weight: bold;');
        console.log(`%c(I have highlighted them in RED on your screen)`, 'color: white');
    } else {
        console.log(`%c❌ WARNING: No targets visible. They might be inside a Shadow DOM or Iframe.`, 'color: red; font-weight: bold;');
        console.log(`%cFallback: OmniControl HUD (External) will handle this via OCR/Accessibility APIs.`, 'color: yellow');
    }
})();
