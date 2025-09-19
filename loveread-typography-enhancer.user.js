// ==UserScript==
// @name         LoveRead Russian Text Typography Enhancer
// @namespace    http://tampermonkey.net/
// @version      2.2
// @description  Improve Russian text readability with consistent typography
// @author       You
// @match        https://loveread.ec/read_book.php*
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    // Add CSS for better Russian text typography
    const style = document.createElement('style');
    style.textContent = `
        /* Import consistent serif fonts */
        @import url('https://fonts.googleapis.com/css2?family=EB+Garamond:ital,wght@0,400;0,500;0,700;1,400&display=swap');
        @import url('https://fonts.googleapis.com/css2?family=Libre+Baskerville:ital,wght@0,400;0,700;1,400&display=swap');

        /* Base typography - consistent serif fonts */
        html, body {
            font-family: 'EB Garamond', 'Libre Baskerville', Georgia, serif !important;
            line-height: 1.6 !important;
            color: #2c3e50 !important;
            background-color: #fefefe !important;
        }

        /* Main content typography */
        #readerContent, .book-content, main {
            font-family: 'EB Garamond', 'Libre Baskerville', Georgia, serif !important;
            font-size: 18px !important;
            line-height: 1.7 !important;
            max-width: 700px !important;
            margin: 0 auto !important;
            padding: 20px !important;
        }

        /* Paragraph styling */
        p, p.MsoNormal, p.em {
            font-family: 'EB Garamond', 'Libre Baskerville', Georgia, serif !important;
            font-size: 18px !important;
            line-height: 1.8 !important;
            margin: 1.2em 0 !important;
            text-align: justify !important;
            color: #34495e !important;
        }

        /* Headers */
        h1, h2, h3, h4, h5, h6 {
            font-family: 'EB Garamond', 'Libre Baskerville', Georgia, serif !important;
            font-weight: 600 !important;
            color: #2c3e50 !important;
            line-height: 1.3 !important;
        }

        h1 {
            font-size: 20px !important;
            line-height: 1.4 !important;
        }

        h2.h2-title {
            font-size: 24px !important;
            font-weight: 600 !important;
            margin: 1.5em 0 !important;
        }

        /* Book title styling */
        .book-title, div.book-title {
            font-family: 'EB Garamond', 'Libre Baskerville', Georgia, serif !important;
            font-size: 24px !important;
            font-weight: 600 !important;
            color: #2c3e50 !important;
            margin: 1.5em 0 !important;
            text-align: center !important;
        }

        /* Emphasis and italics */
        em, i {
            font-family: 'EB Garamond', 'Libre Baskerville', Georgia, serif !important;
            font-style: italic !important;
            color: #555 !important;
        }

        strong, b {
            font-family: 'EB Garamond', 'Libre Baskerville', Georgia, serif !important;
            font-weight: 600 !important;
            color: #2c3e50 !important;
        }

        /* CRITICAL FIX: Menu line-height was 0px */
        .leftMenu li, ul.leftMenu li {
            line-height: 22px !important;
            font-family: 'EB Garamond', 'Libre Baskerville', Georgia, serif !important;
            margin-bottom: 4px !important;
        }

        /* Fix remaining mixed font families - Forms and search */
        #enterSite, #enterSite form, #enterSite label, #enterSite div {
            font-family: 'EB Garamond', 'Libre Baskerville', Georgia, serif !important;
        }

        #searchSite, #searchSite form, #searchSite label, #searchSite div.checkboxSearch {
            font-family: 'EB Garamond', 'Libre Baskerville', Georgia, serif !important;
        }

        /* Calendar elements - fix remaining mixed fonts */
        #calendar-output div {
            font-family: 'EB Garamond', 'Libre Baskerville', Georgia, serif !important;
            font-size: 14px !important;
        }

        /* Navigation and UI elements */
        .navigation, div.navigation, .navigation a {
            font-family: 'EB Garamond', 'Libre Baskerville', Georgia, serif !important;
            font-size: 14px !important;
            font-weight: normal !important;
        }

        /* Form elements */
        input, button, select, textarea, br, img {
            font-family: 'EB Garamond', 'Libre Baskerville', Georgia, serif !important;
            font-size: 14px !important;
            font-weight: normal !important;
        }

        /* Fix extreme font weights */
        .formButton, input.formButton {
            font-weight: 600 !important;
        }

        /* Links - standardize font sizes */
        a {
            font-family: 'EB Garamond', 'Libre Baskerville', Georgia, serif !important;
            color: #7f8c8d !important;
            text-decoration: none !important;
        }

        a:hover {
            color: #2980b9 !important;
            text-decoration: underline !important;
        }

        /* Sidebar menu - fix non-standard sizes and critical line-height */
        .leftMenu a, ul.leftMenu a {
            font-family: 'EB Garamond', 'Libre Baskerville', Georgia, serif !important;
            font-size: 12px !important;
            font-weight: 600 !important;
            line-height: 1.4 !important;
        }

        /* Footer - fix non-standard size */
        #footer {
            font-family: 'EB Garamond', 'Libre Baskerville', Georgia, serif !important;
            font-size: 12px !important;
        }

        #footer strong {
            font-size: 14px !important;
        }

        /* Registration and password links */
        #enterSite div a {
            font-size: 12px !important;
        }

        /* Table styling */
        table, td, th {
            font-family: 'EB Garamond', 'Libre Baskerville', Georgia, serif !important;
        }

        /* Fix font size inconsistencies */
        .capUnit, div.capUnit {
            font-size: 14px !important;
            font-weight: 600 !important;
        }

        /* Page controls */
        .reader-toolbar, div.reader-toolbar {
            font-family: 'EB Garamond', 'Libre Baskerville', Georgia, serif !important;
            font-size: 14px !important;
        }

        #fsValue, #fsDec, #fsInc {
            font-family: 'EB Garamond', 'Libre Baskerville', Georgia, serif !important;
            font-size: 14px !important;
        }

        /* Current page indicator */
        .current, span.current {
            font-weight: 600 !important;
            background-color: #ecf0f1 !important;
            padding: 2px 6px !important;
            border-radius: 3px !important;
        }

        /* Mobile responsiveness */
        @media (max-width: 768px) {
            #readerContent, .book-content, main {
                padding: 15px !important;
                font-size: 16px !important;
            }

            p, p.MsoNormal, p.em {
                font-size: 16px !important;
                line-height: 1.6 !important;
            }

            h1 {
                font-size: 18px !important;
            }

            .leftMenu li, ul.leftMenu li {
                line-height: 18px !important;
            }
        }

        /* Dark mode support */
        @media (prefers-color-scheme: dark) {
            html, body {
                background-color: #1a1a1a !important;
                color: #e8e8e8 !important;
            }

            p, p.MsoNormal, p.em {
                color: #d0d0d0 !important;
            }

            h1, h2, h3, h4, h5, h6, .book-title {
                color: #f0f0f0 !important;
            }

            a {
                color: #8fa0aa !important;
            }

            a:hover {
                color: #5dade2 !important;
            }

            .current {
                background-color: #34495e !important;
                color: #ecf0f1 !important;
            }
        }

        /* Ensure consistent typography for all elements */
        * {
            font-weight: normal !important;
        }

        h1, h2, h3, h4, h5, h6, strong, b, .formButton, .leftMenu a, .capUnit {
            font-weight: 600 !important;
        }
    `;

    document.head.appendChild(style);

    // Wait for page to load completely
    window.addEventListener('load', function() {
        // Set lang attribute for better font rendering
        document.documentElement.lang = 'ru';
        
        console.log('LoveRead Typography Enhancer: Applied consistent serif typography - critical line-height issue fixed');
    });
})();
