// =================== НАСТРОЙКИ ===================
const paginationDelay = 4000;           // Задержка между переходами по страницам (мс)
const itemsDelay = 500;                 // Задержка между попытками найти товары (мс)
const itemsMaxAttempts = 10;            // Количество попыток дождаться появления товаров
// =================================================

async function getAllProductIds() {
    let allIds = new Set();
    let currentPage = 1;
    let previousCount = 0;
    let stagnantCount = 0;

    console.log('Начинаем сбор всех ID товаров...');

    while (stagnantCount < 3) {
        console.log(`Страница ${currentPage}...`);

        // Скроллим вниз к элементу пагинации
        let paginations = document.querySelectorAll('.comet-pagination, .pagination, .next, [class*="pagination"]');
        if (paginations.length) {
            paginations.forEach(el => el.scrollIntoView());
            await new Promise(r => setTimeout(r, 500));
        }

        // Скроллим до самого низа страницы
        window.scrollTo(0, document.body.scrollHeight);
        await new Promise(r => setTimeout(r, 700));

        // Собираем ID с текущей страницы
        const currentIds = [...new Set(
            Array.from(document.querySelectorAll('a[href*="/item/"]'))
                .map(a => a.href.match(/\/item\/(\d+)\.html/)?.[1])
                .filter(Boolean)
        )];
        currentIds.forEach(id => allIds.add(id));
        console.log(`Найдено ${currentIds.length} товаров, всего уникальных: ${allIds.size}`);

        // Проверка прогресса
        if (allIds.size === previousCount) {
            stagnantCount++;
        } else {
            stagnantCount = 0;
        }
        previousCount = allIds.size;

        // Поиск кнопки 'следующая страница'
        const nextSelectors = [
            'button[aria-label*="Next"]',
            'a[aria-label*="Next"]',
            '.comet-pagination-next',
            '.next',
            '.pagination button:last-child:not([disabled])',
            '[class*="next"]:not([disabled])'
        ];
        let nextButton = null;
        for (const selector of nextSelectors) {
            try {
                nextButton = document.querySelector(selector);
                if (nextButton && !nextButton.disabled) break;
            } catch (e) { continue; }
        }
        // Поиск по тексту, если стандартные селекторы не нашли
        if (!nextButton || nextButton.disabled) {
            const buttons = document.querySelectorAll('button, a');
            nextButton = Array.from(buttons).find(el => {
                if (el.disabled) return false;
                const text = el.textContent.trim().toLowerCase();
                const ariaLabel = (el.getAttribute('aria-label') || '').toLowerCase();
                return text.includes('next') || 
                       text.includes('далее') ||
                       text === '›' || 
                       text === '>' ||
                       ariaLabel.includes('next') ||
                       el.innerHTML.includes('›');
            });
        }

        if (nextButton && !nextButton.disabled) {
            console.log('Переходим на следующую страницу...');
            nextButton.click();

            // Ждём загрузки указанную задержку
            await new Promise(r => setTimeout(r, paginationDelay));

            // Ожидание появления товаров
            let attempts = 0;
            while (attempts < itemsMaxAttempts) {
                const newItems = document.querySelectorAll('a[href*="/item/"]').length;
                if (newItems > 0) break;
                await new Promise(r => setTimeout(r, itemsDelay));
                attempts++;
            }
            currentPage++;
        } else {
            console.log('Кнопка следующей страницы не найдена или недоступна');
            break;
        }
    }

    const result = Array.from(allIds);
    console.log(`\nСобрано ${result.length} уникальных ID товаров`);
    console.log('\nID через запятую:');
    console.log(result.join(', '));
    return result;
}

// Запуск
getAllProductIds();
