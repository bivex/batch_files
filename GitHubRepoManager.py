import requests
import json
from typing import List, Optional

class GitHubRepoManager:
    def __init__(self, token: str):
        """
        Initialize with your GitHub personal access token.
        Token needs 'repo' scope for private repos or 'public_repo' for public repos.
        """
        self.token = token
        self.headers = {
            'Authorization': f'token {token}',
            'Accept': 'application/vnd.github.v3+json',
            'Content-Type': 'application/json'
        }
        self.base_url = 'https://api.github.com'
    
    def update_repo_description(self, owner: str, repo: str, description: str) -> bool:
        """Update repository description"""
        url = f'{self.base_url}/repos/{owner}/{repo}'
        data = {'description': description}
        
        response = requests.patch(url, headers=self.headers, json=data)
        
        if response.status_code == 200:
            print(f"✅ Description updated for {owner}/{repo}")
            return True
        else:
            print(f"❌ Failed to update description for {owner}/{repo}: {response.status_code}")
            print(f"Error: {response.json()}")
            return False
    
    def update_repo_topics(self, owner: str, repo: str, topics: List[str]) -> bool:
        """Update repository topics (hashtags)"""
        url = f'{self.base_url}/repos/{owner}/{repo}/topics'
        data = {'names': topics}
        
        # Topics API requires different accept header
        headers = self.headers.copy()
        headers['Accept'] = 'application/vnd.github.mercy-preview+json'
        
        response = requests.put(url, headers=headers, json=data)
        
        if response.status_code == 200:
            print(f"✅ Topics updated for {owner}/{repo}")
            return True
        else:
            print(f"❌ Failed to update topics for {owner}/{repo}: {response.status_code}")
            print(f"Error: {response.json()}")
            return False
    
    def update_repo_full(self, owner: str, repo: str, description: str, topics: List[str]) -> bool:
        """Update both description and topics"""
        desc_success = self.update_repo_description(owner, repo, description)
        topics_success = self.update_repo_topics(owner, repo, topics)
        
        return desc_success and topics_success
    
    def get_repo_info(self, owner: str, repo: str) -> dict:
        """Get current repository information"""
        url = f'{self.base_url}/repos/{owner}/{repo}'
        response = requests.get(url, headers=self.headers)
        
        if response.status_code == 200:
            return response.json()
        else:
            print(f"❌ Failed to get repo info: {response.status_code}")
            return {}
    
    def get_repo_topics(self, owner: str, repo: str) -> List[str]:
        """Get current repository topics"""
        url = f'{self.base_url}/repos/{owner}/{repo}/topics'
        headers = self.headers.copy()
        headers['Accept'] = 'application/vnd.github.mercy-preview+json'
        
        response = requests.get(url, headers=headers)
        
        if response.status_code == 200:
            return response.json()['names']
        else:
            print(f"❌ Failed to get topics: {response.status_code}")
            return []

def main():
    # Configuration
    GITHUB_TOKEN = "your_github_token_here"  # Replace with your token
    
    # Initialize the manager
    github = GitHubRepoManager(GITHUB_TOKEN)
    
    # Example usage - replace with your repo details
    owner = "your-username"
    repo = "your-repo-name"
    
    # New description
    new_description = "A Python script for managing GitHub repository metadata"
    
    # New topics (hashtags)
    new_topics = ["python", "github", "automation", "api", "repository-management"]
    
    print(f"Updating {owner}/{repo}...")
    
    # Show current info
    print("\n📋 Current repository info:")
    current_info = github.get_repo_info(owner, repo)
    if current_info:
        print(f"Description: {current_info.get('description', 'No description')}")
        
    current_topics = github.get_repo_topics(owner, repo)
    print(f"Topics: {current_topics}")
    
    # Update both description and topics
    print(f"\n🔄 Updating repository...")
    success = github.update_repo_full(owner, repo, new_description, new_topics)
    
    if success:
        print(f"\n🎉 Repository updated successfully!")
    else:
        print(f"\n💥 Some updates failed!")

# Batch update multiple repositories
def batch_update_repos():
    GITHUB_TOKEN = "your_github_token_here"
    github = GitHubRepoManager(GITHUB_TOKEN)
    
    # List of repositories to update
    repos_to_update = [
        {
            "owner": "your-username",
            "repo": "repo1",
            "description": "Description for repo 1",
            "topics": ["python", "web", "api"]
        },
        {
            "owner": "your-username", 
            "repo": "repo2",
            "description": "Description for repo 2",
            "topics": ["javascript", "react", "frontend"]
        }
    ]
    
    for repo_data in repos_to_update:
        print(f"\n{'='*50}")
        print(f"Updating {repo_data['owner']}/{repo_data['repo']}")
        print(f"{'='*50}")
        
        github.update_repo_full(
            repo_data['owner'],
            repo_data['repo'],
            repo_data['description'],
            repo_data['topics']
        )

if __name__ == "__main__":
    main()
    # Uncomment the line below for batch updates
    # batch_update_repos()
