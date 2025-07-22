#!/usr/bin/env python3
"""
Script for DPy-Kanboard integration: synchronizes code smells from DPy JSON files to Kanboard tasks
"""

import requests
import os
import glob
import json
from typing import Dict, List, Optional
import sys
import argparse
from datetime import datetime
import time
import schedule
import concurrent.futures

class KanboardClient:
    """Client for interacting with Kanboard API using JSON-RPC"""
    def __init__(self, base_url: str, token: str):
        self.base_url = base_url
        self.token = token
        self.session = requests.Session()
        self.request_id = 1
        self.session.auth = ('jsonrpc', token)

    def _make_request(self, method: str, params: Dict) -> Optional[Dict]:
        payload = {
            "jsonrpc": "2.0",
            "method": method,
            "id": self.request_id,
            "params": params
        }
        headers = {'Content-Type': 'application/json'}
        try:
            response = self.session.post(self.base_url, json=payload, headers=headers)
            response.raise_for_status()
            result = response.json()
            self.request_id += 1
            if 'error' in result:
                print(f"Kanboard API error: {result['error']}")
                return None
            return result.get('result')
        except requests.exceptions.RequestException as e:
            print(f"Error making request to Kanboard: {e}")
            return None

    def test_connection(self) -> bool:
        result = self._make_request('getVersion', {})
        if result:
            print(f"Connected to Kanboard version: {result}")
            return True
        return False

    def get_project_by_id(self, project_id: int) -> Optional[Dict]:
        return self._make_request('getProjectById', {'project_id': project_id})

    def get_project_columns(self, project_id: int) -> List[Dict]:
        return self._make_request('getColumns', {'project_id': project_id}) or []

    def create_task(self, task_data: Dict) -> Optional[int]:
        return self._make_request('createTask', task_data)

    def get_all_tasks(self, project_id: int) -> List[Dict]:
        return self._make_request('getAllTasks', {'project_id': project_id}) or []

    def update_task(self, task_id: int, task_data: Dict) -> bool:
        task_data['id'] = task_id
        result = self._make_request('updateTask', task_data)
        return result is not None

    def close_task(self, task_id: int) -> bool:
        result = self._make_request('closeTask', {'task_id': task_id})
        return result is not None

    def move_task_to_column(self, task_id: int, column_id: int) -> bool:
        task = self._make_request('getTask', {'task_id': task_id})
        if not task:
            return False
        project_id = int(task.get('project_id', 0))
        swimlane_id = int(task.get('swimlane_id', 0))
        result = self._make_request('moveTaskPosition', {
            'project_id': project_id,
            'task_id': task_id,
            'column_id': column_id,
            'position': 1,
            'swimlane_id': swimlane_id
        })
        return result is not None

    def get_task_by_reference(self, project_id: int, reference: str) -> Optional[Dict]:
        tasks = self.get_all_tasks(project_id)
        for task in tasks:
            if task.get('reference') == reference:
                return task
        return None

# --- DPySmellLoader ---
class DPySmellLoader:
    """Loads all *_smells.json files and parses smell entries"""
    def __init__(self, directory: str = '.'): 
        self.directory = directory
        self.smell_files = glob.glob(os.path.join(directory, '*_smells.json'))
        self.smells = []
        self.load_all_smells()

    def load_all_smells(self):
        for file in self.smell_files:
            try:
                with open(file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    for entry in data:
                        entry['__source_file'] = os.path.basename(file)
                        self.smells.append(entry)
            except Exception as e:
                print(f"Failed to load {file}: {e}")

    def get_smells(self) -> List[Dict]:
        return self.smells

# --- DPyKanboardIntegration ---
class DPyKanboardIntegration:
    def __init__(self, kanboard_client: KanboardClient, project_id: int, smells: List[Dict]):
        self.kanboard_client = kanboard_client
        self.project_id = project_id
        self.smells = smells
        self.columns = {}

    def initialize(self) -> bool:
        print("Initializing DPy-Kanboard integration...")
        if not self.kanboard_client.test_connection():
            print("Failed to connect to Kanboard")
            return False
        project = self.kanboard_client.get_project_by_id(self.project_id)
        if not project:
            print(f"Project ID {self.project_id} not found")
            return False
        print(f"Connected to project: {project.get('name', 'Unknown')} (ID: {self.project_id})")
        columns = self.kanboard_client.get_project_columns(self.project_id)
        self.columns = {col['title']: int(col['id']) for col in columns}
        print(f"Available columns: {list(self.columns.keys())}")
        return True

    def smell_to_reference(self, smell: Dict) -> str:
        # Unique reference for each smell
        file = os.path.basename(smell.get('File', smell.get('__source_file', 'unknown')))
        line = smell.get('Line no', 'unknown')
        smell_type = smell.get('Smell', 'unknown')
        return f"dpy-{file}-{line}-{smell_type}"

    def map_smell_to_task(self, smell: Dict, column_id: int) -> Dict:
        title = f"[{smell.get('Smell', 'Smell')}] {smell.get('Function/Method', '')} in {os.path.basename(smell.get('File', smell.get('__source_file', 'unknown')))}"
        if len(title) > 255:
            title = title[:252] + "..."
        description_parts = [
            f"**DPy Code Smell Integration**",
            f"",
            f"**Smell:** {smell.get('Smell', '')}",
            f"**File:** {smell.get('File', '')}",
            f"**Module:** {smell.get('Module', '')}",
            f"**Class:** {smell.get('Class', '')}",
            f"**Function/Method:** {smell.get('Function/Method', '')}",
            f"**Line(s):** {smell.get('Line no', '')}",
            f"**Details:** {smell.get('Details', '')}",
            f"**Source JSON:** {smell.get('__source_file', '')}",
            f"**Last Updated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
        ]
        description = '\n\n'.join(description_parts)
        color = 'yellow' if 'Complex' in smell.get('Smell', '') else 'orange'
        return {
            'project_id': self.project_id,
            'title': title,
            'description': description,
            'column_id': column_id,
            'color_id': color,
            'reference': self.smell_to_reference(smell)
        }

    def synchronize_smells(self, target_column: str = 'Ожидающие', resolved_column: str = 'Выполнено') -> Dict:
        print(f"\n=== Starting synchronization at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} ===")
        print("Fetching tasks from Kanboard...")
        existing_tasks = self.kanboard_client.get_all_tasks(self.project_id)
        existing_refs = {task.get('reference', ''): task for task in existing_tasks}
        stats = {'created': 0, 'updated': 0, 'errors': 0}
        target_column_id = self.columns.get(target_column, list(self.columns.values())[0])
        print(f"Target column: {target_column} (ID: {target_column_id})")
        total_smells = len(self.smells)

        def process_smell(smell):
            reference = self.smell_to_reference(smell)
            existing_task = existing_refs.get(reference)
            task_data = self.map_smell_to_task(smell, target_column_id)
            max_retries = 3
            for attempt in range(max_retries):
                try:
                    if existing_task:
                        if self.kanboard_client.update_task(existing_task['id'], {
                            'title': task_data['title'],
                            'description': task_data['description'],
                            'color_id': task_data['color_id']
                        }):
                            print(f"  ↳ ✓ Updated: {smell.get('Details', '')[:50]}...")
                            return 'updated'
                        else:
                            print(f"  ↳ ✗ Failed to update: {smell.get('Details', '')[:50]}...")
                            return 'errors'
                    else:
                        task_id = self.kanboard_client.create_task(task_data)
                        if task_id:
                            print(f"  ↳ ✓ Created: {smell.get('Details', '')[:50]}...")
                            return 'created'
                        else:
                            print(f"  ↳ ✗ Failed to create: {smell.get('Details', '')[:50]}...")
                            return 'errors'
                except Exception as e:
                    err_str = str(e)
                    if 'database is locked' in err_str and attempt < max_retries - 1:
                        print(f"  ↳ Retrying due to database lock (attempt {attempt+2}/{max_retries})...")
                        time.sleep(1)
                        continue
                    print(f"  ↳ ✗ Exception: {e}")
                    return 'errors'

        with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
            results = list(executor.map(process_smell, self.smells))
        for r in results:
            if r in stats:
                stats[r] += 1
        return stats

    def get_integration_status(self) -> Dict:
        existing_tasks = self.kanboard_client.get_all_tasks(self.project_id)
        smell_refs = {self.smell_to_reference(smell) for smell in self.smells}
        kanboard_refs = {task.get('reference', '') for task in existing_tasks if task.get('reference', '').startswith('dpy-')}
        return {
            'smells_total': len(smell_refs),
            'kanboard_tasks': len(kanboard_refs),
            'synchronized': len(smell_refs.intersection(kanboard_refs)),
            'missing_in_kanboard': len(smell_refs - kanboard_refs),
            'orphaned_in_kanboard': len(kanboard_refs - smell_refs)
        }

    def run_continuous_sync(self, interval_minutes: int = 30, target_column: str = 'Ожидающие', resolved_column: str = 'Выполнено'):
        print(f"Starting continuous sync every {interval_minutes} minutes...")
        schedule.every(interval_minutes).minutes.do(self.synchronize_smells, target_column, resolved_column)
        self.synchronize_smells(target_column, resolved_column)
        while True:
            schedule.run_pending()
            time.sleep(60)

# --- Main CLI ---
def main():
    # Configuration (edit as needed or use env vars)
    KANBOARD_URL = 'https://URL/jsonrpc.php'
    KANBOARD_TOKEN = ''
    PROJECT_ID = 1

    parser = argparse.ArgumentParser(description='DPy-Kanboard Integration')
    parser.add_argument('--mode', choices=['sync', 'continuous', 'status', 'count'], default='sync', help='Integration mode (sync, continuous, status, count)')
    parser.add_argument('--target-column', default='Ожидающие', help='Target column for open issues')
    parser.add_argument('--resolved-column', default='Выполнено', help='Target column for resolved issues')
    parser.add_argument('--interval', type=int, default=30, help='Sync interval in minutes for continuous mode')
    parser.add_argument('--dry-run', action='store_true', help='Show what would be synchronized')
    parser.add_argument('--directory', default='.', help='Directory with *_smells.json files')
    args = parser.parse_args()

    # Load smells
    loader = DPySmellLoader(args.directory)
    smells = loader.get_smells()
    if args.mode == 'count':
        print(f"Found {len(smells)} smells in JSON files.")
        sys.exit(0)
    if not smells:
        print("No smells found in JSON files.")
        sys.exit(1)

    # Initialize Kanboard client
    kanboard_client = KanboardClient(KANBOARD_URL, KANBOARD_TOKEN)
    integration = DPyKanboardIntegration(kanboard_client, PROJECT_ID, smells)
    if not integration.initialize():
        sys.exit(1)

    if args.mode == 'status':
        status = integration.get_integration_status()
        print(f"\n=== Integration Status ===")
        print(f"Smells: {status['smells_total']} total")
        print(f"Kanboard tasks: {status['kanboard_tasks']}")
        print(f"Synchronized: {status['synchronized']}")
        print(f"Missing in Kanboard: {status['missing_in_kanboard']}")
        print(f"Orphaned in Kanboard: {status['orphaned_in_kanboard']}")
    elif args.mode == 'sync':
        if args.dry_run:
            print("Dry run mode - no actual changes will be made")
            # Add dry run logic if needed
        else:
            stats = integration.synchronize_smells(args.target_column, args.resolved_column)
            print(f"\n=== Synchronization Results ===")
            print(f"Created: {stats['created']}")
            print(f"Updated: {stats['updated']}")
            print(f"Errors: {stats['errors']}")
    elif args.mode == 'continuous':
        try:
            integration.run_continuous_sync(args.interval, args.target_column, args.resolved_column)
        except KeyboardInterrupt:
            print("\nStopping continuous sync...")

if __name__ == '__main__':
    main() 
