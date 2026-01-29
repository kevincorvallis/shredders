#!/bin/bash
#
# ralphloop-ui.sh - Interactive UI Enhancement Loop for PowderTracker
#
# Usage:
#   ./scripts/ralphloop-ui.sh [phase]
#
# Examples:
#   ./scripts/ralphloop-ui.sh        # Start from beginning or resume
#   ./scripts/ralphloop-ui.sh 1      # Start Phase 1
#   ./scripts/ralphloop-ui.sh 5      # Start Phase 5
#   ./scripts/ralphloop-ui.sh status # Show current status
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Paths
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IOS_ROOT="$PROJECT_ROOT/ios/PowderTracker"
TODO_FILE="$PROJECT_ROOT/todoUI.md"
PROGRESS_FILE="$PROJECT_ROOT/.ralphloop-ui-progress"

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║       🎿 PowderTracker UI Enhancement Loop (ralphloop)        ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Load progress
load_progress() {
    if [ -f "$PROGRESS_FILE" ]; then
        source "$PROGRESS_FILE"
    else
        CURRENT_PHASE=1
        PHASE_1_COMPLETE=false
        PHASE_2_COMPLETE=false
        PHASE_3_COMPLETE=false
        PHASE_4_COMPLETE=false
        PHASE_5_COMPLETE=false
        PHASE_6_COMPLETE=false
        PHASE_7_COMPLETE=false
        PHASE_8_COMPLETE=false
        PHASE_9_COMPLETE=false
        PHASE_10_COMPLETE=false
    fi
}

# Save progress
save_progress() {
    cat > "$PROGRESS_FILE" << EOF
CURRENT_PHASE=$CURRENT_PHASE
PHASE_1_COMPLETE=$PHASE_1_COMPLETE
PHASE_2_COMPLETE=$PHASE_2_COMPLETE
PHASE_3_COMPLETE=$PHASE_3_COMPLETE
PHASE_4_COMPLETE=$PHASE_4_COMPLETE
PHASE_5_COMPLETE=$PHASE_5_COMPLETE
PHASE_6_COMPLETE=$PHASE_6_COMPLETE
PHASE_7_COMPLETE=$PHASE_7_COMPLETE
PHASE_8_COMPLETE=$PHASE_8_COMPLETE
PHASE_9_COMPLETE=$PHASE_9_COMPLETE
PHASE_10_COMPLETE=$PHASE_10_COMPLETE
EOF
}

# Show status
show_status() {
    load_progress
    echo -e "${BLUE}Current Progress:${NC}"
    echo ""
    phases=("Visual Foundation" "Loading States" "Haptic Feedback" "Animations" "Data Visualization" "Scroll Effects" "Sheets & Modals" "Social Features" "Platform Integration" "Performance & Polish")

    for i in {1..10}; do
        var_name="PHASE_${i}_COMPLETE"
        status=${!var_name}
        if [ "$status" = "true" ]; then
            echo -e "  ${GREEN}✅ Phase $i: ${phases[$((i-1))]}${NC}"
        elif [ "$CURRENT_PHASE" = "$i" ]; then
            echo -e "  ${YELLOW}🔄 Phase $i: ${phases[$((i-1))]} (IN PROGRESS)${NC}"
        else
            echo -e "  ${RED}⬜ Phase $i: ${phases[$((i-1))]}${NC}"
        fi
    done
    echo ""
}

# Build check
build_check() {
    echo -e "${BLUE}🔨 Building app...${NC}"
    cd "$IOS_ROOT"
    if xcodebuild -scheme PowderTracker -destination 'platform=iOS Simulator,name=iPhone 16' -quiet build 2>/dev/null; then
        echo -e "${GREEN}✅ Build successful${NC}"
        return 0
    else
        echo -e "${RED}❌ Build failed${NC}"
        return 1
    fi
}

# Phase 1: Visual Foundation
phase_1() {
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}  Phase 1: Visual Foundation & Glassmorphism${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${BLUE}Checking glassmorphic components...${NC}"
    glass_count=$(grep -r "ultraThinMaterial\|thinMaterial" "$IOS_ROOT" --include="*.swift" 2>/dev/null | wc -l | tr -d ' ')
    echo "  Material usage: $glass_count occurrences (target: >10)"

    echo -e "${BLUE}Checking gradient usage...${NC}"
    gradient_count=$(grep -r "LinearGradient\|RadialGradient" "$IOS_ROOT" --include="*.swift" 2>/dev/null | wc -l | tr -d ' ')
    echo "  Gradient usage: $gradient_count occurrences (target: >5)"

    echo -e "${BLUE}Checking symbol effects...${NC}"
    symbol_count=$(grep -r "symbolEffect\|symbolRenderingMode" "$IOS_ROOT" --include="*.swift" 2>/dev/null | wc -l | tr -d ' ')
    echo "  Symbol effects: $symbol_count occurrences (target: >3)"

    echo ""
    echo -e "${YELLOW}📋 Phase 1 Checklist:${NC}"
    echo "  [ ] Create GlassmorphicCard component"
    echo "  [ ] Add border strokes to cards"
    echo "  [ ] Implement layered shadows"
    echo "  [ ] Define gradient presets"
    echo "  [ ] Use SF Rounded for numbers"
    echo "  [ ] Audit icons for SF Symbols"
    echo ""
    echo -e "${YELLOW}📸 Manual Tasks:${NC}"
    echo "  - Take screenshots of all main screens"
    echo "  - Compare before/after in light AND dark mode"
    echo "  - Verify cards have depth and don't look flat"
    echo ""
}

# Phase 2: Loading States
phase_2() {
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}  Phase 2: Loading States & Skeletons${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${BLUE}Checking skeleton components...${NC}"
    skeleton_count=$(grep -r "Skeleton\|shimmer\|redacted" "$IOS_ROOT" --include="*.swift" 2>/dev/null | wc -l | tr -d ' ')
    echo "  Skeleton components: $skeleton_count occurrences (target: >5)"

    echo -e "${BLUE}Checking ContentUnavailableView...${NC}"
    if grep -r "ContentUnavailableView" "$IOS_ROOT" --include="*.swift" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ ContentUnavailableView found${NC}"
    else
        echo -e "  ${RED}❌ ContentUnavailableView not found${NC}"
    fi

    echo ""
    echo -e "${YELLOW}📋 Phase 2 Checklist:${NC}"
    echo "  [ ] Create SkeletonView with shimmer"
    echo "  [ ] Implement MountainCardSkeleton"
    echo "  [ ] Progressive loading with stagger"
    echo "  [ ] Custom pull-to-refresh animation"
    echo "  [ ] Illustrated empty states"
    echo ""
    echo -e "${YELLOW}📱 Manual Tasks:${NC}"
    echo "  - Enable Network Link Conditioner → Very Bad Network"
    echo "  - Open app fresh - verify skeletons appear"
    echo "  - Test empty favorites state"
    echo ""
}

# Phase 3: Haptics
phase_3() {
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}  Phase 3: Haptic Feedback System${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${BLUE}Checking haptic implementation...${NC}"
    haptic_count=$(grep -r "UIImpactFeedbackGenerator\|UINotificationFeedbackGenerator\|sensoryFeedback" "$IOS_ROOT" --include="*.swift" 2>/dev/null | wc -l | tr -d ' ')
    echo "  Haptic usage: $haptic_count occurrences (target: >8)"

    echo -e "${BLUE}Checking HapticManager...${NC}"
    if grep -r "HapticManager\|HapticFeedback" "$IOS_ROOT" --include="*.swift" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ HapticManager found${NC}"
    else
        echo -e "  ${RED}❌ HapticManager not found${NC}"
    fi

    echo ""
    echo -e "${YELLOW}📋 Phase 3 Checklist:${NC}"
    echo "  [ ] Create HapticManager singleton"
    echo "  [ ] Tab bar selection → .selection"
    echo "  [ ] Favorite toggle → .success/.light"
    echo "  [ ] Pull-to-refresh → .medium"
    echo "  [ ] Network error → .error"
    echo ""
    echo -e "${RED}⚠️  CRITICAL: Test on PHYSICAL device - haptics don't work in Simulator${NC}"
    echo ""
}

# Phase 4: Animations
phase_4() {
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}  Phase 4: Animations & Transitions${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${BLUE}Checking spring animations...${NC}"
    spring_count=$(grep -r "\.spring\|withAnimation" "$IOS_ROOT" --include="*.swift" 2>/dev/null | wc -l | tr -d ' ')
    echo "  Spring/animation usage: $spring_count occurrences (target: >15)"

    echo -e "${BLUE}Checking matched geometry...${NC}"
    matched_count=$(grep -r "matchedGeometryEffect" "$IOS_ROOT" --include="*.swift" 2>/dev/null | wc -l | tr -d ' ')
    echo "  matchedGeometryEffect: $matched_count occurrences (target: >2)"

    echo -e "${BLUE}Checking scroll transitions...${NC}"
    if grep -r "scrollTransition" "$IOS_ROOT" --include="*.swift" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ scrollTransition found${NC}"
    else
        echo -e "  ${RED}❌ scrollTransition not found${NC}"
    fi

    echo ""
    echo -e "${YELLOW}📋 Phase 4 Checklist:${NC}"
    echo "  [ ] Use .spring() instead of .easeInOut"
    echo "  [ ] Scale effect on card press (0.98)"
    echo "  [ ] Hero transitions card → detail"
    echo "  [ ] Stagger card appearance"
    echo "  [ ] Mode picker sliding indicator"
    echo ""
    echo -e "${YELLOW}🎬 Manual Tasks:${NC}"
    echo "  - Record screen recording of full app flow"
    echo "  - Check 'Reduce Motion' is respected"
    echo ""
}

# Phase 5: Charts
phase_5() {
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}  Phase 5: Interactive Data Visualization${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${BLUE}Checking Charts import...${NC}"
    if grep -r "import Charts" "$IOS_ROOT" --include="*.swift" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ Charts framework imported${NC}"
    else
        echo -e "  ${RED}❌ Charts framework not imported${NC}"
    fi

    echo -e "${BLUE}Checking chart components...${NC}"
    chart_count=$(grep -r "BarMark\|LineMark\|Chart {" "$IOS_ROOT" --include="*.swift" 2>/dev/null | wc -l | tr -d ' ')
    echo "  Chart components: $chart_count occurrences (target: >3)"

    echo ""
    echo -e "${YELLOW}📋 Phase 5 Checklist:${NC}"
    echo "  [ ] Create SnowfallForecastChart"
    echo "  [ ] Add temperature line overlay"
    echo "  [ ] Visual depth indicator"
    echo "  [ ] Circular gauge for powder score"
    echo "  [ ] Lift status visual grid"
    echo ""
}

# Phase 6: Scroll Effects
phase_6() {
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}  Phase 6: Collapsible Headers & Scroll Effects${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${BLUE}Checking scroll tracking...${NC}"
    scroll_count=$(grep -r "GeometryReader\|ScrollViewReader" "$IOS_ROOT" --include="*.swift" 2>/dev/null | wc -l | tr -d ' ')
    echo "  GeometryReader/ScrollViewReader: $scroll_count occurrences (target: >3)"

    echo -e "${BLUE}Checking parallax implementation...${NC}"
    parallax_count=$(grep -r "minY\|offset\|parallax" "$IOS_ROOT" --include="*.swift" 2>/dev/null | wc -l | tr -d ' ')
    echo "  Parallax/offset: $parallax_count occurrences"

    echo ""
    echo -e "${YELLOW}📋 Phase 6 Checklist:${NC}"
    echo "  [ ] Create CollapsibleHeaderView"
    echo "  [ ] Sticky section headers"
    echo "  [ ] .scrollTransition for card scale"
    echo "  [ ] Scroll to top button"
    echo ""
}

# Phase 7: Sheets
phase_7() {
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}  Phase 7: Bottom Sheets & Modals${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${BLUE}Checking presentation modifiers...${NC}"
    present_count=$(grep -r "presentationDetents\|presentationBackground" "$IOS_ROOT" --include="*.swift" 2>/dev/null | wc -l | tr -d ' ')
    echo "  Presentation modifiers: $present_count occurrences (target: >3)"

    echo -e "${BLUE}Checking context menus...${NC}"
    if grep -r "contextMenu" "$IOS_ROOT" --include="*.swift" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ Context menus found${NC}"
    else
        echo -e "  ${RED}❌ Context menus not found${NC}"
    fi

    echo ""
    echo -e "${YELLOW}📋 Phase 7 Checklist:${NC}"
    echo "  [ ] Use presentationDetents with multiple heights"
    echo "  [ ] Add context menu to mountain cards"
    echo "  [ ] Implement swipe actions on list rows"
    echo "  [ ] Confirmation for destructive actions"
    echo ""
}

# Phase 8: Social
phase_8() {
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}  Phase 8: Social & Gamification Features${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${BLUE}Checking share functionality...${NC}"
    if grep -r "ShareLink\|UIActivityViewController" "$IOS_ROOT" --include="*.swift" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ Share functionality found${NC}"
    else
        echo -e "  ${RED}❌ Share functionality not found${NC}"
    fi

    echo -e "${BLUE}Checking achievements...${NC}"
    if grep -r "Achievement\|Badge\|Leaderboard" "$IOS_ROOT" --include="*.swift" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ Achievement system found${NC}"
    else
        echo -e "  ${RED}❌ Achievement system not found${NC}"
    fi

    echo ""
    echo -e "${YELLOW}📋 Phase 8 Checklist:${NC}"
    echo "  [ ] Design achievement badges"
    echo "  [ ] Create unlock animation"
    echo "  [ ] Instagram Story share card"
    echo "  [ ] Shareable stats cards"
    echo ""
}

# Phase 9: Platform Integration
phase_9() {
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}  Phase 9: Platform Integration${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${BLUE}Checking Widget extension...${NC}"
    if find "$IOS_ROOT" -name "*Widget*" -type d | grep -q .; then
        echo -e "  ${GREEN}✅ Widget extension found${NC}"
    else
        echo -e "  ${RED}❌ Widget extension not found${NC}"
    fi

    echo -e "${BLUE}Checking ActivityKit...${NC}"
    if grep -r "ActivityKit\|Activity.request" "$IOS_ROOT" --include="*.swift" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ ActivityKit found${NC}"
    else
        echo -e "  ${RED}❌ ActivityKit not found${NC}"
    fi

    echo -e "${BLUE}Checking App Intents...${NC}"
    if grep -r "AppIntent\|@AppIntent" "$IOS_ROOT" --include="*.swift" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ App Intents found${NC}"
    else
        echo -e "  ${RED}❌ App Intents not found${NC}"
    fi

    echo ""
    echo -e "${YELLOW}📋 Phase 9 Checklist:${NC}"
    echo "  [ ] Create Widget extension"
    echo "  [ ] Small/Medium/Large widgets"
    echo "  [ ] Live Activities for ski day"
    echo "  [ ] Siri shortcuts"
    echo ""
}

# Phase 10: Polish
phase_10() {
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}  Phase 10: Performance & Polish${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${BLUE}Checking debug code...${NC}"
    debug_count=$(grep -r "print(\|debugPrint" "$IOS_ROOT" --include="*.swift" 2>/dev/null | grep -v "Tests" | wc -l | tr -d ' ')
    echo "  Debug print statements: $debug_count (should review each)"

    echo ""
    echo -e "${YELLOW}📋 Phase 10 Checklist:${NC}"
    echo "  [ ] Profile with Instruments"
    echo "  [ ] Ensure 60fps scrolling"
    echo "  [ ] Test on iPhone SE (smallest)"
    echo "  [ ] Test on Pro Max (largest)"
    echo "  [ ] Test light and dark mode"
    echo "  [ ] Run Accessibility Inspector"
    echo "  [ ] Remove debug code"
    echo "  [ ] Record demo video"
    echo ""

    # Final build check
    echo -e "${BLUE}Running final build checks...${NC}"
    echo ""
    echo "Building for iPhone SE (3rd generation)..."
    cd "$IOS_ROOT"
    if xcodebuild -scheme PowderTracker -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation)' -quiet build 2>/dev/null; then
        echo -e "${GREEN}✅ iPhone SE build passed${NC}"
    else
        echo -e "${RED}❌ iPhone SE build failed${NC}"
    fi

    echo "Building for iPhone 16 Pro Max..."
    if xcodebuild -scheme PowderTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' -quiet build 2>/dev/null; then
        echo -e "${GREEN}✅ iPhone 16 Pro Max build passed${NC}"
    else
        echo -e "${RED}❌ iPhone 16 Pro Max build failed${NC}"
    fi
}

# Mark phase complete
mark_complete() {
    local phase=$1
    eval "PHASE_${phase}_COMPLETE=true"
    CURRENT_PHASE=$((phase + 1))
    if [ $CURRENT_PHASE -gt 10 ]; then
        CURRENT_PHASE=10
    fi
    save_progress
    echo -e "${GREEN}✅ Phase $phase marked complete!${NC}"
}

# Interactive menu
interactive_menu() {
    load_progress

    while true; do
        echo ""
        echo -e "${CYAN}What would you like to do?${NC}"
        echo "  1) Run current phase validation (Phase $CURRENT_PHASE)"
        echo "  2) Mark current phase complete"
        echo "  3) Show all phase status"
        echo "  4) Jump to specific phase"
        echo "  5) Build check"
        echo "  6) Open todoUI.md"
        echo "  q) Quit"
        echo ""
        read -p "Enter choice: " choice

        case $choice in
            1)
                "phase_$CURRENT_PHASE"
                ;;
            2)
                mark_complete $CURRENT_PHASE
                ;;
            3)
                show_status
                ;;
            4)
                read -p "Enter phase number (1-10): " phase_num
                if [[ $phase_num =~ ^[0-9]+$ ]] && [ $phase_num -ge 1 ] && [ $phase_num -le 10 ]; then
                    CURRENT_PHASE=$phase_num
                    save_progress
                    "phase_$phase_num"
                else
                    echo -e "${RED}Invalid phase number${NC}"
                fi
                ;;
            5)
                build_check
                ;;
            6)
                ${EDITOR:-code} "$TODO_FILE"
                ;;
            q|Q)
                echo -e "${GREEN}Progress saved. Goodbye! 🎿${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice${NC}"
                ;;
        esac
    done
}

# Main
main() {
    load_progress

    case "${1:-}" in
        status)
            show_status
            ;;
        [1-9]|10)
            CURRENT_PHASE=$1
            save_progress
            "phase_$1"
            interactive_menu
            ;;
        "")
            show_status
            echo ""
            interactive_menu
            ;;
        *)
            echo "Usage: $0 [phase|status]"
            echo "  phase: 1-10"
            echo "  status: Show current progress"
            exit 1
            ;;
    esac
}

main "$@"
