#!/usr/bin/env python3
"""
Скрипт для подсчета файлов и строк кода в проекте
"""

import os
import sys
from pathlib import Path
from collections import defaultdict
import argparse


class CodeCounter:
    def __init__(self, project_path, exclude_dirs=None, exclude_files=None):
        self.project_path = Path(project_path)
        self.exclude_dirs = exclude_dirs or {
            '__pycache__', '.git', '.vscode', '.idea', 'venv', 'env', 
            'node_modules', '.pytest_cache', 'logs', 'photos', 'dbexport',
            'tests', 'docs', 'config_examples'
        }
        self.exclude_files = exclude_files or {
            '.gitignore', '.env', 'requirements.txt', '*.log', '*.db',
            '*.sql', '*.md', '*.txt', '*.bat', '*.sh', '*.service',
            '*.html', '*.backup'
        }
        
        # Расширения файлов для подсчета
        self.code_extensions = {
            '.py': 'Python',
            '.js': 'JavaScript',
            '.ts': 'TypeScript',
            '.jsx': 'React JSX',
            '.tsx': 'React TSX',
            '.html': 'HTML',
            '.css': 'CSS',
            '.scss': 'SCSS',
            '.sql': 'SQL',
            '.json': 'JSON',
            '.xml': 'XML',
            '.yaml': 'YAML',
            '.yml': 'YAML',
            '.sh': 'Shell Script',
            '.bat': 'Batch Script',
            '.md': 'Markdown',
            '.txt': 'Text',
            '.cfg': 'Config',
            '.ini': 'Config',
            '.conf': 'Config'
        }
    
    def should_exclude_file(self, file_path):
        """Проверяет, нужно ли исключить файл из подсчета"""
        file_name = file_path.name
        
        # Проверяем исключенные файлы
        for exclude_pattern in self.exclude_files:
            if exclude_pattern.startswith('*'):
                if file_name.endswith(exclude_pattern[1:]):
                    return True
            elif file_name == exclude_pattern:
                return True
        
        return False
    
    def should_exclude_dir(self, dir_path):
        """Проверяет, нужно ли исключить директорию из подсчета"""
        return dir_path.name in self.exclude_dirs
    
    def count_lines_in_file(self, file_path):
        """Подсчитывает строки в файле"""
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                lines = f.readlines()
                total_lines = len(lines)
                non_empty_lines = len([line for line in lines if line.strip()])
                return total_lines, non_empty_lines
        except Exception as e:
            print(f"Ошибка при чтении файла {file_path}: {e}")
            return 0, 0
    
    def scan_project(self):
        """Сканирует проект и собирает статистику"""
        stats = defaultdict(lambda: {
            'files': 0,
            'total_lines': 0,
            'non_empty_lines': 0,
            'file_list': []
        })
        
        total_files = 0
        total_lines = 0
        total_non_empty_lines = 0
        
        print(f"Сканирование проекта: {self.project_path}")
        print("=" * 60)
        
        for root, dirs, files in os.walk(self.project_path):
            root_path = Path(root)
            
            # Исключаем директории
            dirs[:] = [d for d in dirs if not self.should_exclude_dir(Path(d))]
            
            for file in files:
                file_path = root_path / file
                
                # Исключаем файлы
                if self.should_exclude_file(file_path):
                    continue
                
                # Определяем тип файла по расширению
                file_ext = file_path.suffix.lower()
                if file_ext in self.code_extensions:
                    file_type = self.code_extensions[file_ext]
                else:
                    file_type = 'Other'
                
                # Подсчитываем строки
                lines, non_empty_lines = self.count_lines_in_file(file_path)
                
                # Обновляем статистику
                stats[file_type]['files'] += 1
                stats[file_type]['total_lines'] += lines
                stats[file_type]['non_empty_lines'] += non_empty_lines
                stats[file_type]['file_list'].append({
                    'path': str(file_path.relative_to(self.project_path)),
                    'lines': lines,
                    'non_empty_lines': non_empty_lines
                })
                
                total_files += 1
                total_lines += lines
                total_non_empty_lines += non_empty_lines
        
        return stats, total_files, total_lines, total_non_empty_lines
    
    def print_statistics(self, stats, total_files, total_lines, total_non_empty_lines):
        """Выводит статистику"""
        print("\n📊 СТАТИСТИКА КОДА")
        print("=" * 60)
        
        # Общая статистика
        print(f"📁 Общее количество файлов: {total_files}")
        print(f"📝 Общее количество строк: {total_lines:,}")
        print(f"✨ Строк с кодом (не пустые): {total_non_empty_lines:,}")
        print(f"📈 Процент непустых строк: {(total_non_empty_lines/total_lines*100):.1f}%" if total_lines > 0 else "0%")
        
        print("\n📋 ПО ТИПАМ ФАЙЛОВ:")
        print("-" * 60)
        
        # Сортируем по количеству строк
        sorted_stats = sorted(stats.items(), key=lambda x: x[1]['total_lines'], reverse=True)
        
        for file_type, data in sorted_stats:
            if data['files'] > 0:
                avg_lines = data['total_lines'] / data['files']
                print(f"{file_type:15} | "
                      f"Файлов: {data['files']:4} | "
                      f"Строк: {data['total_lines']:6,} | "
                      f"Код: {data['non_empty_lines']:6,} | "
                      f"Среднее: {avg_lines:5.1f}")
        
        print("\n🔍 ТОП-10 САМЫХ БОЛЬШИХ ФАЙЛОВ:")
        print("-" * 60)
        
        # Собираем все файлы и сортируем по количеству строк
        all_files = []
        for file_type, data in stats.items():
            for file_info in data['file_list']:
                all_files.append((file_info['path'], file_info['lines'], file_type))
        
        all_files.sort(key=lambda x: x[1], reverse=True)
        
        for i, (file_path, lines, file_type) in enumerate(all_files[:10], 1):
            print(f"{i:2}. {file_path:40} | {lines:5,} строк | {file_type}")
    
    def save_detailed_report(self, stats, filename="code_report.txt"):
        """Сохраняет детальный отчет в файл"""
        report_path = self.project_path / filename
        
        with open(report_path, 'w', encoding='utf-8') as f:
            f.write("ДЕТАЛЬНЫЙ ОТЧЕТ ПО КОДУ\n")
            f.write("=" * 60 + "\n\n")
            
            for file_type, data in stats.items():
                if data['files'] > 0:
                    f.write(f"\n{file_type.upper()}:\n")
                    f.write("-" * 40 + "\n")
                    
                    # Сортируем файлы по количеству строк
                    sorted_files = sorted(data['file_list'], key=lambda x: x['lines'], reverse=True)
                    
                    for file_info in sorted_files:
                        f.write(f"{file_info['path']:50} | "
                               f"{file_info['lines']:5,} строк | "
                               f"{file_info['non_empty_lines']:5,} код\n")
        
        print(f"\n💾 Детальный отчет сохранен в: {report_path}")


def main():
    parser = argparse.ArgumentParser(description='Подсчет файлов и строк кода в проекте')
    parser.add_argument('path', nargs='?', default='.', 
                       help='Путь к проекту (по умолчанию: текущая директория)')
    parser.add_argument('--exclude-dirs', nargs='*', 
                       help='Дополнительные директории для исключения')
    parser.add_argument('--exclude-files', nargs='*',
                       help='Дополнительные файлы для исключения')
    parser.add_argument('--report', action='store_true',
                       help='Сохранить детальный отчет в файл')
    
    args = parser.parse_args()
    
    # Инициализируем счетчик
    exclude_dirs = set(args.exclude_dirs) if args.exclude_dirs else None
    exclude_files = set(args.exclude_files) if args.exclude_files else None
    
    counter = CodeCounter(args.path, exclude_dirs, exclude_files)
    
    # Сканируем проект
    stats, total_files, total_lines, total_non_empty_lines = counter.scan_project()
    
    # Выводим статистику
    counter.print_statistics(stats, total_files, total_lines, total_non_empty_lines)
    
    # Сохраняем детальный отчет если нужно
    if args.report:
        counter.save_detailed_report(stats)


if __name__ == "__main__":
    main()
