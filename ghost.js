(function () {
    'use strict';

    console.log('👻 Ghost Agent: Initialized and watching for prompts...');

    const observerConfig = {
        childList: true,
        subtree: true
    };

    // Target keywords for button text or tooltips
    const TARGET_KEYWORDS = ['accept', 'autorizar', 'allow', 'confirm', 'alt+enter'];

    // CSS selectors for potential buttons/actions in VS Code / Electron
    const BUTTON_SELECTORS = [
        '.monaco-button',
        '.action-item',
        '.dialog-buttons .monaco-text-button',
        '.quick-input-widget .quick-input-list-entry', // Sometimes prompts appear in quick input
        '.notification-toast .monaco-button',
        '.modal-body .monaco-button'
    ];

    const isMatch = (text) => {
        if (!text) return false;
        const lower = text.toLowerCase();
        return TARGET_KEYWORDS.some(keyword => lower.includes(keyword));
    };

    const handleMutations = (mutationsList) => {
        for (const mutation of mutationsList) {
            if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
                mutation.addedNodes.forEach((node) => {
                    // Start valid check: must be an Element node
                    if (node.nodeType !== Node.ELEMENT_NODE) return;

                    // 1. Check if the node itself is a target button
                    if (BUTTON_SELECTORS.some(selector => node.matches && node.matches(selector))) {
                        checkAndClick(node);
                    }

                    // 2. Query within the node for target buttons
                    // We iterate selectors to find any contained buttons
                    const foundButtons = node.querySelectorAll(BUTTON_SELECTORS.join(', '));
                    foundButtons.forEach(btn => checkAndClick(btn));
                });
            }
        }
    };

    const checkAndClick = (element) => {
        // Check visible text
        const textContent = element.textContent || element.innerText || '';
        // Check title or aria-label for accessibility/tooltips
        const title = element.getAttribute('title') || element.getAttribute('aria-label') || '';

        if (isMatch(textContent) || isMatch(title)) {
            try {
                // Determine if it's currently visible/clickable (basic check)
                if (element.offsetParent !== null && !element.disabled) {
                    element.click();
                    console.log(`👻 Ghost Agent: Auto-authorized "${textContent.trim() || 'Action'}"`);
                }
            } catch (err) {
                console.error('👻 Ghost Agent: Failed to click', err);
            }
        }
    };

    const observer = new MutationObserver(handleMutations);

    // Start observing the document body
    // We wait for body if it doesn't exist yet (for very early injection)
    if (document.body) {
        observer.observe(document.body, observerConfig);
    } else {
        document.addEventListener('DOMContentLoaded', () => {
            observer.observe(document.body, observerConfig);
        });
    }

})();
