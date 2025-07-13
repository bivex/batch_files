import requests
import json
import re
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass
from datetime import datetime

@dataclass
class LicenseInfo:
    has_license: bool
    license_type: Optional[str] = None
    license_file: Optional[str] = None
    confidence: str = "unknown"  # high, medium, low, unknown
    source: str = "none"  # api, file, readme, none

class GitHubLicenseAnalyzer:
    def __init__(self, token: str):
        """
        Инициализация с GitHub токеном
        """
        self.token = token
        self.headers = {
            'Authorization': f'token {token}',
            'Accept': 'application/vnd.github.v3+json',
            'Content-Type': 'application/json'
        }
        self.base_url = 'https://api.github.com'
        
        # Возможные имена файлов лицензий
        self.license_files = [
            'LICENSE', 'LICENSE.txt', 'LICENSE.md', 'LICENSE.rst',
            'LICENCE', 'LICENCE.txt', 'LICENCE.md', 'LICENCE.rst',
            'license', 'license.txt', 'license.md', 'license.rst',
            'licence', 'licence.txt', 'licence.md', 'licence.rst',
            'COPYING', 'COPYING.txt', 'COPYRIGHT', 'COPYRIGHT.txt'
        ]
        
        # Паттерны для поиска лицензий в README
        self.license_patterns = [
            r'(?i)license[d]?\s*under\s*(?:the\s*)?([^,\n]+)',
            r'(?i)licensed\s*under\s*(?:the\s*)?([^,\n]+)',
            r'(?i)license:\s*([^,\n]+)',
            r'(?i)licence:\s*([^,\n]+)',
            r'(?i)##\s*license\s*\n\s*([^#\n]+)',
            r'(?i)##\s*licence\s*\n\s*([^#\n]+)',
            r'(?i)MIT\s*License',
            r'(?i)Apache\s*License',
            r'(?i)GNU\s*General\s*Public\s*License',
            r'(?i)BSD\s*License',
            r'(?i)GPL\s*License'
        ]

    def get_authenticated_user(self) -> Optional[str]:
        """Получение имени текущего пользователя по токену"""
        url = f'{self.base_url}/user'
        response = requests.get(url, headers=self.headers)
        
        if response.status_code == 200:
            user_data = response.json()
            return user_data.get('login')
        else:
            print(f"❌ Ошибка получения данных пользователя: {response.status_code}")
            return None

    def get_my_repos(self, include_forks: bool = False, repo_type: str = 'all') -> List[Tuple[str, str]]:
        """
        Получение всех репозиториев текущего пользователя
        
        Args:
            include_forks: включать форки или нет
            repo_type: 'all', 'owner', 'public', 'private', 'member'
        """
        url = f'{self.base_url}/user/repos'
        params = {
            'type': repo_type,
            'per_page': 100,
            'sort': 'updated',
            'direction': 'desc'
        }
        
        all_repos = []
        page = 1
        
        print(f"🔍 Получаем список ваших репозиториев...")
        
        while True:
            params['page'] = page
            response = requests.get(url, headers=self.headers, params=params)
            
            if response.status_code != 200:
                print(f"❌ Ошибка при получении репозиториев: {response.status_code}")
                break
                
            repos = response.json()
            if not repos:
                break
            
            for repo in repos:
                # Фильтрация форков если нужно
                if not include_forks and repo.get('fork', False):
                    continue
                
                all_repos.append((repo['owner']['login'], repo['name']))
            
            print(f"📄 Обработана страница {page}, найдено {len(repos)} репозиториев")
            page += 1
            
            # Защита от бесконечного цикла
            if page > 100:  # GitHub API обычно не возвращает более 100 страниц
                break
        
        print(f"✅ Всего найдено {len(all_repos)} репозиториев")
        return all_repos

    def get_repo_license_from_api(self, owner: str, repo: str) -> Optional[Dict]:
        """Получение информации о лицензии через GitHub API"""
        url = f'{self.base_url}/repos/{owner}/{repo}'
        response = requests.get(url, headers=self.headers)
        
        if response.status_code == 200:
            repo_data = response.json()
            return repo_data.get('license')
        return None

    def get_repo_files(self, owner: str, repo: str, path: str = '') -> List[Dict]:
        """Получение списка файлов в репозитории"""
        url = f'{self.base_url}/repos/{owner}/{repo}/contents/{path}'
        response = requests.get(url, headers=self.headers)
        
        if response.status_code == 200:
            return response.json()
        return []

    def get_file_content(self, owner: str, repo: str, file_path: str) -> Optional[str]:
        """Получение содержимого файла"""
        url = f'{self.base_url}/repos/{owner}/{repo}/contents/{file_path}'
        response = requests.get(url, headers=self.headers)
        
        if response.status_code == 200:
            file_data = response.json()
            if file_data.get('content'):
                import base64
                content = base64.b64decode(file_data['content']).decode('utf-8', errors='ignore')
                return content
        return None

    def find_license_files(self, owner: str, repo: str) -> List[str]:
        """Поиск файлов лицензий в корне репозитория"""
        files = self.get_repo_files(owner, repo)
        license_files_found = []
        
        for file_info in files:
            if file_info['type'] == 'file' and file_info['name'] in self.license_files:
                license_files_found.append(file_info['name'])
        
        return license_files_found

    def analyze_license_content(self, content: str) -> Tuple[str, str]:
        """Анализ содержимого файла лицензии"""
        content_lower = content.lower()
        
        license_indicators = {
            'MIT': ['mit license', 'permission is hereby granted'],
            'Apache-2.0': ['apache license', 'version 2.0'],
            'GPL-3.0': ['gnu general public license', 'version 3'],
            'GPL-2.0': ['gnu general public license', 'version 2'],
            'BSD-3-Clause': ['bsd license', 'redistribution and use'],
            'BSD-2-Clause': ['bsd license', '2-clause'],
            'ISC': ['isc license', 'permission to use, copy, modify'],
            'Unlicense': ['unlicense', 'public domain'],
            'LGPL': ['lesser general public license', 'lgpl']
        }
        
        for license_type, indicators in license_indicators.items():
            if all(indicator in content_lower for indicator in indicators):
                return license_type, "high"
        
        # Поиск по одному индикатору (низкая уверенность)
        for license_type, indicators in license_indicators.items():
            if any(indicator in content_lower for indicator in indicators):
                return license_type, "medium"
        
        return "Unknown", "low"

    def search_license_in_readme(self, owner: str, repo: str) -> Optional[Tuple[str, str]]:
        """Поиск упоминаний лицензии в README файлах"""
        readme_files = ['README.md', 'README.rst', 'README.txt', 'README']
        
        for readme_file in readme_files:
            content = self.get_file_content(owner, repo, readme_file)
            if content:
                for pattern in self.license_patterns:
                    match = re.search(pattern, content)
                    if match:
                        license_mention = match.group(1).strip() if match.groups() else match.group(0)
                        return license_mention, "medium"
        
        return None

    def analyze_repository(self, owner: str, repo: str) -> LicenseInfo:
        """Полный анализ репозитория на наличие лицензии"""
        print(f"🔍 Анализ репозитория {owner}/{repo}...")
        
        # 1. Проверка через GitHub API
        api_license = self.get_repo_license_from_api(owner, repo)
        if api_license:
            return LicenseInfo(
                has_license=True,
                license_type=api_license.get('name', 'Unknown'),
                license_file=api_license.get('key', ''),
                confidence="high",
                source="api"
            )
        
        # 2. Поиск файлов лицензий
        license_files = self.find_license_files(owner, repo)
        if license_files:
            # Анализ первого найденного файла лицензии
            license_content = self.get_file_content(owner, repo, license_files[0])
            if license_content:
                license_type, confidence = self.analyze_license_content(license_content)
                return LicenseInfo(
                    has_license=True,
                    license_type=license_type,
                    license_file=license_files[0],
                    confidence=confidence,
                    source="file"
                )
        
        # 3. Поиск в README файлах
        readme_license = self.search_license_in_readme(owner, repo)
        if readme_license:
            return LicenseInfo(
                has_license=True,
                license_type=readme_license[0],
                license_file="README",
                confidence=readme_license[1],
                source="readme"
            )
        
        # 4. Лицензия не найдена
        return LicenseInfo(
            has_license=False,
            confidence="high",
            source="none"
        )

    def analyze_multiple_repos(self, repo_list: List[Tuple[str, str]]) -> Dict[str, LicenseInfo]:
        """Анализ нескольких репозиториев"""
        results = {}
        total = len(repo_list)
        
        for i, (owner, repo) in enumerate(repo_list, 1):
            print(f"[{i}/{total}] ", end="")
            try:
                results[f"{owner}/{repo}"] = self.analyze_repository(owner, repo)
            except Exception as e:
                print(f"❌ Ошибка при анализе {owner}/{repo}: {e}")
                results[f"{owner}/{repo}"] = LicenseInfo(
                    has_license=False,
                    confidence="unknown",
                    source="error"
                )
        
        return results

    def analyze_all_my_repos(self, include_forks: bool = False, repo_type: str = 'all') -> Dict[str, LicenseInfo]:
        """Анализ всех репозиториев текущего пользователя"""
        # Получаем имя пользователя
        username = self.get_authenticated_user()
        if not username:
            print("❌ Не удалось получить данные пользователя")
            return {}
        
        print(f"👤 Анализ репозиториев пользователя: {username}")
        
        # Получаем все репозитории
        my_repos = self.get_my_repos(include_forks=include_forks, repo_type=repo_type)
        
        if not my_repos:
            print("❌ Не найдено ни одного репозитория")
            return {}
        
        # Анализируем все репозитории
        return self.analyze_multiple_repos(my_repos)

def print_license_report(results: Dict[str, LicenseInfo]):
    """Вывод отчета о лицензиях"""
    print("\n" + "="*80)
    print("📊 ОТЧЕТ О ЛИЦЕНЗИЯХ")
    print("="*80)
    
    licensed_repos = []
    unlicensed_repos = []
    
    for repo_name, license_info in results.items():
        if license_info.has_license:
            licensed_repos.append((repo_name, license_info))
        else:
            unlicensed_repos.append((repo_name, license_info))
    
    print(f"\n✅ Репозитории с лицензией: {len(licensed_repos)}")
    print(f"❌ Репозитории без лицензии: {len(unlicensed_repos)}")
    print(f"📈 Процент лицензированных: {len(licensed_repos) / len(results) * 100:.1f}%")
    
    # Статистика по типам лицензий
    license_stats = {}
    for _, license_info in licensed_repos:
        license_type = license_info.license_type or "Unknown"
        license_stats[license_type] = license_stats.get(license_type, 0) + 1
    
    if license_stats:
        print(f"\n📋 Статистика по типам лицензий:")
        for license_type, count in sorted(license_stats.items(), key=lambda x: x[1], reverse=True):
            print(f"   {license_type}: {count}")
    
    if licensed_repos:
        print(f"\n{'='*20} ЛИЦЕНЗИРОВАННЫЕ РЕПОЗИТОРИИ {'='*20}")
        for repo_name, license_info in licensed_repos:
            confidence_icon = {"high": "🟢", "medium": "🟡", "low": "🟠", "unknown": "⚪"}
            source_icon = {"api": "🔗", "file": "📄", "readme": "📖", "none": "❌"}
            
            print(f"{confidence_icon.get(license_info.confidence, '⚪')} {repo_name}")
            print(f"   📋 Лицензия: {license_info.license_type}")
            print(f"   {source_icon.get(license_info.source, '❓')} Источник: {license_info.source}")
            if license_info.license_file:
                print(f"   📁 Файл: {license_info.license_file}")
            print()
    
    if unlicensed_repos:
        print(f"\n{'='*20} РЕПОЗИТОРИИ БЕЗ ЛИЦЕНЗИИ {'='*20}")
        for repo_name, license_info in unlicensed_repos:
            print(f"❌ {repo_name}")
        print()

def save_results_to_json(results: Dict[str, LicenseInfo], filename: str = None):
    """Сохранение результатов в JSON файл"""
    if filename is None:
        filename = f"license_analysis_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    
    json_data = {}
    for repo_name, license_info in results.items():
        json_data[repo_name] = {
            'has_license': license_info.has_license,
            'license_type': license_info.license_type,
            'license_file': license_info.license_file,
            'confidence': license_info.confidence,
            'source': license_info.source
        }
    
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(json_data, f, ensure_ascii=False, indent=2)
    
    print(f"💾 Результаты сохранены в {filename}")

def main():
    # Конфигурация
    GITHUB_TOKEN = "your_github_token_here"  # Замените на ваш токен
    
    analyzer = GitHubLicenseAnalyzer(GITHUB_TOKEN)
    
    # Получение имени пользователя
    username = analyzer.get_authenticated_user()
    if username:
        print(f"👤 Добро пожаловать, {username}!")
    else:
        print("❌ Ошибка аутентификации. Проверьте токен.")
        return
    
    # Варианты анализа
    print("\n🔍 Выберите тип анализа:")
    print("1. Все репозитории (включая форки)")
    print("2. Только мои репозитории (без форков)")
    print("3. Только публичные репозитории")
    print("4. Только приватные репозитории")
    
    choice = input("\nВведите номер (1-4) или нажмите Enter для варианта 2: ").strip()
    
    if choice == "1":
        include_forks = True
        repo_type = 'all'
        print("🔄 Анализ всех репозиториев (включая форки)...")
    elif choice == "3":
        include_forks = False
        repo_type = 'public'
        print("🔄 Анализ только публичных репозиториев...")
    elif choice == "4":
        include_forks = False
        repo_type = 'private'
        print("🔄 Анализ только приватных репозиториев...")
    else:
        include_forks = False
        repo_type = 'all'
        print("🔄 Анализ только ваших репозиториев (без форков)...")
    
    # Запуск анализа
    results = analyzer.analyze_all_my_repos(include_forks=include_forks, repo_type=repo_type)
    
    if results:
        # Вывод отчета
        print_license_report(results)
        
        # Сохранение результатов
        save_choice = input("\n💾 Сохранить результаты в файл? (y/n): ").strip().lower()
        if save_choice in ['y', 'yes', 'да', 'д']:
            save_results_to_json(results)
    else:
        print("❌ Не удалось получить результаты анализа")

if __name__ == "__main__":
    main()
