// Находим все ссылки на товары и извлекаем ID
const productIds = Array.from(document.querySelectorAll('a[href*="/item/"]'))
  .map(link => {
    const match = link.href.match(/\/item\/(\d+)\.html/);
    return match ? match[1] : null;
  })
  .filter(id => id !== null)
  .filter((id, index, array) => array.indexOf(id) === index); // убираем дубликаты

// Выводим через запятую
console.log(productIds.join(', '));
