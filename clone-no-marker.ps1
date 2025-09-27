# Clone repository without "generated from" marker
param(
    [Parameter(Mandatory=$true)]
    [string]$src,           # Source repository, format: owner/repo
    
    [Parameter(Mandatory=$true)]
    [string]$newName,       # New repository name
    
    [ValidateSet("public", "private")]
    [string]$visibility = "public",   # Repository visibility
    
    [switch]$bindLocal      # Switch to bind local directory with remote repository
)

Write-Host "Starting clone operation..."
Write-Host "Source repository: $src"
Write-Host "New repository name: $newName"
Write-Host "Visibility: $visibility"
if ($bindLocal) {
    Write-Host "Bind local directory: Yes"
} else {
    Write-Host "Bind local directory: No"
}

# Check if gh command is installed
if (!(Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error "GitHub CLI not installed. Please install gh command first."
    exit 1
}

# Check if logged in
$authStatus = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Not logged in to GitHub. Please run 'gh auth login' to log in."
    exit 1
}

# Extract username with more robust pattern matching
$username = $null
$usernameMatch = $authStatus | Select-String -Pattern 'Logged in to github\.com account ([^\s\(]+)'
if ($usernameMatch) {
    $username = $usernameMatch.Matches.Groups[1].Value
} else {
    # Try alternative pattern
    $usernameMatch = $authStatus | Select-String -Pattern 'Logged in to github\.com as ([^\s]+)'
    if ($usernameMatch) {
        $username = $usernameMatch.Matches.Groups[1].Value
    }
}

if ([string]::IsNullOrEmpty($username)) {
    Write-Error "Unable to extract GitHub username"
    exit 1
}

Write-Host "Current user: $username"

# Function to clean up temporary directories
function Cleanup-TempDirs {
    if (Test-Path "_tmp") {
        Write-Host "Cleaning up temporary directory..."
        Remove-Item -Recurse -Force "_tmp" -ErrorAction SilentlyContinue
    }
    if (Test-Path "..\_tmp") {
        Write-Host "Cleaning up temporary directory..."
        Remove-Item -Recurse -Force "..\_tmp" -ErrorAction SilentlyContinue
    }
}

# Clean up any existing temporary directory
Cleanup-TempDirs

if ($bindLocal) {
    # For local binding, we need to initialize a new git repo in current directory
    $currentDir = Get-Location
    Write-Host "Current directory: $currentDir"
    $repoDir = Join-Path $currentDir $newName
    Write-Host "Repository directory: $repoDir"
    
    # Check if directory already exists
    if (Test-Path $repoDir) {
        Write-Error "Directory $newName already exists in current location"
        exit 1
    }
    
    # Create new directory
    New-Item -ItemType Directory -Path $repoDir | Out-Null
    Set-Location $repoDir
    Write-Host "Changed to repository directory: $(Get-Location)"
    
    try {
        # Initialize git repository
        git init | Out-Null
        git checkout -b main 2>$null
        
        # Create new repository on GitHub
        Write-Host "Creating new repository $newName on GitHub..."
        gh repo create $newName --$visibility --description "Created from $src" --confirm
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to create repository. The repository name may already exist or you may not have permission to create it."
            exit 1
        }
        
        # Add remote origin
        $remoteUrl = "https://github.com/$username/$newName.git"
        git remote add origin $remoteUrl
        
        # Clone source repository (latest commit only) directly into current directory
        Write-Host "Cloning source repository $src (latest commit only)..."
        git clone --depth=1 --single-branch "https://github.com/$src.git" _temp_clone
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to clone repository"
            exit 1
        }
        
        # Copy files from temp clone to current directory, excluding .git
        if (Test-Path "_temp_clone") {
            Write-Host "Temp clone directory exists, copying files..."
            $files = Get-ChildItem "_temp_clone" -Force
            foreach ($file in $files) {
                if ($file.Name -ne ".git") {
                    Write-Host "Copying $($file.Name)..."
                    Copy-Item $file.FullName -Destination "." -Recurse -Force
                }
            }
            # Clean up temp clone
            Remove-Item -Recurse -Force "_temp_clone" -ErrorAction SilentlyContinue
        }
        
        # Check files in repository directory
        Write-Host "Files in repository directory after copy:"
        $repoFiles = Get-ChildItem "." -Force
        foreach ($file in $repoFiles) {
            Write-Host "  $($file.Name)"
        }
        
        # Add files and commit
        git add .
        # Check if there are files to commit
        $status = git status --porcelain
        if ($status) {
            Write-Host "Files to commit:"
            Write-Host $status
            git commit -m "Initial commit from $src"
            
            # Push to remote repository
            Write-Host "Pushing to new repository..."
            git push -u origin main
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Failed to push. You may need to check your network connection or GitHub permissions."
                exit 1
            }
            
            Write-Host "New repository created and local directory bound: https://github.com/$username/$newName"
        } else {
            Write-Host "No files to commit. Repository is empty."
            Write-Host "Local directory created and bound to remote repository: https://github.com/$username/$newName"
        }
    }
    finally {
        Set-Location $currentDir
        # Clean up temporary directory
        Cleanup-TempDirs
    }
} else {
    # Original behavior - clone to temporary directory
    try {
        # Clone source repository (latest commit only)
        Write-Host "Cloning source repository $src (latest commit only)..."
        gh repo clone $src _tmp -- --depth=1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to clone repository"
            exit 1
        }

        # Create new repository on GitHub
        Write-Host "Creating new repository $newName on GitHub..."
        gh repo create $newName --$visibility --description "Copied from $src" --confirm
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to create repository. The repository name may already exist or you may not have permission to create it."
            exit 1
        }

        # Push to new repository
        Write-Host "Pushing to new repository..."
        Push-Location _tmp
        try {
            # Remove original origin
            git remote remove origin
            
            # Add new origin
            $remoteUrl = "https://github.com/$username/$newName.git"
            git remote add origin $remoteUrl
            
            # Get default branch name
            $defaultBranch = git branch --show-current
            if ([string]::IsNullOrEmpty($defaultBranch)) {
                # If we can't get current branch, try to get the first branch
                $branches = git branch
                if ($branches -match '^\*?\s*(.+)$') {
                    $defaultBranch = $matches[1].Trim()
                }
            }
            
            if ([string]::IsNullOrEmpty($defaultBranch)) {
                $defaultBranch = "main"  # Default to main
            }
            
            # Create a new orphan branch with the latest files
            git checkout --orphan temp_branch
            git add .
            git commit -m "Initial commit from $src"
            
            # Rename the branch to the default branch name
            git branch -M $defaultBranch
            
            # Push and set upstream
            git push -u origin $defaultBranch --force
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Failed to push. You may need to check your network connection or GitHub permissions."
                exit 1
            }
            
            Write-Host "New repository created without 'generated from' marker: https://github.com/$username/$newName"
        }
        finally {
            Pop-Location
        }
    }
    finally {
        # Clean up temporary directory
        Cleanup-TempDirs
    }
}

Write-Host "Operation completed!"
