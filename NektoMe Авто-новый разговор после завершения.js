// ==UserScript==
// @name         NektoMe Авто-новый разговор после завершения
// @namespace    http://nekto.me/
// @version      1.0
// @description  Автоматически запускает новый разговор, когда текущий завершён.
// @author       Senior UI/UX
// @match        https://nekto.me/audiochat*
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    function tryAutoStart() {
        // ищем статус "Разговор завершен"
        const endStatus = Array.from(document.querySelectorAll('*')).find(el =>
            /Разговор завершен/i.test(el.textContent)
        );
        if (endStatus) {
            // ищем кнопку "Начать новый разговор" — обычно это <button> или <a>
            const newChatBtn = Array.from(document.querySelectorAll('button, a')).find(el =>
                /Начать новый разговор/i.test(el.textContent)
            );
            if (newChatBtn && !newChatBtn.disabled) {
                newChatBtn.click();

                // Всплывающее уведомление (опционально)
                let toast = document.createElement('div');
                toast.innerText = 'Новый разговор запущен!';
                toast.style = 'position:fixed;top:16px;right:16px;background:#17696a;color:white;padding:12px 20px;border-radius:8px;box-shadow:0 4px 20px rgba(0,0,0,.13);font-size:16px;z-index:9999;';
                document.body.appendChild(toast);
                setTimeout(() => toast.remove(), 1800);
            }
        }
    }

    // Отслеживание динамических изменений на странице (например, после отключения)
    const observer = new MutationObserver(tryAutoStart);
    observer.observe(document.body, { childList: true, subtree: true });
})();
