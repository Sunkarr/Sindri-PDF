document.addEventListener('DOMContentLoaded', () => {
    // Intersection Observer for scroll animations
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
            }
        });
    }, {
        threshold: 0.1
    });

    const hiddenElements = document.querySelectorAll('.fade-in');
    hiddenElements.forEach((el) => observer.observe(el));

    // --- Interactive macOS Terminal simulator typewriter loop ---
    const typedSpan = document.getElementById('terminal-typed');
    const newPromptDiv = document.getElementById('terminal-new-prompt');
    const commandText = "xattr -cr /Applications/Sindri\\ PDF.app";
    let charIndex = 0;
    let isTyping = false;

    function typeTerminalCommand() {
        if (!typedSpan || isTyping) return;
        isTyping = true;
        
        // Setup initial terminal visual state
        newPromptDiv.style.display = 'none';
        typedSpan.textContent = '';
        const activeCursor = typedSpan.nextElementSibling;
        if (activeCursor) activeCursor.classList.remove('blinking');
        
        function typeChar() {
            if (charIndex < commandText.length) {
                typedSpan.textContent += commandText.charAt(charIndex);
                charIndex++;
                setTimeout(typeChar, 70 + Math.random() * 60); // Natural typing rhythm
            } else {
                // Hit enter wait period
                setTimeout(() => {
                    if (activeCursor) activeCursor.classList.add('blinking');
                    
                    // Simulate execution prompt output showing up
                    setTimeout(() => {
                        newPromptDiv.style.display = 'block';
                        const newCursor = newPromptDiv.querySelector('.terminal-cursor');
                        if (newCursor) newCursor.classList.add('blinking');
                        
                        // Wait, then reset loop
                        setTimeout(() => {
                            charIndex = 0;
                            isTyping = false;
                            typeTerminalCommand();
                        }, 5000);
                    }, 500);
                }, 800);
            }
        }
        
        typeChar();
    }

    // Trigger typing loop when terminal enters the viewport (using observer)
    const terminalObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting && !isTyping) {
                typeTerminalCommand();
            }
        });
    }, { threshold: 0.2 });

    const terminalContainer = document.querySelector('.terminal-container');
    if (terminalContainer) {
        terminalObserver.observe(terminalContainer);
    }

    // Terminal command box copy functionality
    const copyBtn = document.getElementById('terminal-copy-btn');
    if (copyBtn) {
        copyBtn.addEventListener('click', () => {
            const command = "xattr -cr /Applications/Sindri\\ PDF.app";
            navigator.clipboard.writeText(command).then(() => {
                copyBtn.textContent = 'Copied!';
                copyBtn.style.background = 'rgba(48, 209, 88, 0.12)';
                copyBtn.style.color = '#30d158';
                copyBtn.style.borderColor = 'rgba(48, 209, 88, 0.2)';
                
                setTimeout(() => {
                    copyBtn.textContent = 'Copy';
                    copyBtn.style.background = 'rgba(255, 255, 255, 0.06)';
                    copyBtn.style.color = 'var(--text-primary)';
                    copyBtn.style.borderColor = 'var(--card-border)';
                }, 2000);
            }).catch(err => {
                console.error('Failed to copy text: ', err);
            });
        });
    }

    // Scroll to How to Install section after download click
    const downloadBtn = document.getElementById('download-btn');
    if (downloadBtn) {
        downloadBtn.addEventListener('click', () => {
            const installSection = document.getElementById('install-guide');
            if (installSection) {
                installSection.scrollIntoView({ behavior: 'smooth' });
            }
        });
    }
});
