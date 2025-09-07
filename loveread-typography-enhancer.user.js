// ==UserScript==
// @name         LoveRead Russian Text Typography Enhancer
// @namespace    http://tampermonkey.net/
// @version      1.0
// @description  Improve Russian text readability with Garamond font and better typography
// @author       You
// @match        https://loveread.ec/read_book.php*
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    // Add CSS for better Russian text typography
    const style = document.createElement('style');
    style.textContent = `
        /* Import Garamond-like fonts */
        @import url('https://fonts.googleapis.com/css2?family=EB+Garamond:ital,wght@0,400;0,500;1,400&display=swap');
        @import url('https://fonts.googleapis.com/css2?family=Libre+Baskerville:ital,wght@0,400;0,700;1,400&display=swap');

        /* Apply enhanced typography to main text content */
        body {
            font-family: 'EB Garamond', 'Libre Baskerville', 'Times New Roman', serif !important;
            line-height: 1.7 !important;
            color: #2c3e50 !important;
            background-color: #fefefe !important;
        }

        /* Target paragraphs with Russian text */
        p {
            font-family: 'EB Garamond', 'Libre Baskerville', 'Times New Roman', serif !important;
            font-size: 18px !important;
            line-height: 1.8 !important;
            margin: 1.5em 0 !important;
            text-align: justify !important;
            color: #34495e !important;
            max-width: 700px !important;
            margin-left: auto !important;
            margin-right: auto !important;
        }

        /* Style for Cyrillic characters specifically */
        *[lang="ru"], *:lang(ru) {
            font-family: 'EB Garamond', 'Libre Baskerville', Georgia, serif !important;
        }

        /* Enhance readability for main content area */
        body > * {
            font-family: 'EB Garamond', 'Libre Baskerville', serif !important;
        }

        /* Better spacing and margins for the main content */
        body {
            max-width: 800px !important;
            margin: 0 auto !important;
            padding: 40px 20px !important;
            background: linear-gradient(to bottom, #fefefe 0%, #f9f9f9 100%) !important;
        }

        /* Style navigation elements less prominently */
        a {
            color: #7f8c8d !important;
            text-decoration: none !important;
            font-size: 14px !important;
        }

        a:hover {
            color: #2980b9 !important;
            text-decoration: underline !important;
        }

        /* Improve table styling if present */
        table {
            font-family: 'EB Garamond', serif !important;
            border-collapse: collapse !important;
            margin: 20px auto !important;
        }

        td {
            padding: 10px !important;
            font-family: 'EB Garamond', serif !important;
        }

        /* Better typography for quotes and emphasized text */
        em, i {
            font-style: italic !important;
            color: #555 !important;
        }

        strong, b {
            font-weight: 500 !important;
            color: #2c3e50 !important;
        }

        /* Responsive design for mobile */
        @media (max-width: 768px) {
            body {
                padding: 20px 15px !important;
            }
            
            p {
                font-size: 16px !important;
                max-width: 100% !important;
            }
        }

        /* Dark mode support */
        @media (prefers-color-scheme: dark) {
            body {
                background-color: #1a1a1a !important;
                color: #e8e8e8 !important;
            }
            
            p {
                color: #d0d0d0 !important;
            }
            
            a {
                color: #8fa0aa !important;
            }
            
            a:hover {
                color: #5dade2 !important;
            }
        }
    `;

    document.head.appendChild(style);

    // Wait for page to load completely
    window.addEventListener('load', function() {
        // Add lang attribute for better font rendering
        document.documentElement.lang = 'ru';
        
        // Find and enhance text nodes containing Cyrillic characters
        const walker = document.createTreeWalker(
            document.body,
            NodeFilter.SHOW_TEXT,
            {
                acceptNode: function(node) {
                    // Check if text contains Cyrillic characters
                    return /[а-яё]/i.test(node.textContent) ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_REJECT;
                }
            }
        );

        const textNodes = [];
        let node;
        while (node = walker.nextNode()) {
            textNodes.push(node);
        }

        // Wrap Cyrillic text in spans with proper styling
        textNodes.forEach(textNode => {
            if (textNode.parentElement && textNode.textContent.trim()) {
                const span = document.createElement('span');
                span.style.fontFamily = "'EB Garamond', 'Libre Baskerville', Georgia, serif";
                span.style.fontFeatureSettings = "'liga', 'kern'";
                span.textContent = textNode.textContent;
                textNode.parentNode.replaceChild(span, textNode);
            }
        });

        console.log('LoveRead Typography Enhancer: Applied Garamond styling to Russian text');
    });
})();
