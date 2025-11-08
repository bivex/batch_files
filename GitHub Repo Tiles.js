// ==UserScript==
// @name         GitHub Repo Tiles
// @namespace    http://tampermonkey.net/
// @version      1.2
// @description  Красивая плитка репозиториев, структурно и информативно
// @author       AI
// @match        https://github.com/bivex?tab=repositories
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    const repoList = document.querySelector('#user-repositories-list ul');
    if (!repoList) return;

    const style = document.createElement('style');
    style.textContent = `
    .repo-tile-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(340px,1fr)); gap: 16px; margin-top: 20px; }
    .repo-tile { background: #f6f8fa; border: 1px solid #d0d7de; border-radius: 8px; padding: 16px; box-shadow: 0 2px 8px rgba(27,31,35,.04); font-size: 15px; display: flex; flex-direction: column; gap: 8px; }
    .repo-tile a { font-weight: bold; font-size: 16px; color: #0969da !important; text-decoration: none; }
    .repo-tile .repo-description { color: #24292f; font-size: 14px; margin: 3px 0 7px; }
    .repo-tile .repo-meta { font-size: 12px; background: #eaecef; border-radius: 5px; padding: 3px 7px; margin-right: 7px; display: inline-block; }
    .repo-tile .repo-license { font-size: 11px; color: #707070; background: #fffbe6; border-radius: 4px; padding: 2px 6px; margin-left: 4px; }
    .repo-tile .repo-fork { font-size:12px; color:#666; margin-left:4px; }
    `;
    document.head.appendChild(style);

    const repos = Array.from(repoList.querySelectorAll('li'));
    const grid = document.createElement('div');
    grid.className = 'repo-tile-grid';

    repos.forEach(repo => {
        const titleElem = repo.querySelector('a[itemprop="name codeRepository"]');
        const descElem = repo.querySelector('p[itemprop="description"]');
        const topicElems = repo.querySelectorAll('.topic-tag');
        const langElem = repo.querySelector('[itemprop="programmingLanguage"]');
        const updatedElem = repo.querySelector('relative-time');
        const licenseElem = Array.from(repo.querySelectorAll('svg[class*="octicon-law"] ~ span')).find(e => e.textContent.includes('License'));
        const forkElem = repo.querySelector('.mr-1.Link--muted');

        const title = titleElem?.innerText ?? '';
        const link = titleElem?.href ?? '#';
        const desc = descElem?.innerText ?? 'Нет описания';
        const lang = langElem?.innerText ?? '';
        const updated = updatedElem?.innerText ?? '';
        const license = licenseElem?.textContent ?? '';
        const topics = Array.from(topicElems).map(el => el.innerText).join(', ');
        const forked = forkElem ? forkElem.innerText : '';

        const tile = document.createElement('div');
        tile.className = 'repo-tile';
        tile.innerHTML = `
            <a href="${link}" target="_blank">${title}</a>
            <div class="repo-description">${desc}</div>
            <div>
                ${topics ? `<span class="repo-meta">${topics}</span>` : ''}
                ${lang ? `<span class="repo-meta">Язык: ${lang}</span>` : ''}
                ${updated ? `<span class="repo-meta">Обновлено: ${updated}</span>` : ''}
                ${license ? `<span class="repo-license">${license}</span>` : ''}
                ${forked ? `<span class="repo-fork">Forked from ${forked}</span>` : ''}
            </div>
        `;
        grid.appendChild(tile);
    });

    repoList.innerHTML = '';
    repoList.appendChild(grid);

})();
