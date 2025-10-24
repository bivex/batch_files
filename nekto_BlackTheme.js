// ==UserScript==
// @name         NektoMe Premium BlackGlass v3.5 (Expert Edition)
// @namespace    http://tampermonkey.net/
// @version      3.5
// @description  Элитная Apple Glass Black тема для nekto.me/audiochat: глубокий чёрный, стеклянность, плавность, адаптивность, акценты Neon Aqua & Lime Glow.
// @author       UI/UX Dev
// @match        https://nekto.me/audiochat*
// @grant        none
// ==/UserScript==
(function() {
  'use strict';
  const style = document.createElement('style');
  style.innerHTML = `
  @import url('https://fonts.googleapis.com/css2?family=SF+Pro+Display:wght@400;500;600;700&display=swap');

  :root {
    --accent: #3DFF8C;
    --accent-alt: #25C6FF;
    --bg-base: #0C0C0E;
    --glass-bg: rgba(22,22,26,0.72);
    --glass-strong: rgba(18,18,20,0.88);
    --text-main: #F5F5F5;
    --text-dim: #9BA3AE;
    --radius: 18px;
    --blur: 12px;
    --shadow: 0 10px 40px rgba(0,0,0,0.45);
    --font: 'SF Pro Display', 'Inter', 'Segoe UI', sans-serif;
  }

  html, body {
    background: var(--bg-base) !important;
    color: var(--text-main) !important;
    font-family: var(--font) !important;
    font-weight: 400;
    letter-spacing: 0.2px;
    -webkit-font-smoothing: antialiased;
    text-rendering: optimizeLegibility;
  }

  * {
    transition: background .25s ease, color .25s ease, box-shadow .3s ease, transform .25s ease;
  }

  /* ===== STRUCTURE ===== */
  header, nav, .navbar, .header {
    background: var(--glass-bg) !important;
    border: 1px solid rgba(255,255,255,0.06);
    backdrop-filter: blur(var(--blur)) saturate(1.15);
    border-radius: var(--radius);
    box-shadow: var(--shadow);
    margin-bottom: 12px;
  }

  .content, .main, .chat-container, .panel, .box {
    background: var(--glass-strong) !important;
    border: 1px solid rgba(255,255,255,0.08);
    border-radius: var(--radius);
    padding: 26px;
    backdrop-filter: blur(var(--blur)) saturate(1.25);
    box-shadow: 0 6px 40px rgba(0,0,0,0.35);
    animation: fadeIn .4s ease forwards;
  }

  /* ===== BUTTONS ===== */
  button, .btn, [type="submit"], .primary {
    background: linear-gradient(92deg, var(--accent) 0%, var(--accent-alt) 100%);
    color: #0A0A0A !important;
    font-weight: 600;
    border: none;
    border-radius: 14px;
    padding: 12px 28px;
    cursor: pointer;
    box-shadow: 0 0 18px rgba(61,255,140,0.25);
  }
  button:hover, .btn:hover {
    transform: translateY(-1px);
    box-shadow: 0 0 28px rgba(37,198,255,0.4);
  }
  button:active {
    transform: translateY(0);
    filter: brightness(0.9);
  }

  /* ===== INPUTS ===== */
  input, textarea, select {
    background: rgba(28,28,32,0.96) !important;
    border: 1px solid rgba(255,255,255,0.07);
    border-radius: 12px;
    color: var(--text-main);
    padding: 11px 14px;
    font-size: 0.98em;
  }
  input:focus, textarea:focus {
    border-color: var(--accent);
    outline: none;
    box-shadow: 0 0 0 3px rgba(37,198,255,0.25);
  }

  /* ===== LINKS ===== */
  a, .link {
    color: var(--accent);
    text-decoration: none;
    font-weight: 600;
  }
  a:hover {
    color: var(--accent-alt);
    text-shadow: 0 0 8px rgba(37,198,255,0.5);
  }

  /* ===== MODALS ===== */
  .modal, .dialog, .popup {
    background: rgba(20,20,22,0.94);
    border-radius: 20px;
    border: 1px solid rgba(255,255,255,0.1);
    padding: 28px;
    backdrop-filter: blur(14px) saturate(1.25);
    box-shadow: 0 8px 40px rgba(0,0,0,0.45);
  }

  /* ===== TEXT ===== */
  h1, h2, h3, h4, h5, h6 {
    color: #FFF !important;
    font-weight: 600;
    letter-spacing: 0.3px;
  }
  p {
    color: var(--text-dim);
    line-height: 1.6;
  }

  /* ===== SCROLLBAR ===== */
  ::-webkit-scrollbar {
    width: 10px;
    background: transparent;
  }
  ::-webkit-scrollbar-thumb {
    background: linear-gradient(var(--accent), var(--accent-alt));
    border-radius: 6px;
  }

  /* ===== SELECTION ===== */
  ::selection {
    background: var(--accent-alt);
    color: #000;
  }

  /* ===== ANIMATIONS ===== */
  @keyframes fadeIn {
    from { opacity: 0; transform: translateY(6px); }
    to { opacity: 1; transform: translateY(0); }
  }

  /* ===== MOBILE ===== */
  @media (max-width: 768px) {
    .content, .main, .chat-container {
      padding: 18px;
      border-radius: 14px;
    }
    button {
      padding: 10px 20px;
      font-size: 0.95em;
    }
  }

  /* ===== DISABLE ADS ===== */
  .ad, .ads, .banner, iframe[src*="ads"] {
    display: none !important;
    visibility: hidden !important;
  }

  /* ===== HOVER LIGHT ===== */
  .hover-glow:hover {
    box-shadow: 0 0 20px rgba(61,255,140,0.25);
  }

  /* ===== BACKDROP GLASS PANELS ===== */
  .info, .user-panel, .sidebar {
    background: rgba(20,20,22,0.75);
    border-radius: var(--radius);
    border: 1px solid rgba(255,255,255,0.08);
    backdrop-filter: blur(10px) brightness(1.1);
  }

  /* ===== TOOLTIPS ===== */
  [title]:hover::after {
    content: attr(title);
    position: absolute;
    background: rgba(15,15,18,0.9);
    color: var(--text-main);
    padding: 6px 10px;
    border-radius: 8px;
    font-size: 0.8em;
    transform: translateY(-120%);
    opacity: 0;
    animation: tooltipFade .3s forwards;
    white-space: nowrap;
  }
  @keyframes tooltipFade {
    from { opacity: 0; transform: translateY(-100%); }
    to { opacity: 1; transform: translateY(-120%); }
  }
  `;
  document.head.appendChild(style);
})();
