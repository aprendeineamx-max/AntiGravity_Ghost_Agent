(function () {
    'use strict';

    const AGENT_NAME = '👻 Ghost Agent';
    const ATTR_HANDLED = 'data-ghost-handled';

    // Config: Performance & Targeting
    const CONFIG = {
        debounceMs: 200,
        selectors: [
            '.monaco-button',
            '.action-item',
            '.dialog-buttons .monaco-text-button',
            '.quick-input-widget .quick-input-list-entry',
            '.notification-toast .monaco-button',
            '.modal-body .monaco-button',
            '.chat-notification-widget .monaco-button', // Specific for Chat
            '[aria-label="Allow Always"]',
            '[aria-label="Allow Once"]',
            '[aria-label="Accept all"]',
            '[title="Accept all"]',
            '.chat-input-control .monaco-button',
            '[role="button"]', // Generic catch-all (strictly text filtered)
            'button'
        ],
        keywords: [
            'accept', 'autorizar', 'allow', 'confirm', 'alt+enter', 'yes', 'si', // Standard
            'setup', 'configurar', 'trust', 'connect', // Browser
            'allow once', 'always allow', 'allow always', // Dropdowns
            'accept all', // Specific
            'acceptalt', 'run command' // AI Chat specific
        ]
    };

    console.log(`${AGENT_NAME}: Initialized. Waiting via MutationObserver...`);

    /**
     * Predicate: Should we click this element?
     * @param {HTMLElement} element 
     */
    const shouldClick = (element) => {
        // 1. Sanity Check
        if (!element || element.hasAttribute(ATTR_HANDLED) || element.disabled) return false;

        // 2. Visibility Check (Basic)
        if (element.offsetParent === null) return false;

        // 3. Content Match
        const text = (element.innerText || element.textContent || '').trim().toLowerCase();
        const title = (element.getAttribute('title') || element.getAttribute('aria-label') || '').toLowerCase();

        return CONFIG.keywords.some(kw => text.includes(kw) || title.includes(kw));
    };

    /**
     * Action: Click and Mark
     * @param {HTMLElement} element 
     */
    const performClick = (element) => {
        try {
            // Mark immediately to prevent double-clicks
            element.setAttribute(ATTR_HANDLED, 'true');

            // Visual Debug (Optional: Highlight before click)
            element.style.outline = '2px solid #00FF00';

            // Execution
            element.click();

            console.log(`${AGENT_NAME}: Auto-authorized -> "${element.innerText || 'Action'}"`);
        } catch (err) {
            console.error(`${AGENT_NAME}: Action Failed`, err);
        }
    };

    /**
     * Observer Logic
     */
    const handleMutations = (mutationsList) => {
        for (const mutation of mutationsList) {
            if (mutation.type === 'childList') {
                mutation.addedNodes.forEach(node => {
                    if (node.nodeType === Node.ELEMENT_NODE) {
                        // A. Check the node itself
                        if (CONFIG.selectors.some(s => node.matches(s)) && shouldClick(node)) {
                            performClick(node);
                        }

                        // B. Check children (if it's a container)
                        const query = CONFIG.selectors.join(',');
                        const children = node.querySelectorAll(query);
                        children.forEach(child => {
                            if (shouldClick(child)) performClick(child);
                        });
                    }
                });
            }
        }
    };

    // Initialize Observer
    const observer = new MutationObserver(handleMutations);

    // Wait for Body
    const init = () => {
        if (document.body) {
            observer.observe(document.body, {
                childList: true,
                subtree: true
            });
        } else {
            setTimeout(init, 100);
        }
    };

    init();

})();
