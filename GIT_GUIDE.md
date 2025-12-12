# Git Setup and Workflow Guide

## 🚀 Quick Setup

### Automated Setup (Recommended)
```bash
./git-setup.sh
```

This script will:
1. Initialize git repository
2. Configure git user (if needed)
3. Add GitHub remote
4. Stage all files
5. Create initial commit
6. Push to GitHub (optional)

### Manual Setup
```bash
# Initialize repository
git init -b main

# Configure git user (if needed)
git config user.name "Your Name"
git config user.email "your.email@example.com"

# Add remote
git remote add origin https://github.com/Paul-PADataAnalytics/expeditiousreader.git

# Stage files
git add .

# Commit
git commit -m "Initial commit"

# Push
git push -u origin main
```

## 📁 What Gets Committed

### ✅ Included in Repository
- Source code (`lib/`, `web/`, `android/`, etc.)
- Configuration files (`pubspec.yaml`, `analysis_options.yaml`)
- Build scripts (`build_all.sh`, `docker-build.sh`, etc.)
- Docker configuration (`Dockerfile`, `docker-compose.yml`, `docker/`)
- Documentation (all `.md` files)
- Assets (`assets/` folder)
- Tests (`test/` folder)

### ❌ Excluded from Repository (via .gitignore)
- Build outputs (`build/`, `releases/`)
- Platform-specific builds (`*.apk`, `*.aab`, `*.exe`, etc.)
- IDE files (`.idea/`, `*.iml`)
- Temporary files (`*.tmp`, `*.log`, `*.bak`)
- Dependencies (`.dart_tool/`, `.flutter-plugins-dependencies`)
- Local configuration (`.env.local`, `docker-compose.override.yml`)

## 🔄 Daily Git Workflow

### Making Changes
```bash
# 1. Check current status
git status

# 2. Create a new branch for your feature
git checkout -b feature/your-feature-name

# 3. Make your changes to files

# 4. Stage changes
git add .
# Or stage specific files
git add lib/services/library_service.dart

# 5. Commit with descriptive message
git commit -m "Add feature: description of what you did"

# 6. Push to GitHub
git push -u origin feature/your-feature-name
```

### Updating from Remote
```bash
# Pull latest changes
git pull

# Or fetch and merge
git fetch
git merge origin/main
```

### Switching Branches
```bash
# List branches
git branch -a

# Switch to existing branch
git checkout main

# Create and switch to new branch
git checkout -b feature/new-feature
```

## 📝 Commit Message Guidelines

### Good Commit Messages
```bash
git commit -m "Fix: Resolve QuotaExceededError in web storage"
git commit -m "Feature: Add Docker deployment support"
git commit -m "Docs: Update build scripts documentation"
git commit -m "Refactor: Improve library service error handling"
```

### Commit Message Format
```
Type: Brief description (50 chars or less)

Detailed explanation if needed (wrapped at 72 chars):
- What was changed
- Why it was changed
- Any side effects or notes

Fixes #issue-number (if applicable)
```

### Commit Types
- `Feature:` New functionality
- `Fix:` Bug fixes
- `Docs:` Documentation changes
- `Refactor:` Code restructuring
- `Test:` Adding or updating tests
- `Chore:` Maintenance tasks
- `Style:` Formatting changes
- `Perf:` Performance improvements

## 🌿 Branch Strategy

### Main Branches
- `main` - Production-ready code
- `develop` - Development branch (optional)

### Feature Branches
```bash
# Create feature branch
git checkout -b feature/speed-reading-improvements

# Work on feature
# ... make changes ...

# Commit changes
git add .
git commit -m "Feature: Improve speed reading algorithm"

# Push feature branch
git push -u origin feature/speed-reading-improvements

# Create Pull Request on GitHub
# Merge via GitHub UI after review
```

### Hotfix Branches
```bash
# For urgent fixes
git checkout -b hotfix/critical-bug-fix

# Make fix
# ... fix the bug ...

# Commit and push
git add .
git commit -m "Fix: Critical bug in book import"
git push -u origin hotfix/critical-bug-fix
```

## 🔍 Useful Git Commands

### Status and Information
```bash
# Check status
git status

# View commit history
git log --oneline
git log --graph --oneline --all

# View changes
git diff
git diff --staged

# View remote info
git remote -v

# View branch info
git branch -a
```

### Undoing Changes
```bash
# Discard changes in working directory
git checkout -- file.txt

# Unstage files
git reset HEAD file.txt

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1

# Amend last commit message
git commit --amend -m "New commit message"
```

### Stashing Changes
```bash
# Save changes temporarily
git stash

# List stashes
git stash list

# Apply stashed changes
git stash pop

# Apply specific stash
git stash apply stash@{0}

# Clear stashes
git stash clear
```

## 🔐 Authentication

### HTTPS (Personal Access Token)
```bash
# Generate token at: https://github.com/settings/tokens

# When prompted for password, use the token
git push
Username: Paul-PADataAnalytics
Password: <paste-your-token-here>
```

### SSH (Recommended)
```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your.email@example.com"

# Add key to ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Add public key to GitHub
cat ~/.ssh/id_ed25519.pub
# Copy and add at: https://github.com/settings/keys

# Change remote to SSH
git remote set-url origin git@github.com:Paul-PADataAnalytics/expeditiousreader.git
```

## 🏷️ Tagging Releases

### Creating Tags
```bash
# Create lightweight tag
git tag v1.0.0

# Create annotated tag (recommended)
git tag -a v1.0.0 -m "Release version 1.0.0"

# Tag specific commit
git tag -a v1.0.0 abc1234 -m "Release version 1.0.0"

# Push tags
git push origin v1.0.0
# Or push all tags
git push --tags
```

### Semantic Versioning
- `v1.0.0` - Major.Minor.Patch
- `v1.0.0-beta` - Pre-release
- `v1.0.0-rc.1` - Release candidate

## 🔄 Syncing with Remote

### Keep Your Fork Updated
```bash
# Add upstream remote (if forked)
git remote add upstream https://github.com/original/repo.git

# Fetch upstream changes
git fetch upstream

# Merge upstream changes
git checkout main
git merge upstream/main

# Push to your fork
git push origin main
```

### Resolving Merge Conflicts
```bash
# When conflicts occur
git status  # See conflicting files

# Edit files to resolve conflicts
# Look for <<<<<<< HEAD markers

# After resolving
git add .
git commit -m "Resolve merge conflicts"
git push
```

## 📊 GitHub Integration

### Creating Pull Requests
1. Push your feature branch
2. Go to GitHub repository
3. Click "Compare & pull request"
4. Add description
5. Request review
6. Address feedback
7. Merge when approved

### GitHub Actions (CI/CD)
Create `.github/workflows/build.yml`:
```yaml
name: Build and Test

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test
      - run: flutter build web --release
```

## 🛡️ Best Practices

### Do's
- ✅ Commit often with meaningful messages
- ✅ Pull before starting work
- ✅ Use branches for features
- ✅ Review changes before committing
- ✅ Keep commits focused and atomic
- ✅ Write descriptive commit messages
- ✅ Tag releases

### Don'ts
- ❌ Commit build outputs
- ❌ Commit sensitive information
- ❌ Commit large binary files
- ❌ Force push to main/shared branches
- ❌ Commit without testing
- ❌ Use vague commit messages

## 🔧 Configuration

### Global Git Config
```bash
# Set user info
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Set default branch name
git config --global init.defaultBranch main

# Set default editor
git config --global core.editor "code --wait"

# Enable color
git config --global color.ui auto

# Set up aliases
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.cm commit
git config --global alias.lg "log --oneline --graph --all"
```

### Project-Specific Config
```bash
# Set for this project only (run in project directory)
git config user.name "Project Name"
git config user.email "project@example.com"
```

## 📚 Additional Resources

- [Git Documentation](https://git-scm.com/doc)
- [GitHub Guides](https://guides.github.com/)
- [Git Cheat Sheet](https://education.github.com/git-cheat-sheet-education.pdf)
- [Pro Git Book](https://git-scm.com/book/en/v2)

## 🆘 Troubleshooting

### "Permission denied (publickey)"
```bash
# Check SSH connection
ssh -T git@github.com

# If fails, check SSH key
ls -al ~/.ssh

# Generate new key if needed
ssh-keygen -t ed25519 -C "your.email@example.com"
```

### "fatal: refusing to merge unrelated histories"
```bash
# Allow merging unrelated histories
git pull origin main --allow-unrelated-histories
```

### "Your branch is ahead of 'origin/main'"
```bash
# Push your commits
git push
```

### "Your branch is behind 'origin/main'"
```bash
# Pull latest changes
git pull
```

### Accidentally committed to main
```bash
# Create new branch with current changes
git branch feature/my-changes

# Reset main to match remote
git checkout main
git reset --hard origin/main

# Continue work on feature branch
git checkout feature/my-changes
```

## ✅ Verification Checklist

After setup, verify:
- [ ] Repository initialized: `git status`
- [ ] Remote configured: `git remote -v`
- [ ] User configured: `git config user.name`
- [ ] Initial commit created: `git log`
- [ ] Pushed to GitHub: Visit repository URL
- [ ] .gitignore working: Build files not tracked

---

**Quick Commands:**
```bash
# Setup
./git-setup.sh

# Daily workflow
git status
git add .
git commit -m "message"
git push

# Branch workflow
git checkout -b feature/name
# ... make changes ...
git push -u origin feature/name
```

**Need help?** See the troubleshooting section or visit [Git Documentation](https://git-scm.com/doc)
