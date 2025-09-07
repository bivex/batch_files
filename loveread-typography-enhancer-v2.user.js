// ==UserScript==
// @name         LoveRead Russian Text Typography Enhancer V2 (Crimson Text)
// @namespace    http://tampermonkey.net/
// @version      2.0
// @description  Improve Russian text readability with Crimson Text font and premium typography
// @author       You
// @match        https://loveread.ec/read_book.php*
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    // Add CSS for premium Russian text typography
    const style = document.createElement('style');
    style.textContent = `
        /* Import premium serif fonts */
        @import url('https://fonts.googleapis.com/css2?family=Crimson+Text:ital,wght@0,400;0,600;1,400;1,600&display=swap');
        @import url('https://fonts.googleapis.com/css2?family=Lora:ital,wght@0,400;0,500;0,600;1,400&display=swap');
        @import url('https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,400;0,500;0,600;1,400&display=swap');

        /* Premium typography for main text content */
        body {
            font-family: 'Crimson Text', 'Lora', 'Cormorant Garamond', Georgia, serif !important;
            line-height: 1.75 !important;
            color: #1a1a1a !important;
            background: #faf9f7 !important;
            letter-spacing: 0.3px !important;
        }

        /* Enhanced paragraphs with premium styling */
        p {
            font-family: 'Crimson Text', 'Lora', 'Cormorant Garamond', Georgia, serif !important;
            font-size: 19px !important;
            font-weight: 400 !important;
            line-height: 1.85 !important;
            margin: 1.8em 0 !important;
            text-align: justify !important;
            color: #2d3748 !important;
            max-width: 680px !important;
            margin-left: auto !important;
            margin-right: auto !important;
            hyphens: auto !important;
            word-spacing: 1px !important;
            letter-spacing: 0.2px !important;
            text-rendering: optimizeLegibility !important;
            font-feature-settings: 'liga', 'kern', 'clig' !important;
        }

        /* Crimson Text specific optimizations for Cyrillic */
        *[lang="ru"], *:lang(ru) {
            font-family: 'Crimson Text', 'Lora', Georgia, serif !important;
            font-variant-ligatures: common-ligatures !important;
        }

        /* Premium page layout */
        body {
            max-width: 750px !important;
            margin: 0 auto !important;
            padding: 50px 30px !important;
            background: linear-gradient(135deg, #faf9f7 0%, #f5f4f2 100%) !important;
            box-shadow: inset 0 0 100px rgba(0,0,0,0.02) !important;
        }

        /* Elegant navigation styling */
        a {
            color: #8b7355 !important;
            text-decoration: none !important;
            font-size: 15px !important;
            font-family: 'Lora', serif !important;
            font-weight: 500 !important;
            transition: all 0.3s ease !important;
        }

        a:hover {
            color: #5d4e37 !important;
            text-decoration: underline !important;
            text-decoration-color: #c9a876 !important;
        }

        /* Premium table styling */
        table {
            font-family: 'Crimson Text', serif !important;
            border-collapse: collapse !important;
            margin: 30px auto !important;
            background: rgba(255,255,255,0.6) !important;
            border-radius: 8px !important;
        }

        td {
            padding: 15px !important;
            font-family: 'Crimson Text', serif !important;
            border: none !important;
        }

        /* Refined typography for emphasis */
        em, i {
            font-style: italic !important;
            color: #4a5568 !important;
            font-family: 'Crimson Text', serif !important;
        }

        strong, b {
            font-weight: 600 !important;
            color: #2d3748 !important;
            font-family: 'Crimson Text', serif !important;
        }

        /* Premium drop cap effect for first paragraph */
        p:first-of-type::first-letter {
            float: left !important;
            font-family: 'Cormorant Garamond', serif !important;
            font-size: 4em !important;
            line-height: 0.8 !important;
            padding-right: 8px !important;
            padding-top: 4px !important;
            color: #8b7355 !important;
            font-weight: 500 !important;
        }

        /* Elegant quotation marks */
        blockquote {
            font-family: 'Crimson Text', serif !important;
            font-style: italic !important;
            font-size: 20px !important;
            border-left: 3px solid #c9a876 !important;
            padding-left: 20px !important;
            margin: 2em 0 !important;
            color: #4a5568 !important;
        }

        /* Mobile responsive design */
        @media (max-width: 768px) {
            body {
                padding: 25px 20px !important;
                font-size: 17px !important;
            }
            
            p {
                font-size: 17px !important;
                max-width: 100% !important;
                line-height: 1.8 !important;
            }

            p:first-of-type::first-letter {
                font-size: 3em !important;
            }
        }

        /* Elegant dark mode */
        @media (prefers-color-scheme: dark) {
            body {
                background: linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%) !important;
                color: #e2e8f0 !important;
            }
            
            p {
                color: #cbd5e0 !important;
            }
            
            a {
                color: #d4af37 !important;
            }
            
            a:hover {
                color: #ffd700 !important;
                text-decoration-color: #d4af37 !important;
            }

            p:first-of-type::first-letter {
                color: #d4af37 !important;
            }

            blockquote {
                border-left-color: #d4af37 !important;
                color: #a0aec0 !important;
            }
        }

        /* Print styles */
        @media print {
            body {
                background: white !important;
                color: black !important;
                font-size: 12pt !important;
                line-height: 1.6 !important;
            }
            
            p {
                font-size: 12pt !important;
                line-height: 1.6 !important;
                margin: 0.8em 0 !important;
            }
        }

        /* Smooth scrolling */
        html {
            scroll-behavior: smooth !important;
        }

        /* Selection styling */
        ::selection {
            background: rgba(201, 168, 118, 0.3) !important;
            color: #2d3748 !important;
        }

        /* Focus styles for accessibility */
        a:focus {
            outline: 2px solid #c9a876 !important;
            outline-offset: 2px !important;
            border-radius: 2px !important;
        }
    `;

    document.head.appendChild(style);

    // Enhanced page processing
    window.addEventListener('load', function() {
        // Set language for better font rendering
        document.documentElement.lang = 'ru';
        
        // Add reading time estimation
        const wordCount = document.body.textContent.split(/\s+/).length;
        const readingTime = Math.ceil(wordCount / 200); // ~200 words per minute
        
        // Create reading info element
        const readingInfo = document.createElement('div');
        readingInfo.style.cssText = `
            font-family: 'Lora', serif;
            font-size: 14px;
            color: #8b7355;
            text-align: center;
            margin-bottom: 30px;
            font-style: italic;
            border-bottom: 1px solid rgba(139, 115, 85, 0.2);
            padding-bottom: 15px;
        `;
        readingInfo.textContent = `Время чтения: ~${readingTime} мин`;
        
        // Insert reading info at the beginning of body
        if (document.body.firstChild) {
            document.body.insertBefore(readingInfo, document.body.firstChild);
        }

        // Enhanced Cyrillic text processing
        const walker = document.createTreeWalker(
            document.body,
            NodeFilter.SHOW_TEXT,
            {
                acceptNode: function(node) {
                    return /[а-яё]/i.test(node.textContent) && node.textContent.trim().length > 3 
                        ? NodeFilter.FILTER_ACCEPT 
                        : NodeFilter.FILTER_REJECT;
                }
            }
        );

        const textNodes = [];
        let node;
        while (node = walker.nextNode()) {
            textNodes.push(node);
        }

        // Apply premium font styling to Cyrillic text
        textNodes.forEach(textNode => {
            if (textNode.parentElement && textNode.textContent.trim()) {
                const span = document.createElement('span');
                span.style.cssText = `
                    font-family: 'Crimson Text', 'Lora', Georgia, serif;
                    font-feature-settings: 'liga', 'kern', 'clig', 'onum';
                    text-rendering: optimizeLegibility;
                    font-variant-numeric: oldstyle-nums;
                `;
                span.textContent = textNode.textContent;
                textNode.parentNode.replaceChild(span, textNode);
            }
        });

        console.log('LoveRead Typography Enhancer V2: Applied Crimson Text premium styling to Russian text');
        
        // Add subtle page transition effect
        document.body.style.opacity = '0';
        document.body.style.transition = 'opacity 0.5s ease-in-out';
        setTimeout(() => {
            document.body.style.opacity = '1';
        }, 100);
    });
})();
