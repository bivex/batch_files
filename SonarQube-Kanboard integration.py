#!/usr/bin/env python3
"""
Script for SonarQube-Kanboard integration with enhanced diagnostics
"""

import requests
from typing import Dict, List, Optional
import sys
import argparse
from datetime import datetime
import time
import schedule


class SonarQubeClient:
    """Client for interacting with SonarQube API"""

    def __init__(self, base_url: str, token: str):
        self.base_url = base_url.rstrip('/')
        self.token = token
        self.session = requests.Session()
        self.session.auth = (token, '')

    def get_issues_detailed(self, project_key: str, include_resolved: bool = False) -> List[Dict]:
        """Fetch ALL issues with detailed information using pagination"""
        url = f"{self.base_url}/api/issues/search"
        params = {
            'componentKeys': project_key,
            'ps': 500,  # Page size
            'facets': 'types,severities,resolutions'
        }

        if not include_resolved:
            params['resolved'] = 'false'

        all_issues = []
        page = 1
        total = None

        try:
            while total is None or len(all_issues) < total:
                params['p'] = page
                response = self.session.get(url, params=params)
                response.raise_for_status()
                data = response.json()
                
                issues = data.get('issues', [])
                all_issues.extend(issues)
                
                # Update total on first page
                if total is None:
                    total = data.get('total', 0)
                    print(f"Found {total} issues in SonarQube")
                
                # Break if no more issues or empty page
                if not issues:
                    break
                
                page += 1
                print(f"Fetched page {page-1}, got {len(issues)} issues (total: {len(all_issues)}/{total})")
            
            return all_issues
        except requests.exceptions.RequestException as e:
            print(f"Error fetching issues from SonarQube: {e}")
            return []

    def get_issues_by_type_and_resolution(self, project_key: str) -> Dict:
        """Get issues organized by type and resolution status"""
        all_issues = self.get_issues_detailed(project_key, include_resolved=True)

        organized_issues = {
            'unresolved': {
                'CODE_SMELL': [],
                'BUG': [],
                'VULNERABILITY': []
            },
            'resolved': {
                'CODE_SMELL': [],
                'BUG': [],
                'VULNERABILITY': []
            }
        }

        for issue in all_issues:
            issue_type = issue.get('type', 'UNKNOWN')
            resolution = issue.get('resolution')

            if issue_type in organized_issues['unresolved']:
                if resolution:
                    organized_issues['resolved'][issue_type].append(issue)
                else:
                    organized_issues['unresolved'][issue_type].append(issue)

        return organized_issues

    def get_project_quality_gate(self, project_key: str) -> Dict:
        """Get project quality gate status"""
        url = f"{self.base_url}/api/qualitygates/project_status"
        params = {'projectKey': project_key}

        try:
            response = self.session.get(url, params=params)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"Error fetching quality gate: {e}")
            return {}


class KanboardClient:
    """Client for interacting with Kanboard API using JSON-RPC"""

    def __init__(self, base_url: str, token: str):
        self.base_url = base_url
        self.token = token
        self.session = requests.Session()
        self.request_id = 1
        self.session.auth = ('jsonrpc', token)

    def _make_request(self, method: str, params: Dict) -> Optional[Dict]:
        """Make a JSON-RPC request to Kanboard"""
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
        """Test the connection"""
        result = self._make_request('getVersion', {})
        if result:
            print(f"Connected to Kanboard version: {result}")
            return True
        return False

    def get_project_by_id(self, project_id: int) -> Optional[Dict]:
        """Get project by ID"""
        return self._make_request('getProjectById', {'project_id': project_id})

    def get_project_columns(self, project_id: int) -> List[Dict]:
        """Get columns for a project"""
        return self._make_request('getColumns', {'project_id': project_id}) or []

    def create_task(self, task_data: Dict) -> Optional[int]:
        """Create a new task in Kanboard"""
        return self._make_request('createTask', task_data)

    def get_all_tasks(self, project_id: int) -> List[Dict]:
        """Get all tasks for a project"""
        return self._make_request('getAllTasks', {'project_id': project_id}) or []

    def update_task(self, task_id: int, task_data: Dict) -> bool:
        """Update an existing task"""
        task_data['id'] = task_id
        result = self._make_request('updateTask', task_data)
        return result is not None

    def close_task(self, task_id: int) -> bool:
        """Close a task"""
        result = self._make_request('closeTask', {'task_id': task_id})
        return result is not None

    def move_task_to_column(self, task_id: int, column_id: int) -> bool:
        """Move task to specific column"""
        result = self._make_request('moveTaskPosition', {
            'task_id': task_id,
            'column_id': column_id,
            'position': 1
        })
        return result is not None

    def get_task_by_reference(self, project_id: int, reference: str) -> Optional[Dict]:
        """Get task by reference"""
        tasks = self.get_all_tasks(project_id)
        for task in tasks:
            if task.get('reference') == reference:
                return task
        return None


class SonarKanboardIntegration:
    """Main integration class"""

    def __init__(self, sonar_client: SonarQubeClient, kanboard_client: KanboardClient,
                 project_id: int, sonar_project_key: str):
        self.sonar_client = sonar_client
        self.kanboard_client = kanboard_client
        self.project_id = project_id
        self.sonar_project_key = sonar_project_key
        self.columns = {}
        self.type_mappings = {
            'CODE_SMELL': 'Maintainability',
            'BUG': 'Reliability',
            'VULNERABILITY': 'Security'
        }

    def initialize(self) -> bool:
        """Initialize integration"""
        print("Initializing SonarQube-Kanboard integration...")

        # Test connections
        if not self.kanboard_client.test_connection():
            print("Failed to connect to Kanboard")
            return False

        project = self.kanboard_client.get_project_by_id(self.project_id)
        if not project:
            print(f"Project ID {self.project_id} not found")
            return False

        print(f"Connected to project: {project.get('name', 'Unknown')} (ID: {self.project_id})")

        # Get columns
        columns = self.kanboard_client.get_project_columns(self.project_id)
        self.columns = {col['title']: int(col['id']) for col in columns}
        print(f"Available columns: {list(self.columns.keys())}")

        return True

    def map_sonar_issue_to_kanboard_task(self, issue: Dict, column_id: int, issue_type: str) -> Dict:
        """Map a SonarQube issue to a Kanboard task"""
        rule_name = issue.get('rule', 'Unknown Rule')
        severity = issue.get('severity', 'MINOR')
        component = issue.get('component', '').replace(f'{self.sonar_project_key}:', '')
        line = issue.get('line', 0)
        message = issue.get('message', '')
        issue_key = issue.get('key', '')

        category = self.type_mappings.get(issue_type, 'Unknown')

        title = f"[{category}] [{severity}] {message}"
        if len(title) > 255:
            title = title[:252] + "..."

        description_parts = [
            f"**SonarQube Issue Integration**",
            f"",
            f"**Category:** {category}",
            f"**Issue Key:** {issue_key}",
            f"**Rule:** {rule_name}",
            f"**Severity:** {severity}",
            f"**File:** {component}",
            f"**Message:** {message}"
        ]

        if line > 0:
            description_parts.append(f"**Line:** {line}")

        if issue.get('debt'):
            description_parts.append(f"**Technical Debt:** {issue['debt']}")

        if issue.get('tags'):
            description_parts.append(f"**Tags:** {', '.join(issue['tags'])}")

        description_parts.append(f"**Last Updated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

        description = '\n'.join(description_parts)

        color_map = {
            'VULNERABILITY': 'red',
            'BUG': 'orange',
            'CODE_SMELL': {
                'BLOCKER': 'red',
                'CRITICAL': 'red',
                'MAJOR': 'orange',
                'MINOR': 'yellow',
                'INFO': 'blue'
            }
        }

        if issue_type == 'CODE_SMELL':
            color = color_map['CODE_SMELL'].get(severity, 'blue')
        else:
            color = color_map.get(issue_type, 'blue')

        return {
            'project_id': self.project_id,
            'title': title,
            'description': description,
            'column_id': column_id,
            'color_id': color,
            'reference': f"sonar-{issue_key}"
        }

    def synchronize_issues(self, target_column: str = 'Ожидающие',
                           resolved_column: str = 'Выполнено') -> Dict:
        """Synchronize issues between SonarQube and Kanboard"""
        print(f"\n=== Starting synchronization at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} ===")

        # Get organized issues from SonarQube
        print("Fetching issues from SonarQube...")
        organized_issues = self.sonar_client.get_issues_by_type_and_resolution(self.sonar_project_key)

        # Get existing tasks from Kanboard
        print("Fetching tasks from Kanboard...")
        existing_tasks = self.kanboard_client.get_all_tasks(self.project_id)
        existing_refs = {task.get('reference', ''): task for task in existing_tasks}

        stats = {
            'created': 0,
            'updated': 0,
            'resolved': 0,
            'errors': 0
        }

        target_column_id = self.columns.get(target_column, list(self.columns.values())[0])
        resolved_column_id = self.columns.get(resolved_column, list(self.columns.values())[-1])

        print(f"Target column: {target_column} (ID: {target_column_id})")
        print(f"Resolved column: {resolved_column} (ID: {resolved_column_id})")

        # Process unresolved issues
        for issue_type, issues in organized_issues['unresolved'].items():
            if not issues:
                continue

            type_name = self.type_mappings[issue_type]
            print(f"\nProcessing {type_name} issues ({len(issues)} total)...")

            # Add progress tracking
            processed = 0
            total_issues = len(issues)
            
            for issue in issues:
                processed += 1
                if processed % 10 == 0 or processed == total_issues:
                    print(f"  Progress: {processed}/{total_issues} ({int(processed/total_issues*100)}%)")
                
                issue_key = issue.get('key', '')
                reference = f"sonar-{issue_key}"

                existing_task = existing_refs.get(reference)

                if existing_task:
                    # Update existing task
                    task_data = self.map_sonar_issue_to_kanboard_task(issue, target_column_id, issue_type)
                    if self.kanboard_client.update_task(existing_task['id'], {
                        'title': task_data['title'],
                        'description': task_data['description'],
                        'color_id': task_data['color_id']
                    }):
                        print(f"  ↳ ✓ Updated: {issue.get('message', 'Unknown')[:50]}...")
                        stats['updated'] += 1

                        # Move to target column if not already there
                        if int(existing_task['column_id']) != target_column_id:
                            self.kanboard_client.move_task_to_column(existing_task['id'], target_column_id)
                    else:
                        print(f"  ↳ ✗ Failed to update: {issue.get('message', 'Unknown')[:50]}...")
                        stats['errors'] += 1
                else:
                    # Create new task
                    task_data = self.map_sonar_issue_to_kanboard_task(issue, target_column_id, issue_type)
                    task_id = self.kanboard_client.create_task(task_data)

                    if task_id:
                        print(f"  ↳ ✓ Created: {issue.get('message', 'Unknown')[:50]}...")
                        stats['created'] += 1
                    else:
                        print(f"  ↳ ✗ Failed to create: {issue.get('message', 'Unknown')[:50]}...")
                        stats['errors'] += 1

        # Process resolved issues (move to resolved column)
        print("\nProcessing resolved issues...")
        resolved_refs = set()
        for issue_type, issues in organized_issues['resolved'].items():
            for issue in issues:
                issue_key = issue.get('key', '')
                reference = f"sonar-{issue_key}"
                resolved_refs.add(reference)

        resolved_count = 0
        to_resolve = [task for ref, task in existing_refs.items() 
                     if ref.startswith('sonar-') and ref in resolved_refs 
                     and int(task['column_id']) != resolved_column_id]
        
        total_to_resolve = len(to_resolve)
        print(f"Found {total_to_resolve} tasks to mark as resolved")
        
        for task in to_resolve:
            resolved_count += 1
            if resolved_count % 10 == 0 or resolved_count == total_to_resolve:
                print(f"  Progress: {resolved_count}/{total_to_resolve} ({int(resolved_count/total_to_resolve*100)}%)")
            
            if self.kanboard_client.move_task_to_column(task['id'], resolved_column_id):
                print(f"  ↳ ✓ Moved to resolved: {task.get('title', 'Unknown')[:50]}...")
                stats['resolved'] += 1

        return stats

    def run_continuous_sync(self, interval_minutes: int = 30,
                            target_column: str = 'Ожидающие',
                            resolved_column: str = 'Выполнено'):
        """Run continuous synchronization"""
        print(f"Starting continuous sync every {interval_minutes} minutes...")

        schedule.every(interval_minutes).minutes.do(
            self.synchronize_issues, target_column, resolved_column
        )

        # Run initial sync
        self.synchronize_issues(target_column, resolved_column)

        while True:
            schedule.run_pending()
            time.sleep(60)  # Check every minute

    def get_integration_status(self) -> Dict:
        """Get current integration status"""
        organized_issues = self.sonar_client.get_issues_by_type_and_resolution(self.sonar_project_key)
        existing_tasks = self.kanboard_client.get_all_tasks(self.project_id)

        sonar_refs = set()
        unresolved_count = 0
        resolved_count = 0
        issue_type_counts = {
            'CODE_SMELL': {'unresolved': 0, 'resolved': 0},
            'BUG': {'unresolved': 0, 'resolved': 0},
            'VULNERABILITY': {'unresolved': 0, 'resolved': 0}
        }
        
        for status in ['unresolved', 'resolved']:
            for issue_type, issues in organized_issues[status].items():
                for issue in issues:
                    sonar_refs.add(f"sonar-{issue.get('key', '')}")
                    if status == 'unresolved':
                        unresolved_count += 1
                        issue_type_counts[issue_type]['unresolved'] += 1
                    else:
                        resolved_count += 1
                        issue_type_counts[issue_type]['resolved'] += 1

        kanboard_refs = {task.get('reference', '') for task in existing_tasks if
                         task.get('reference', '').startswith('sonar-')}

        return {
            'sonar_issues_total': len(sonar_refs),
            'sonar_issues_unresolved': unresolved_count,
            'sonar_issues_resolved': resolved_count,
            'issue_type_counts': issue_type_counts,
            'kanboard_tasks': len(kanboard_refs),
            'synchronized': len(sonar_refs.intersection(kanboard_refs)),
            'missing_in_kanboard': len(sonar_refs - kanboard_refs),
            'orphaned_in_kanboard': len(kanboard_refs - sonar_refs)
        }


def main():
    # Configuration
    SONAR_URL = 'http://localhost:9000'
    SONAR_TOKEN = ''
    KANBOARD_URL = 'https://URL/jsonrpc.php'
    KANBOARD_TOKEN = ''
    PROJECT_ID = 1
    SONAR_PROJECT_KEY = '----'

    parser = argparse.ArgumentParser(description='SonarQube-Kanboard Integration')
    parser.add_argument('--mode', choices=['sync', 'continuous', 'status'],
                        default='sync', help='Integration mode')
    parser.add_argument('--target-column', default='Ожидающие',
                        help='Target column for open issues')
    parser.add_argument('--resolved-column', default='Выполнено',
                        help='Target column for resolved issues')
    parser.add_argument('--interval', type=int, default=30,
                        help='Sync interval in minutes for continuous mode')
    parser.add_argument('--dry-run', action='store_true',
                        help='Show what would be synchronized')

    args = parser.parse_args()

    # Initialize clients
    sonar_client = SonarQubeClient(SONAR_URL, SONAR_TOKEN)
    kanboard_client = KanboardClient(KANBOARD_URL, KANBOARD_TOKEN)

    # Initialize integration
    integration = SonarKanboardIntegration(
        sonar_client, kanboard_client, PROJECT_ID, SONAR_PROJECT_KEY
    )

    if not integration.initialize():
        sys.exit(1)

    # Run based on mode
    if args.mode == 'status':
        status = integration.get_integration_status()
        print(f"\n=== Integration Status ===")
        print(f"SonarQube issues: {status['sonar_issues_total']} total")
        print(f"  - Unresolved: {status['sonar_issues_unresolved']}")
        print(f"  - Resolved: {status['sonar_issues_resolved']}")
        
        print(f"\nIssue breakdown:")
        for issue_type, counts in status['issue_type_counts'].items():
            print(f"  {issue_type}: {counts['unresolved']} unresolved, {counts['resolved']} resolved")
        
        print(f"\nKanboard tasks: {status['kanboard_tasks']}")
        print(f"Synchronized: {status['synchronized']}")
        print(f"Missing in Kanboard: {status['missing_in_kanboard']}")
        print(f"Orphaned in Kanboard: {status['orphaned_in_kanboard']}")

    elif args.mode == 'sync':
        if args.dry_run:
            print("Dry run mode - no actual changes will be made")
            # Here you would add dry run logic
        else:
            stats = integration.synchronize_issues(args.target_column, args.resolved_column)
            print(f"\n=== Synchronization Results ===")
            print(f"Created: {stats['created']}")
            print(f"Updated: {stats['updated']}")
            print(f"Resolved: {stats['resolved']}")
            print(f"Errors: {stats['errors']}")

    elif args.mode == 'continuous':
        try:
            integration.run_continuous_sync(
                args.interval, args.target_column, args.resolved_column
            )
        except KeyboardInterrupt:
            print("\nStopping continuous sync...")


if __name__ == '__main__':
    main()
