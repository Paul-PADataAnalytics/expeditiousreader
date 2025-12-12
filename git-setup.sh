#!/bin/zsh

# Git Repository Setup Script
# Sets up the project for GitHub at https://github.com/Paul-PADataAnalytics/expeditiousreader.git

set -e  # Exit on error

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

REPO_URL="https://github.com/Paul-PADataAnalytics/expeditiousreader.git"
BRANCH="main"

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   Git Repository Setup - Expeditious Reader${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${RED}✗ Git is not installed${NC}"
    echo "Please install git: sudo apt-get install git"
    exit 1
fi
echo -e "${GREEN}✓ Git is installed${NC}"

# Check if already a git repository
if [ -d .git ]; then
    echo -e "${YELLOW}⚠ Git repository already exists${NC}"
    echo -e "${YELLOW}Current remote:${NC}"
    git remote -v
    echo ""
    read -p "Do you want to continue and reset the repository? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Aborted${NC}"
        exit 0
    fi
    rm -rf .git
    echo -e "${GREEN}✓ Removed existing .git directory${NC}"
fi

# Initialize git repository
echo ""
echo -e "${YELLOW}📦 Initializing Git repository...${NC}"
git init -b main
echo -e "${GREEN}✓ Git repository initialized${NC}"

# Configure git user if not set
if [ -z "$(git config user.name)" ]; then
    echo ""
    echo -e "${YELLOW}Git user not configured. Please enter your details:${NC}"
    read -p "Enter your name: " git_name
    read -p "Enter your email: " git_email
    git config user.name "$git_name"
    git config user.email "$git_email"
    echo -e "${GREEN}✓ Git user configured${NC}"
else
    echo -e "${GREEN}✓ Git user already configured: $(git config user.name) <$(git config user.email)>${NC}"
fi

# Add remote
echo ""
echo -e "${YELLOW}🔗 Adding remote repository...${NC}"
git remote add origin "$REPO_URL"
echo -e "${GREEN}✓ Remote added: $REPO_URL${NC}"

# Stage all files
echo ""
echo -e "${YELLOW}📝 Staging files...${NC}"
git add .
echo -e "${GREEN}✓ Files staged${NC}"

# Show status
echo ""
echo -e "${YELLOW}📊 Repository status:${NC}"
git status --short | head -20
total_files=$(git status --short | wc -l)
echo ""
echo -e "${BLUE}Total files to commit: $total_files${NC}"

# Create initial commit
echo ""
echo -e "${YELLOW}💾 Creating initial commit...${NC}"
git commit -m "Initial commit: Expeditious Reader

- Flutter-based ebook reader application
- Multi-platform support (Web, Android, Linux, Windows)
- Speed reading and traditional reading modes
- Docker deployment setup
- Multi-platform build scripts
- Comprehensive documentation

Features:
- PDF, EPUB, TXT support
- Speed reading (100-1000 WPM)
- Traditional reading with lazy loading
- Library management
- Cross-platform compatibility

Technical:
- Flutter 3.x
- Provider state management
- SharedPreferences for storage
- Nginx-based Docker deployment
- Automated build scripts for all platforms"

echo -e "${GREEN}✓ Initial commit created${NC}"

# Show commit info
echo ""
echo -e "${YELLOW}📋 Commit information:${NC}"
git log --oneline -1
git show --stat --pretty=format:'' HEAD | head -20

# Push to remote
echo ""
echo -e "${YELLOW}🚀 Ready to push to GitHub${NC}"
echo -e "${BLUE}Remote: $REPO_URL${NC}"
echo -e "${BLUE}Branch: $BRANCH${NC}"
echo ""
read -p "Push to GitHub now? (Y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo ""
    echo -e "${YELLOW}Skipping push. You can push later with:${NC}"
    echo -e "${GREEN}  git push -u origin main${NC}"
    echo ""
else
    echo ""
    echo -e "${YELLOW}📤 Pushing to GitHub...${NC}"
    echo -e "${YELLOW}Note: You may be prompted for GitHub credentials${NC}"
    
    if git push -u origin main; then
        echo -e "${GREEN}✓ Successfully pushed to GitHub!${NC}"
    else
        echo -e "${RED}✗ Push failed${NC}"
        echo ""
        echo -e "${YELLOW}Common solutions:${NC}"
        echo "1. Generate a GitHub Personal Access Token:"
        echo "   https://github.com/settings/tokens"
        echo ""
        echo "2. Use SSH instead of HTTPS:"
        echo -e "   ${GREEN}git remote set-url origin git@github.com:Paul-PADataAnalytics/expeditiousreader.git${NC}"
        echo ""
        echo "3. Or push manually later:"
        echo -e "   ${GREEN}git push -u origin main${NC}"
        exit 1
    fi
fi

# Summary
echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   Git Setup Complete!${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Repository Information:${NC}"
echo -e "  URL:    $REPO_URL"
echo -e "  Branch: $BRANCH"
echo -e "  Commit: $(git log --oneline -1)"
echo ""
echo -e "${YELLOW}Useful Git Commands:${NC}"
echo -e "  Status:        ${GREEN}git status${NC}"
echo -e "  Add files:     ${GREEN}git add .${NC}"
echo -e "  Commit:        ${GREEN}git commit -m \"message\"${NC}"
echo -e "  Push:          ${GREEN}git push${NC}"
echo -e "  Pull:          ${GREEN}git pull${NC}"
echo -e "  View history:  ${GREEN}git log --oneline${NC}"
echo -e "  View remote:   ${GREEN}git remote -v${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Visit: https://github.com/Paul-PADataAnalytics/expeditiousreader"
echo "2. Verify the repository looks correct"
echo "3. Add a description and topics on GitHub"
echo "4. Consider adding branch protection rules"
echo ""
echo -e "${GREEN}🎉 Your project is now on GitHub!${NC}"
echo ""
