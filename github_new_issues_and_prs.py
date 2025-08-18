import requests
import json
from datetime import datetime, timedelta, timezone
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass
import time

@dataclass
class IssueOrPR:
    repo_name: str
    type: str  # 'issue' or 'pull_request'
    number: int
    title: str
    state: str
    author: str
    created_at: datetime
    updated_at: datetime
    url: str
    labels: List[str]
    is_draft: Optional[bool] = None  # Only for PRs
    comments_count: int = 0

class GitHubNotificationScanner:
    def __init__(self, token: str):
        self.token = token
        self.headers = {
            'Authorization': f'token {token}',
            'Accept': 'application/vnd.github.v3+json',
            'Content-Type': 'application/json'
        }
        self.base_url = 'https://api.github.com'
    
    def parse_github_datetime(self, date_str: str) -> datetime:
        """Safe datetime parsing from GitHub API"""
        try:
            # GitHub returns time in ISO 8601 format with Z at the end
            if date_str.endswith('Z'):
                date_str = date_str[:-1] + '+00:00'
            
            # Parse with timezone
            dt = datetime.fromisoformat(date_str)
            
            # If no timezone info, add UTC
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=timezone.utc)
            
            return dt
        except Exception as e:
            print(f"⚠️ Error parsing date '{date_str}': {e}")
            # Return current time with UTC timezone as fallback
            return datetime.now(timezone.utc)
    
    def get_utc_datetime(self, days_back: int = 0) -> datetime:
        """Get UTC datetime accounting for days back"""
        return datetime.now(timezone.utc) - timedelta(days=days_back)
    
    def get_authenticated_user(self) -> Optional[str]:
        """Get current user name"""
        url = f'{self.base_url}/user'
        response = requests.get(url, headers=self.headers)
        
        if response.status_code == 200:
            user_data = response.json()
            return user_data.get('login')
        return None
    
    def get_my_repos(self, include_forks: bool = False) -> List[Tuple[str, str, Dict]]:
        """Get all user repositories"""
        url = f'{self.base_url}/user/repos'
        params = {
            'type': 'all',
            'per_page': 100,
            'sort': 'updated',
            'direction': 'desc'
        }
        
        all_repos = []
        page = 1
        
        print(f"🔍 Getting list of your repositories...")
        
        while True:
            params['page'] = page
            response = requests.get(url, headers=self.headers, params=params)
            
            if response.status_code != 200:
                print(f"❌ Error getting repositories: {response.status_code}")
                break
            
            repos = response.json()
            if not repos:
                break
            
            for repo in repos:
                # Filter forks if needed
                if not include_forks and repo.get('fork', False):
                    continue
                
                all_repos.append((repo['owner']['login'], repo['name'], repo))
            
            print(f"📄 Processed page {page}, found {len(repos)} repositories")
            page += 1
            
            if page > 100:  # Protection against infinite loop
                break
        
        print(f"✅ Total found {len(all_repos)} repositories")
        return all_repos
    
    def get_repo_issues(self, owner: str, repo: str, since: datetime = None, 
                       include_prs: bool = True) -> List[IssueOrPR]:
        """Get issues and PRs for repository"""
        url = f'{self.base_url}/repos/{owner}/{repo}/issues'
        
        params = {
            'state': 'all',  # open, closed, all
            'sort': 'updated',
            'direction': 'desc',
            'per_page': 100
        }
        
        if since:
            # Ensure since has timezone info
            if since.tzinfo is None:
                since = since.replace(tzinfo=timezone.utc)
            params['since'] = since.isoformat()
        
        all_items = []
        page = 1
        
        while True:
            params['page'] = page
            response = requests.get(url, headers=self.headers, params=params)
            
            if response.status_code != 200:
                if response.status_code == 403:
                    print(f"⚠️ Access denied for {owner}/{repo} (possibly private repository)")
                elif response.status_code == 404:
                    print(f"⚠️ Repository {owner}/{repo} not found")
                else:
                    print(f"⚠️ Error getting issues for {owner}/{repo}: {response.status_code}")
                break
            
            items = response.json()
            if not items:
                break
            
            for item in items:
                try:
                    # GitHub API returns both issues and PRs in /issues endpoint
                    is_pr = 'pull_request' in item
                    
                    if not include_prs and is_pr:
                        continue
                    
                    # Safe date parsing
                    created_at = self.parse_github_datetime(item['created_at'])
                    updated_at = self.parse_github_datetime(item['updated_at'])
                    
                    # If time filter is set, check created_at
                    if since and created_at < since:
                        continue
                    
                    issue_or_pr = IssueOrPR(
                        repo_name=f"{owner}/{repo}",
                        type='pull_request' if is_pr else 'issue',
                        number=item['number'],
                        title=item['title'],
                        state=item['state'],
                        author=item['user']['login'] if item['user'] else 'unknown',
                        created_at=created_at,
                        updated_at=updated_at,
                        url=item['html_url'],
                        labels=[label['name'] for label in item.get('labels', [])],
                        comments_count=item.get('comments', 0),
                        is_draft=item.get('draft') if is_pr else None
                    )
                    
                    all_items.append(issue_or_pr)
                    
                except Exception as e:
                    print(f"⚠️ Error processing item in {owner}/{repo}: {e}")
                    continue
            
            page += 1
            
            # If we got fewer items than requested, this is the last page
            if len(items) < params['per_page']:
                break
                
            if page > 50:  # Protection against too many requests
                break
        
        return all_items
    
    def print_repo_items_inline(self, repo_name: str, items: List[IssueOrPR]):
        """Print issue and PR titles inline with repository"""
        if not items:
            return
        
        issues = [item for item in items if item.type == 'issue']
        prs = [item for item in items if item.type == 'pull_request']
        
        # Form string with titles
        titles = []
        
        if issues:
            for issue in issues:
                state_icon = "🟢" if issue.state == 'open' else "🔴"
                titles.append(f"📋{state_icon}#{issue.number}: {issue.title}")
        
        if prs:
            for pr in prs:
                state_icon = "🟢" if pr.state == 'open' else "🔴"
                draft_mark = "📝" if pr.is_draft else ""
                titles.append(f"🔀{state_icon}{draft_mark}#{pr.number}: {pr.title}")
        
        # Output in one line or multiple lines if many
        if len(titles) == 1:
            print(f"   📋 Found: {titles[0]}")
        else:
            print(f"   📋 Found {len(issues)} issues, {len(prs)} PRs:")
            for title in titles:
                print(f"      {title}")
    
    def scan_all_repos(self, days_back: int = 7, include_forks: bool = False,
                      only_new_activity: bool = True, include_own: bool = False) -> Dict[str, List[IssueOrPR]]:
        """Scan all repositories for new issues/PRs"""
        
        # Get current user
        current_user = self.get_authenticated_user()
        if not current_user:
            print("❌ Failed to get user information")
            return {}
        
        # Calculate date "from when to search" with UTC timezone
        since_date = self.get_utc_datetime(days_back)
        
        # Get repositories
        repos = self.get_my_repos(include_forks=include_forks)
        
        print(f"\n🔍 Scanning {len(repos)} repositories for activity in the last {days_back} days")
        print(f"📅 Looking for activity since: {since_date.strftime('%Y-%m-%d %H:%M:%S UTC')}")
        print("=" * 80)
        
        all_findings = {}
        total_issues = 0
        total_prs = 0
        
        for i, (owner, repo, repo_data) in enumerate(repos, 1):
            repo_full_name = f"{owner}/{repo}"
            print(f"\n[{i}/{len(repos)}] Scanning {repo_full_name}...")
            
            # Delay to avoid rate limiting
            if i > 1:
                time.sleep(0.5)
            
            try:
                items = self.get_repo_issues(
                    owner, repo, 
                    since=since_date if only_new_activity else None,
                    include_prs=True
                )
                
                # Filtering
                filtered_items = []
                for item in items:
                    # Exclude own issues/PRs if include_own=False
                    if not include_own and item.author == current_user:
                        continue
                    
                    # If only_new_activity=True, show only new or recently updated
                    if only_new_activity:
                        # Ensure all datetime objects have timezone info for comparison
                        item_created = item.created_at
                        item_updated = item.updated_at
                        
                        if item_created.tzinfo is None:
                            item_created = item_created.replace(tzinfo=timezone.utc)
                        if item_updated.tzinfo is None:
                            item_updated = item_updated.replace(tzinfo=timezone.utc)
                        
                        if item_created >= since_date or item_updated >= since_date:
                            filtered_items.append(item)
                    else:
                        filtered_items.append(item)
                
                if filtered_items:
                    all_findings[repo_full_name] = filtered_items
                    
                    issues = [item for item in filtered_items if item.type == 'issue']
                    prs = [item for item in filtered_items if item.type == 'pull_request']
                    
                    total_issues += len(issues)
                    total_prs += len(prs)
                    
                    # Output details of what was found
                    self.print_repo_items_inline(repo_full_name, filtered_items)
                else:
                    print(f"   ✅ No new activity")
                    
            except Exception as e:
                print(f"   ❌ Error: {e}")
                continue
        
        print(f"\n{'='*80}")
        print(f"📊 TOTAL: {total_issues} issues, {total_prs} PRs in {len(all_findings)} repositories")
        
        return all_findings
    
    def print_detailed_report(self, findings: Dict[str, List[IssueOrPR]], 
                            group_by_type: bool = True):
        """Detailed report of found issues/PRs"""
        
        if not findings:
            print("\n🎉 No new activity found!")
            return
        
        print(f"\n{'='*80}")
        print("📋 DETAILED REPORT")
        print(f"{'='*80}")
        
        for repo_name, items in findings.items():
            print(f"\n🔗 {repo_name}")
            print("-" * len(repo_name))
            
            if group_by_type:
                issues = [item for item in items if item.type == 'issue']
                prs = [item for item in items if item.type == 'pull_request']
                
                if issues:
                    print(f"\n  📋 Issues ({len(issues)}):")
                    for issue in sorted(issues, key=lambda x: x.created_at, reverse=True):
                        self._print_item(issue, "    ")
                
                if prs:
                    print(f"\n  🔀 Pull Requests ({len(prs)}):")
                    for pr in sorted(prs, key=lambda x: x.created_at, reverse=True):
                        self._print_item(pr, "    ")
            else:
                # Sort by creation time
                sorted_items = sorted(items, key=lambda x: x.created_at, reverse=True)
                for item in sorted_items:
                    self._print_item(item, "  ")
    
    def _print_item(self, item: IssueOrPR, indent: str = ""):
        """Print information about individual issue/PR"""
        icon = "🔀" if item.type == 'pull_request' else "📋"
        state_icon = "🟢" if item.state == 'open' else "🔴"
        
        # Time with timezone consideration
        try:
            created_local = item.created_at.strftime('%m/%d %H:%M')
            time_info = f"created {created_local}"
            
            # Check difference between created_at and updated_at
            time_diff = abs((item.updated_at - item.created_at).total_seconds())
            if time_diff > 60:  # More than a minute difference
                updated_local = item.updated_at.strftime('%m/%d %H:%M')
                time_info += f", updated {updated_local}"
        except Exception:
            time_info = "time unknown"
        
        # Main information
        print(f"{indent}{icon} {state_icon} #{item.number} {item.title}")
        print(f"{indent}   👤 {item.author} | {time_info}")
        
        # Additional information
        extras = []
        if item.comments_count > 0:
            extras.append(f"💬 {item.comments_count}")
        if item.labels:
            extras.append(f"🏷️ {', '.join(item.labels[:3])}")
        if item.is_draft:
            extras.append("📝 Draft")
        
        if extras:
            print(f"{indent}   {' | '.join(extras)}")
        
        print(f"{indent}   🔗 {item.url}")
    
    def save_report(self, findings: Dict[str, List[IssueOrPR]], filename: str = None):
        """Save report to JSON file"""
        if not filename:
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            filename = f"github_activity_report_{timestamp}.json"
        
        # Convert to serializable format
        serializable_data = {}
        
        for repo_name, items in findings.items():
            serializable_data[repo_name] = []
            for item in items:
                try:
                    serializable_data[repo_name].append({
                        'type': item.type,
                        'number': item.number,
                        'title': item.title,
                        'state': item.state,
                        'author': item.author,
                        'created_at': item.created_at.isoformat(),
                        'updated_at': item.updated_at.isoformat(),
                        'url': item.url,
                        'labels': item.labels,
                        'comments_count': item.comments_count,
                        'is_draft': item.is_draft
                    })
                except Exception as e:
                    print(f"⚠️ Error serializing data for {repo_name}: {e}")
                    continue
        
        report_data = {
            'scan_timestamp': datetime.now(timezone.utc).isoformat(),
            'total_repos': len(findings),
            'total_items': sum(len(items) for items in findings.values()),
            'findings': serializable_data
        }
        
        try:
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump(report_data, f, ensure_ascii=False, indent=2)
            
            print(f"\n💾 Report saved to {filename}")
        except Exception as e:
            print(f"\n❌ Error saving report: {e}")
    
    def interactive_scan(self):
        """Interactive scanning"""
        print("🔍 Interactive GitHub Activity Scanning")
        print("=" * 50)
        
        # Authentication check
        username = self.get_authenticated_user()
        if not username:
            print("❌ Authentication error. Check your token.")
            return
        
        print(f"👤 User: {username}")
        
        # Scan settings
        try:
            days_back = int(input("\nHow many days back to search for activity? [7]: ") or "7")
        except ValueError:
            days_back = 7
        
        include_forks = input("Include forks? (y/n) [n]: ").strip().lower() in ['y', 'yes']
        include_own = input("Include your own issues/PRs? (y/n) [n]: ").strip().lower() in ['y', 'yes']
        only_new = input("Only new activity (created/updated)? (y/n) [y]: ").strip().lower() not in ['n', 'no']
        
        print(f"\n🚀 Starting scan...")
        print(f"   📅 Period: {days_back} days ago")
        print(f"   🍴 Forks: {'Yes' if include_forks else 'No'}")
        print(f"   👤 Own: {'Yes' if include_own else 'No'}")
        print(f"   🆕 Only new: {'Yes' if only_new else 'No'}")
        
        # Scanning
        findings = self.scan_all_repos(
            days_back=days_back,
            include_forks=include_forks,
            only_new_activity=only_new,
            include_own=include_own
        )
        
        # Report
        self.print_detailed_report(findings)
        
        # Save
        if findings:
            save_report = input("\n💾 Save report to file? (y/n): ").strip().lower()
            if save_report in ['y', 'yes']:
                self.save_report(findings)

def main():
    """Main function"""
    GITHUB_TOKEN = "your_github_token_here"  # Replace with your token
    
    if GITHUB_TOKEN == "your_github_token_here":
        print("❌ Set your GitHub token in GITHUB_TOKEN variable")
        return
    
    scanner = GitHubNotificationScanner(GITHUB_TOKEN)
    
    print("🔍 GitHub Activity Scanner v2.0")
    print("=" * 50)
    
    # Authentication check
    username = scanner.get_authenticated_user()
    if not username:
        print("❌ Authentication error. Check your token.")
        return
    
    print(f"👤 Welcome, {username}!")
    
    # Mode selection
    print("\nChoose mode:")
    print("1. Interactive scanning")
    print("2. Quick scan (3 days, exclude own)")
    print("3. Full scan (7 days, everything)")
    
    choice = input("\nYour choice (1-3): ").strip()
    
    if choice == "1":
        scanner.interactive_scan()
    elif choice == "2":
        findings = scanner.scan_all_repos(
            days_back=3,
            include_forks=False,
            only_new_activity=True,
            include_own=False
        )
        scanner.print_detailed_report(findings)
        if findings:
            scanner.save_report(findings)
    elif choice == "3":
        findings = scanner.scan_all_repos(
            days_back=7,
            include_forks=True,
            only_new_activity=True,
            include_own=True
        )
        scanner.print_detailed_report(findings)
        if findings:
            scanner.save_report(findings)
    else:
        print("❌ Invalid choice")

if __name__ == "__main__":
    main()
