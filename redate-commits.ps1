# PowerShell script for backdated commits (10 months to 1 year ago)
# This will create commits between March 2024 to January 2025

$ErrorActionPreference = "Stop"

# Calculate dates (10-12 months ago from today)
$today = Get-Date
$START_DATE = $today.AddMonths(-12)  # 1 year ago
$END_DATE = $today.AddMonths(-10)    # 10 months ago

$TARGET_COMMITS = 30
$MIN_DAYS_BETWEEN = 2  # Minimum days between commits

Write-Host "Starting commit generation..." -ForegroundColor Green
Write-Host "Creating exactly $TARGET_COMMITS commits from $($START_DATE.ToString('yyyy-MM-dd')) to $($END_DATE.ToString('yyyy-MM-dd'))"
Write-Host ""

# Calculate total days and interval between commits
$totalDays = ($END_DATE - $START_DATE).TotalDays
$daysBetweenCommits = $totalDays / $TARGET_COMMITS

Write-Host "Total period: $([int]$totalDays) days"
Write-Host "Average days between commits: $([int]$daysBetweenCommits)"
Write-Host ""

# Reset to before all commits
Write-Host "Resetting repository to clean state..." -ForegroundColor Yellow
git checkout --orphan temp_branch
git add .
$env:GIT_AUTHOR_DATE = $START_DATE.AddHours(10).ToString("yyyy-MM-dd HH:mm:ss")
$env:GIT_COMMITTER_DATE = $START_DATE.AddHours(10).ToString("yyyy-MM-dd HH:mm:ss")
git commit -m "Initial commit: Project setup" --quiet
Remove-Item Env:\GIT_AUTHOR_DATE
Remove-Item Env:\GIT_COMMITTER_DATE

git branch -D main
git branch -m main

Write-Host "Commit 1/30 - $($START_DATE.ToString('yyyy-MM-dd'))" -ForegroundColor Green

# Track last commit date
$lastCommitDate = $START_DATE

# Commit messages for variety
$messages = @(
    "Update: {0}",
    "Improvements and bug fixes",
    "Feature enhancements",
    "Code refactoring",
    "Performance optimizations",
    "UI/UX improvements",
    "Documentation updates",
    "Minor fixes",
    "Update dependencies",
    "Clean up code"
)

# Generate remaining commits
for ($i = 1; $i -lt $TARGET_COMMITS; $i++) {
    # Calculate minimum next date
    $minNextDate = $lastCommitDate.AddDays($MIN_DAYS_BETWEEN)
    
    # Calculate target date based on even distribution
    $targetDate = $START_DATE.AddDays($daysBetweenCommits * $i)
    
    # Use whichever is later
    if ($minNextDate -gt $targetDate) {
        $commitDate = $minNextDate
    } else {
        $commitDate = $targetDate
    }
    
    # Add small random variance (±2 days)
    $variance = Get-Random -Minimum -2 -Maximum 2
    $commitDate = $commitDate.AddDays($variance)
    
    # Ensure we don't exceed end date
    if ($commitDate -gt $END_DATE) {
        $commitDate = $END_DATE
    }
    
    # Ensure it's after the last commit
    if ($commitDate -le $lastCommitDate) {
        $commitDate = $lastCommitDate.AddDays($MIN_DAYS_BETWEEN)
    }
    
    # Skip weekends for more natural pattern
    while ($commitDate.DayOfWeek -eq 'Saturday' -or $commitDate.DayOfWeek -eq 'Sunday') {
        $commitDate = $commitDate.AddDays(1)
    }
    
    # Update last commit date
    $lastCommitDate = $commitDate
    
    # Random time during working hours (9am-6pm)
    $randomHour = Get-Random -Minimum 9 -Maximum 19
    $randomMinute = Get-Random -Minimum 0 -Maximum 60
    $commitDateTime = $commitDate.Date.AddHours($randomHour).AddMinutes($randomMinute)
    
    # Create a small change
    $logEntry = "Commit $($i + 1) at $($commitDateTime.ToString('yyyy-MM-dd HH:mm:ss'))"
    Add-Content -Path ".commit-log.txt" -Value $logEntry
    
    # Stage and commit with backdated timestamp
    git add .commit-log.txt
    
    # Select random message
    $messageIndex = Get-Random -Minimum 0 -Maximum $messages.Length
    $commitMessage = $messages[$messageIndex]
    if ($commitMessage -like "*{0}*") {
        $commitMessage = $commitMessage -f $commitDateTime.ToString("MMM dd, yyyy")
    }
    
    $dateString = $commitDateTime.ToString("yyyy-MM-dd HH:mm:ss")
    $env:GIT_AUTHOR_DATE = $dateString
    $env:GIT_COMMITTER_DATE = $dateString
    git commit -m $commitMessage --quiet
    Remove-Item Env:\GIT_AUTHOR_DATE
    Remove-Item Env:\GIT_COMMITTER_DATE
    
    # Progress indicator
    if (($i % 5) -eq 0) {
        Write-Host "Created $($i + 1)/30 commits..." -ForegroundColor Cyan
    }
}

Write-Host ""
Write-Host "✅ All 30 commits created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Date range:" -ForegroundColor Yellow
git log --pretty=format:'%ad' --date=short | Select-Object -First 1 -Last 1
Write-Host ""
Write-Host ""
Write-Host "To push to GitHub:" -ForegroundColor Yellow
Write-Host "  Run: git push -u origin main --force"
Write-Host ""
Write-Host "Note: Use --force since we rewrote history" -ForegroundColor Red
