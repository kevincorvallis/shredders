#!/bin/bash

#
# activate-enhanced-ui.sh
# Script to activate the enhanced Shredders UI components
#

set -e

echo "======================================"
echo "  Shredders Enhanced UI Activator"
echo "======================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo -e "${RED}Error: Must run from project root directory${NC}"
    exit 1
fi

echo -e "${BLUE}This script will:${NC}"
echo "  1. Backup existing auth pages (Web)"
echo "  2. Activate enhanced auth pages (Web)"
echo "  3. Show instructions for iOS activation"
echo ""

# Ask for confirmation
read -p "Continue? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo -e "${YELLOW}Step 1: Web Auth Pages${NC}"
echo "--------------------------------"

# Web Login Page
if [ -f "src/app/auth/login/page.enhanced.tsx" ]; then
    echo "Found enhanced login page..."

    if [ -f "src/app/auth/login/page.tsx" ]; then
        echo "Backing up current login page..."
        mv src/app/auth/login/page.tsx src/app/auth/login/page.old.tsx
        echo -e "${GREEN}✓${NC} Backup created: page.old.tsx"
    fi

    echo "Activating enhanced login page..."
    mv src/app/auth/login/page.enhanced.tsx src/app/auth/login/page.tsx
    echo -e "${GREEN}✓${NC} Enhanced login activated"
else
    echo -e "${RED}✗${NC} Enhanced login page not found"
fi

echo ""

# Web Signup Page
if [ -f "src/app/auth/signup/page.enhanced.tsx" ]; then
    echo "Found enhanced signup page..."

    if [ -f "src/app/auth/signup/page.tsx" ]; then
        echo "Backing up current signup page..."
        mv src/app/auth/signup/page.tsx src/app/auth/signup/page.old.tsx
        echo -e "${GREEN}✓${NC} Backup created: page.old.tsx"
    fi

    echo "Activating enhanced signup page..."
    mv src/app/auth/signup/page.enhanced.tsx src/app/auth/signup/page.tsx
    echo -e "${GREEN}✓${NC} Enhanced signup activated"
else
    echo -e "${RED}✗${NC} Enhanced signup page not found"
fi

echo ""
echo -e "${YELLOW}Step 2: iOS Components${NC}"
echo "--------------------------------"
echo ""
echo "To activate iOS enhancements, update these files in Xcode:"
echo ""
echo -e "${BLUE}1. Replace UnifiedAuthView with EnhancedUnifiedAuthView:${NC}"
echo "   File: ios/PowderTracker/PowderTracker/Views/ContentView.swift"
echo "   Find: UnifiedAuthView()"
echo "   Replace: EnhancedUnifiedAuthView()"
echo ""
echo -e "${BLUE}2. Add Onboarding Flow:${NC}"
echo "   Add to ContentView.swift:"
echo '   @AppStorage("hasCompletedOnboarding") private var hasCompleted = false'
echo '   @State private var showOnboarding = false'
echo ""
echo '   .onAppear {'
echo '       if !hasCompleted {'
echo '           showOnboarding = true'
echo '       }'
echo '   }'
echo '   .sheet(isPresented: $showOnboarding) {'
echo '       OnboardingView(isPresented: $showOnboarding)'
echo '           .onDisappear { hasCompleted = true }'
echo '   }'
echo ""

echo -e "${YELLOW}Step 3: Web Welcome Flow (Optional)${NC}"
echo "--------------------------------"
echo ""
echo "To add the welcome flow for new users:"
echo ""
echo -e "${BLUE}Add to your main layout or home page:${NC}"
echo ""
echo 'import { WelcomeFlow } from "@/components/WelcomeFlow";'
echo 'import { useState, useEffect } from "react";'
echo ""
echo 'const [showWelcome, setShowWelcome] = useState(false);'
echo ""
echo 'useEffect(() => {'
echo '  const hasCompleted = localStorage.getItem("hasCompletedOnboarding");'
echo '  if (!hasCompleted) {'
echo '    setShowWelcome(true);'
echo '  }'
echo '}, []);'
echo ""
echo 'const handleComplete = () => {'
echo '  localStorage.setItem("hasCompletedOnboarding", "true");'
echo '  setShowWelcome(false);'
echo '};'
echo ""
echo '{showWelcome && ('
echo '  <WelcomeFlow'
echo '    onComplete={handleComplete}'
echo '    userName={user?.displayName}'
echo '  />'
echo ')}'
echo ""

echo -e "${YELLOW}Step 4: Testing${NC}"
echo "--------------------------------"
echo ""
echo "Test the changes:"
echo ""
echo -e "${BLUE}Web:${NC}"
echo "  npm run dev"
echo "  Visit http://localhost:3000/auth/login"
echo "  Visit http://localhost:3000/auth/signup"
echo ""
echo -e "${BLUE}iOS:${NC}"
echo "  Open in Xcode"
echo "  Run on simulator"
echo "  Test auth flow"
echo "  Test onboarding"
echo ""

echo -e "${YELLOW}Step 5: Rollback (if needed)${NC}"
echo "--------------------------------"
echo ""
echo "To revert to old UI:"
echo ""
echo -e "${BLUE}Web:${NC}"
echo "  cd src/app/auth/login"
echo "  mv page.tsx page.enhanced.tsx"
echo "  mv page.old.tsx page.tsx"
echo ""
echo "  cd ../signup"
echo "  mv page.tsx page.enhanced.tsx"
echo "  mv page.old.tsx page.tsx"
echo ""
echo -e "${BLUE}iOS:${NC}"
echo "  Revert changes in Xcode (Cmd+Z or git checkout)"
echo ""

echo -e "${GREEN}======================================"
echo "  Setup Complete!"
echo "======================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Test the new UI"
echo "  2. Read UI_ENHANCEMENTS.md for details"
echo "  3. Check DEMO_COMPONENTS.md for testing guide"
echo "  4. Gather team feedback"
echo ""
echo -e "${BLUE}Happy Shredding! 🏔️${NC}"
echo ""
