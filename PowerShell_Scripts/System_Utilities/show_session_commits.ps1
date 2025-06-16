# Show Git Commit Log Since Session Start

# Script parameters
param (
    [switch]$ExportCsv,
    [switch]$ExportJson,
    [switch]$ShowDetails,
    [string]$OutputFolder = "$env:USERPROFILE\Documents\GitLogs"
)

# Create output folder if it doesn't exist
if (($ExportCsv -or $ExportJson) -and -not (Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
}

# Get timestamp for log files
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

# Helper function for formatted output
function Write-Header {
    param([string]$Text)
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor White
    Write-Host "===================================================" -ForegroundColor Cyan
}

# Show script header
Write-Header "Git Commit Log Since Session Start"
Write-Host ""

# Get the current system boot time
$bootUpTime = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -ExpandProperty LastBootUpTime
$sessionStartTime = $bootUpTime.ToString("yyyy-MM-dd HH:mm:ss")
$gitDateFormat = $bootUpTime.ToString("yyyy-MM-ddTHH:mm:ss")

Write-Host "Session Start Time: $sessionStartTime" -ForegroundColor Yellow
Write-Host ""

# Check if we're in a git repository
try {
    $null = git rev-parse --is-inside-work-tree
} catch {
    Write-Host "ERROR: Not in a git repository." -ForegroundColor Red
    Write-Host "Please run this script from within a git repository." -ForegroundColor Red
    Write-Host ""
    Write-Header "Script Ended"
    Read-Host "Press Enter to exit"
    exit
}

# Get repository information
$repoPath = git rev-parse --show-toplevel
$repoName = Split-Path -Leaf $repoPath
$currentBranch = git branch --show-current
$remoteName = git remote

# Get remote URL if available
$remoteUrl = ""
if ($remoteName) {
    $remoteUrl = git remote get-url $remoteName
}

# Show repository info
Write-Host "Repository: $repoName" -ForegroundColor Green
Write-Host "Branch: $currentBranch" -ForegroundColor Green
if ($remoteUrl) {
    Write-Host "Remote: $remoteUrl" -ForegroundColor Green
}
Write-Host ""

Write-Host "Commits since session start:" -ForegroundColor White
Write-Host "---------------------------------------------------" -ForegroundColor DarkGray

# Create an array to store commit info for export
$commitData = @()

# Get commits since boot time
# Add more details if ShowDetails is enabled
$format = "%h|%cr|%an|%s"
if ($ShowDetails) {
    $format = "%H|%h|%an|%ae|%at|%cr|%s|%b"
}

$commits = git log --since="$gitDateFormat" --pretty=format:$format --abbrev-commit --date=relative

if ($null -eq $commits -or $commits -eq "") {
    Write-Host "No commits found since session start." -ForegroundColor Yellow
} else {
    # Process and display commits
    $commitCount = 0
    $commits -split "`n" | ForEach-Object {
        $commitCount++
        $parts = $_ -split "\|"
        
        if ($ShowDetails) {
            if ($parts.Count -ge 7) {
                $fullHash = $parts[0]
                $shortHash = $parts[1]
                $author = $parts[2]
                $email = $parts[3]
                $timestamp = $parts[4]
                $timeAgo = $parts[5]
                $subject = $parts[6]
                $body = if ($parts.Count -gt 7) { $parts[7] } else { "" }
                
                # Format datetime from Unix timestamp
                $commitDate = (Get-Date "1970-01-01 00:00:00.000Z").AddSeconds($timestamp)
                
                # Add to export data
                $commitData += [PSCustomObject]@{
                    FullHash = $fullHash
                    ShortHash = $shortHash
                    Author = $author
                    Email = $email
                    DateTime = $commitDate
                    TimeAgo = $timeAgo
                    Subject = $subject
                    Body = $body
                }
                
                # Terminal output with colors
                Write-Host "$shortHash" -ForegroundColor Yellow -NoNewline
                Write-Host " - " -ForegroundColor White -NoNewline
                Write-Host "$timeAgo" -ForegroundColor Green -NoNewline
                Write-Host " - " -ForegroundColor White -NoNewline
                Write-Host "$author" -ForegroundColor Cyan -NoNewline
                Write-Host " <$email>" -ForegroundColor DarkCyan
                Write-Host "$subject" -ForegroundColor White
                
                # Show changed files
                $changedFiles = git show --pretty="" --name-status $fullHash
                if ($changedFiles) {
                    Write-Host "Files changed:" -ForegroundColor DarkGray
                    $changedFiles -split "`n" | ForEach-Object {
                        if ($_ -match "^([A-Z])\s+(.+)$") {
                            $changeType = $Matches[1]
                            $filename = $Matches[2]
                            
                            $color = switch($changeType) {
                                "A" { "Green" }     # Added
                                "M" { "Yellow" }    # Modified
                                "D" { "Red" }       # Deleted
                                "R" { "Magenta" }   # Renamed
                                default { "White" }
                            }
                            
                            $changeSymbol = switch($changeType) {
                                "A" { "+" }  # Added
                                "M" { "~" }  # Modified
                                "D" { "-" }  # Deleted
                                "R" { ">" }  # Renamed
                                default { " " }
                            }
                            
                            Write-Host "  $changeSymbol $filename" -ForegroundColor $color
                        }
                    }
                }
                
                if (-not [string]::IsNullOrWhiteSpace($body)) {
                    Write-Host "  Message: $body" -ForegroundColor DarkGray
                }
                Write-Host ""
            }
        } else {
            # Simple format (original)
            if ($parts.Count -ge 4) {
                $hash = $parts[0]
                $timeAgo = $parts[1]
                $author = $parts[2]
                $message = $parts[3]
                
                # Add to export data
                $commitData += [PSCustomObject]@{
                    Hash = $hash
                    TimeAgo = $timeAgo
                    Author = $author
                    Message = $message
                }
                
                # Terminal output with colors
                Write-Host "$hash" -ForegroundColor Yellow -NoNewline
                Write-Host " - " -ForegroundColor White -NoNewline
                Write-Host "$timeAgo" -ForegroundColor Green -NoNewline
                Write-Host " - " -ForegroundColor White -NoNewline
                Write-Host "$author" -ForegroundColor Cyan
                Write-Host "$message" -ForegroundColor White
                Write-Host ""
            }
        }
    }
    
    Write-Host "---------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "Total commits in this session: $commitCount" -ForegroundColor Magenta
    
    # Export the data if requested
    if ($ExportCsv -and $commitData.Count -gt 0) {
        $csvPath = Join-Path $OutputFolder "$repoName`_$currentBranch`_$timestamp.csv"
        $commitData | Export-Csv -Path $csvPath -NoTypeInformation
        Write-Host "CSV export saved to: $csvPath" -ForegroundColor Cyan
    }
    
    if ($ExportJson -and $commitData.Count -gt 0) {
        $jsonPath = Join-Path $OutputFolder "$repoName`_$currentBranch`_$timestamp.json"
        $commitData | ConvertTo-Json -Depth 4 | Out-File -FilePath $jsonPath
        Write-Host "JSON export saved to: $jsonPath" -ForegroundColor Cyan
    }
}

# Check for uncommitted changes
$status = git status --porcelain
if ($status) {
    $changedCount = ($status | Measure-Object).Count
    Write-Host ""
    Write-Host "Warning: You have $changedCount uncommitted changes" -ForegroundColor Yellow
    
    if ($ShowDetails) {
        Write-Host ""
        Write-Host "Uncommitted changes:" -ForegroundColor Yellow
        $status | ForEach-Object {
            if ($_ -match "^(.{2})\s+(.+)$") {
                $changeCode = $Matches[1].Trim()
                $filename = $Matches[2]
                
                $color = "White"
                $prefix = " "
                
                if ($changeCode -match "M") { $color = "Yellow"; $prefix = "~" }
                elseif ($changeCode -match "A") { $color = "Green"; $prefix = "+" }
                elseif ($changeCode -match "D") { $color = "Red"; $prefix = "-" }
                elseif ($changeCode -match "R") { $color = "Magenta"; $prefix = ">" }
                elseif ($changeCode -match "\?") { $color = "Gray"; $prefix = "?" }
                
                Write-Host "  $prefix $filename" -ForegroundColor $color
            }
        }
    }
}

Write-Host ""
Write-Header "Script Ended"
Write-Host ""
Write-Host "Options:" -ForegroundColor White
Write-Host "  -ExportCsv      Export commits to CSV file" -ForegroundColor Gray
Write-Host "  -ExportJson     Export commits to JSON file" -ForegroundColor Gray
Write-Host "  -ShowDetails    Show detailed commit information" -ForegroundColor Gray
Write-Host "  -OutputFolder   Specify folder for exports (default: Documents\GitLogs)" -ForegroundColor Gray
Write-Host ""
Write-Host "Example: .\show_session_commits.ps1 -ExportCsv -ShowDetails" -ForegroundColor Gray
Write-Host ""
Read-Host "Press Enter to exit" 
