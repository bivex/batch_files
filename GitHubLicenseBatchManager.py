import requests
import json
import base64
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass
from datetime import datetime
import time

@dataclass
class LicenseResult:
    repo_name: str
    success: bool
    license_type: str
    message: str
    already_had_license: bool = False
    error: Optional[str] = None

class GitHubLicenseBatchManager:
    def __init__(self, token: str):
        self.token = token
        self.headers = {
            'Authorization': f'token {token}',
            'Accept': 'application/vnd.github.v3+json',
            'Content-Type': 'application/json'
        }
        self.base_url = 'https://api.github.com'
        
        # Доступные лицензии
        self.available_licenses = [
            'MIT', 'Apache-2.0', 'GPL-3.0', 'GPL-2.0', 'BSD-3-Clause',
            'BSD-2-Clause', 'ISC', 'LGPL-3.0', 'LGPL-2.1', 'Unlicense'
        ]
    
    def get_authenticated_user(self) -> Optional[str]:
        """Получение имени текущего пользователя"""
        url = f'{self.base_url}/user'
        response = requests.get(url, headers=self.headers)
        
        if response.status_code == 200:
            user_data = response.json()
            return user_data.get('login')
        return None
    
    def get_user_info(self) -> Optional[Dict]:
        """Получение информации о пользователе"""
        url = f'{self.base_url}/user'
        response = requests.get(url, headers=self.headers)
        
        if response.status_code == 200:
            return response.json()
        return None
    
    def get_my_repos(self, include_forks: bool = False) -> List[Tuple[str, str, Dict]]:
        """Получение всех репозиториев пользователя"""
        url = f'{self.base_url}/user/repos'
        params = {
            'type': 'all',
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
                
                all_repos.append((repo['owner']['login'], repo['name'], repo))
            
            print(f"📄 Обработана страница {page}, найдено {len(repos)} репозиториев")
            page += 1
            
            if page > 100:
                break
        
        print(f"✅ Всего найдено {len(all_repos)} репозиториев")
        return all_repos
    
    def check_existing_license(self, owner: str, repo: str) -> Optional[Dict]:
        """Проверка наличия лицензии в репозитории"""
        # Проверка через API
        url = f'{self.base_url}/repos/{owner}/{repo}'
        response = requests.get(url, headers=self.headers)
        
        if response.status_code == 200:
            repo_data = response.json()
            api_license = repo_data.get('license')
            if api_license:
                return {
                    'source': 'api',
                    'license': api_license.get('name', 'Unknown'),
                    'key': api_license.get('key', '')
                }
        
        # Проверка файлов лицензий
        license_files = ['LICENSE', 'LICENSE.txt', 'LICENSE.md', 'LICENCE', 'COPYING']
        
        for license_file in license_files:
            file_url = f'{self.base_url}/repos/{owner}/{repo}/contents/{license_file}'
            file_response = requests.get(file_url, headers=self.headers)
            
            if file_response.status_code == 200:
                return {
                    'source': 'file',
                    'license': 'Unknown (file exists)',
                    'file': license_file
                }
        
        return None
    
    def get_license_template(self, license_key: str) -> Optional[str]:
        """Получение шаблона лицензии"""
        url = f'{self.base_url}/licenses/{license_key}'
        response = requests.get(url, headers=self.headers)
        
        if response.status_code == 200:
            return response.json()['body']
        return None
    
    def prepare_license_content(self, license_key: str, author_name: str = None, 
                               author_email: str = None, year: int = None) -> Optional[str]:
        """Подготовка содержимого лицензии с заменой placeholders"""
        license_content = self.get_license_template(license_key)
        if not license_content:
            return None
        
        # Замена placeholders
        current_year = year or datetime.now().year
        
        replacements = {
            '[year]': str(current_year),
            '[yyyy]': str(current_year),
            '[fullname]': author_name or 'Author',
            '[name of copyright owner]': author_name or 'Author',
            '[email]': author_email or 'author@example.com'
        }
        
        for placeholder, replacement in replacements.items():
            license_content = license_content.replace(placeholder, replacement)
        
        return license_content
    
    def add_license_to_repo(self, owner: str, repo: str, license_key: str,
                           author_name: str = None, author_email: str = None,
                           force: bool = False) -> LicenseResult:
        """Добавление лицензии в репозиторий"""
        repo_full_name = f"{owner}/{repo}"
        
        # Проверка существующей лицензии
        existing_license = self.check_existing_license(owner, repo)
        if existing_license and not force:
            return LicenseResult(
                repo_name=repo_full_name,
                success=False,
                license_type=existing_license['license'],
                message=f"Лицензия уже существует: {existing_license['license']}",
                already_had_license=True
            )
        
        # Подготовка содержимого лицензии
        license_content = self.prepare_license_content(license_key, author_name, author_email)
        if not license_content:
            return LicenseResult(
                repo_name=repo_full_name,
                success=False,
                license_type=license_key,
                message="Не удалось получить шаблон лицензии",
                error="Template not found"
            )
        
        # Создание файла LICENSE
        url = f'{self.base_url}/repos/{owner}/{repo}/contents/LICENSE'
        
        content_encoded = base64.b64encode(license_content.encode('utf-8')).decode('utf-8')
        
        data = {
            'message': f'Add {license_key} license',
            'content': content_encoded,
            'committer': {
                'name': author_name or 'GitHub API',
                'email': author_email or 'noreply@github.com'
            }
        }
        
        response = requests.put(url, headers=self.headers, json=data)
        
        if response.status_code == 201:
            return LicenseResult(
                repo_name=repo_full_name,
                success=True,
                license_type=license_key,
                message="Лицензия успешно добавлена"
            )
        else:
            error_msg = "Unknown error"
            if response.status_code == 409:
                error_msg = "Файл LICENSE уже существует"
            elif response.status_code == 403:
                error_msg = "Нет прав на запись в репозиторий"
            elif response.status_code == 404:
                error_msg = "Репозиторий не найден"
            
            return LicenseResult(
                repo_name=repo_full_name,
                success=False,
                license_type=license_key,
                message=f"Ошибка добавления лицензии: {error_msg}",
                error=f"HTTP {response.status_code}"
            )
    
    def batch_add_licenses(self, license_key: str, author_name: str = None,
                          author_email: str = None, include_forks: bool = False,
                          force: bool = False, exclude_repos: List[str] = None,
                          include_only: List[str] = None) -> List[LicenseResult]:
        """Массовое добавление лицензий во все репозитории"""
        
        exclude_repos = exclude_repos or []
        
        # Получение информации о пользователе
        user_info = self.get_user_info()
        if user_info and not author_name:
            author_name = user_info.get('name') or user_info.get('login')
        if user_info and not author_email:
            author_email = user_info.get('email')
        
        # Получение списка репозиториев
        repos = self.get_my_repos(include_forks=include_forks)
        
        # Фильтрация репозиториев
        if include_only:
            repos = [(o, r, d) for o, r, d in repos if f"{o}/{r}" in include_only]
        
        repos = [(o, r, d) for o, r, d in repos if f"{o}/{r}" not in exclude_repos]
        
        if not repos:
            print("❌ Нет репозиториев для обработки")
            return []
        
        print(f"\n🚀 Начинаем добавление лицензии {license_key} в {len(repos)} репозиториев")
        print(f"👤 Автор: {author_name}")
        print(f"📧 Email: {author_email}")
        print(f"🔄 Принудительное обновление: {'Да' if force else 'Нет'}")
        
        results = []
        
        for i, (owner, repo, repo_data) in enumerate(repos, 1):
            print(f"\n[{i}/{len(repos)}] Обработка {owner}/{repo}...")
            
            # Задержка для избежания rate limiting
            if i > 1:
                time.sleep(1)
            
            result = self.add_license_to_repo(
                owner, repo, license_key, author_name, author_email, force
            )
            
            results.append(result)
            
            # Вывод результата
            if result.success:
                print(f"✅ {result.message}")
            elif result.already_had_license:
                print(f"⚠️ {result.message}")
            else:
                print(f"❌ {result.message}")
        
        return results
    
    def interactive_batch_setup(self):
        """Интерактивная настройка batch добавления лицензий"""
        print("🎯 Интерактивная настройка добавления лицензий")
        print("=" * 50)
        
        # Получение информации о пользователе
        user_info = self.get_user_info()
        if not user_info:
            print("❌ Не удалось получить информацию о пользователе")
            return
        
        username = user_info.get('login')
        user_name = user_info.get('name') or username
        user_email = user_info.get('email')
        
        print(f"👤 Пользователь: {username}")
        print(f"📝 Имя: {user_name}")
        print(f"📧 Email: {user_email or 'Не указан'}")
        
        # Выбор лицензии
        print(f"\n📋 Доступные лицензии:")
        for i, license_type in enumerate(self.available_licenses, 1):
            print(f"{i}. {license_type}")
        
        while True:
            try:
                choice = input(f"\nВыберите лицензию (1-{len(self.available_licenses)}): ").strip()
                license_index = int(choice) - 1
                if 0 <= license_index < len(self.available_licenses):
                    selected_license = self.available_licenses[license_index]
                    break
                else:
                    print("❌ Неверный выбор")
            except ValueError:
                print("❌ Введите число")
        
        # Настройка автора
        custom_name = input(f"\nИмя автора [{user_name}]: ").strip()
        author_name = custom_name if custom_name else user_name
        
        custom_email = input(f"Email автора [{user_email or 'noreply@github.com'}]: ").strip()
        author_email = custom_email if custom_email else (user_email or 'noreply@github.com')
        
        # Дополнительные опции
        include_forks = input("\nВключить форки? (y/n) [n]: ").strip().lower() in ['y', 'yes']
        force = input("Принудительно обновить существующие лицензии? (y/n) [n]: ").strip().lower() in ['y', 'yes']
        
        # Исключения
        exclude_input = input("\nРепозитории для исключения (через запятую): ").strip()
        exclude_repos = [repo.strip() for repo in exclude_input.split(',') if repo.strip()]
        
        # Подтверждение
        print(f"\n📊 Настройки:")
        print(f"   Лицензия: {selected_license}")
        print(f"   Автор: {author_name}")
        print(f"   Email: {author_email}")
        print(f"   Включить форки: {'Да' if include_forks else 'Нет'}")
        print(f"   Принудительное обновление: {'Да' if force else 'Нет'}")
        print(f"   Исключить: {', '.join(exclude_repos) if exclude_repos else 'Нет'}")
        
        confirm = input(f"\nПродолжить? (y/n): ").strip().lower()
        if confirm not in ['y', 'yes']:
            print("❌ Отменено")
            return
        
        # Запуск batch обработки
        results = self.batch_add_licenses(
            license_key=selected_license,
            author_name=author_name,
            author_email=author_email,
            include_forks=include_forks,
            force=force,
            exclude_repos=exclude_repos
        )
        
        # Отчет
        self.print_batch_report(results)
        
        # Сохранение отчета
        save_report = input("\n💾 Сохранить отчет в файл? (y/n): ").strip().lower()
        if save_report in ['y', 'yes']:
            self.save_batch_report(results, selected_license)
    
    def print_batch_report(self, results: List[LicenseResult]):
        """Вывод отчета о batch операции"""
        print("\n" + "=" * 80)
        print("📊 ОТЧЕТ О ДОБАВЛЕНИИ ЛИЦЕНЗИЙ")
        print("=" * 80)
        
        successful = [r for r in results if r.success]
        already_licensed = [r for r in results if r.already_had_license]
        failed = [r for r in results if not r.success and not r.already_had_license]
        
        print(f"\n✅ Успешно добавлено: {len(successful)}")
        print(f"⚠️ Уже имели лицензию: {len(already_licensed)}")
        print(f"❌ Ошибки: {len(failed)}")
        print(f"📈 Процент успеха: {len(successful) / len(results) * 100:.1f}%")
        
        if successful:
            print(f"\n{'='*20} УСПЕШНО ДОБАВЛЕНО {'='*20}")
            for result in successful:
                print(f"✅ {result.repo_name} - {result.license_type}")
        
        if already_licensed:
            print(f"\n{'='*20} УЖЕ ИМЕЛИ ЛИЦЕНЗИЮ {'='*20}")
            for result in already_licensed:
                print(f"⚠️ {result.repo_name} - {result.license_type}")
        
        if failed:
            print(f"\n{'='*20} ОШИБКИ {'='*20}")
            for result in failed:
                print(f"❌ {result.repo_name} - {result.message}")
    
    def save_batch_report(self, results: List[LicenseResult], license_type: str):
        """Сохранение отчета в файл"""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"license_batch_report_{license_type}_{timestamp}.json"
        
        report_data = {
            'timestamp': datetime.now().isoformat(),
            'license_type': license_type,
            'total_repos': len(results),
            'successful': len([r for r in results if r.success]),
            'already_licensed': len([r for r in results if r.already_had_license]),
            'failed': len([r for r in results if not r.success and not r.already_had_license]),
            'results': [
                {
                    'repo_name': r.repo_name,
                    'success': r.success,
                    'license_type': r.license_type,
                    'message': r.message,
                    'already_had_license': r.already_had_license,
                    'error': r.error
                }
                for r in results
            ]
        }
        
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(report_data, f, ensure_ascii=False, indent=2)
        
        print(f"💾 Отчет сохранен в {filename}")

def main():
    # Конфигурация
    GITHUB_TOKEN = "your_github_token_here"  # Замените на ваш токен
    
    if GITHUB_TOKEN == "your_github_token_here":
        print("❌ Установите ваш GitHub токен в переменную GITHUB_TOKEN")
        return
    
    license_manager = GitHubLicenseBatchManager(GITHUB_TOKEN)
    
    print("🚀 GitHub License Batch Manager")
    print("=" * 50)
    
    # Проверка аутентификации
    username = license_manager.get_authenticated_user()
    if not username:
        print("❌ Ошибка аутентификации. Проверьте токен.")
        return
    
    print(f"👤 Добро пожаловать, {username}!")
    
    # Интерактивный режим
    license_manager.interactive_batch_setup()

def batch_example():
    """Пример программного использования"""
    GITHUB_TOKEN = "your_github_token_here"
    
    license_manager = GitHubLicenseBatchManager(GITHUB_TOKEN)
    
    # Добавление MIT лицензии во все репозитории
    results = license_manager.batch_add_licenses(
        license_key='MIT',
        author_name='Your Name',
        author_email='your.email@example.com',
        include_forks=False,
        force=False,
        exclude_repos=['username/sensitive-repo', 'username/old-project']
    )
    
    # Вывод отчета
    license_manager.print_batch_report(results)

if __name__ == "__main__":
    main()
    
    # Раскомментируйте для программного использования
    # batch_example()
