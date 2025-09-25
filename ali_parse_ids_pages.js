async function getAllProductIds() {
    let allIds = new Set();
    let currentPage = 1;
    let previousCount = 0;
    let stagnantCount = 0;
    
    console.log('Начинаем сбор всех ID товаров...');
    
    while (stagnantCount < 3) {
        console.log(`Страница ${currentPage}...`);
        
        // Собираем ID с текущей страницы
        const currentIds = [...new Set(
            Array.from(document.querySelectorAll('a[href*="/item/"]'))
                .map(a => a.href.match(/\/item\/(\d+)\.html/)?.[1])
                .filter(Boolean)
        )];
        
        currentIds.forEach(id => allIds.add(id));
        console.log(`Найдено ${currentIds.length} товаров, всего уникальных: ${allIds.size}`);
        
        // Проверяем прогресс
        if (allIds.size === previousCount) {
            stagnantCount++;
        } else {
            stagnantCount = 0;
        }
        previousCount = allIds.size;
        
        // Ищем кнопку следующей страницы
        const nextSelectors = [
            'button[aria-label*="Next"]',
            'a[aria-label*="Next"]',
            '.comet-pagination-next',
            '.next',
            '.pagination button:last-child:not([disabled])',
            '[class*="next"]:not([disabled])'
        ];
        
        let nextButton = null;
        
        // Сначала пробуем стандартные селекторы
        for (const selector of nextSelectors) {
            try {
                nextButton = document.querySelector(selector);
                if (nextButton && !nextButton.disabled) break;
            } catch (e) {
                continue;
            }
        }
        
        // Если не нашли, ищем по тексту и символам
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
            
            // Ждем загрузки
            await new Promise(resolve => setTimeout(resolve, 4000));
            
            // Дополнительное ожидание появления товаров
            let attempts = 0;
            while (attempts < 10) {
                const newItems = document.querySelectorAll('a[href*="/item/"]').length;
                if (newItems > 0) break;
                await new Promise(resolve => setTimeout(resolve, 500));
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
