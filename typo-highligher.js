(() => {
  const fonts = new Map();
  const colors = {};

  // Генератор случайных пастельных цветов
  function randomColor() {
    const r = Math.floor(150 + Math.random() * 100);
    const g = Math.floor(150 + Math.random() * 100);
    const b = Math.floor(150 + Math.random() * 100);
    return `rgba(${r}, ${g}, ${b}, 0.35)`;
  }

  document.querySelectorAll("*").forEach(el => {
    const style = getComputedStyle(el);

    const key = JSON.stringify({
      fontFamily: style.fontFamily,
      fontSize: style.fontSize,
      fontWeight: style.fontWeight,
      fontStyle: style.fontStyle,
      lineHeight: style.lineHeight,
      letterSpacing: style.letterSpacing,
      textTransform: style.textTransform
    });

    if (!fonts.has(key)) {
      fonts.set(key, { ...JSON.parse(key), count: 0, tags: [] });
      colors[key] = randomColor();
    }

    const entry = fonts.get(key);
    entry.count++;
    entry.tags.push(el.tagName.toLowerCase());

    // Подсветка элементов
    el.style.outline = `2px solid ${colors[key]}`;
    el.style.backgroundColor = colors[key];
  });

  console.table(
    [...fonts.values()].map(f => ({
      "Font Family": f.fontFamily,
      "Font Size": f.fontSize,
      "Font Weight": f.fontWeight,
      "Font Style": f.fontStyle,
      "Line Height": f.lineHeight,
      "Letter Spacing": f.letterSpacing,
      "Text Transform": f.textTransform,
      "Elements Count": f.count,
      "Example Tags": [...new Set(f.tags)].slice(0, 8).join(", ")
        + (f.tags.length > 8 ? " ..." : "")
    }))
  );

  console.log("✅ Подсветка включена: каждый уникальный набор шрифтов выделен своим цветом");
})();
