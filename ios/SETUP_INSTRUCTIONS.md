# Setup Instructions - Adding Creative Visualizations

The new visualization components have been created but need to be manually added to Xcode.

## Quick Setup (5 minutes)

### Step 1: Add Files to Xcode

Open Xcode (already open), then:

1. **Add Components folder files:**
   - In Xcode's left sidebar, right-click on `PowderTracker/Views/Components`
   - Select "Add Files to 'PowderTracker'..."
   - Navigate to: `/Users/kevin/Downloads/shredders/ios/PowderTracker/PowderTracker/Views/Components`
   - Select these 3 files (hold Cmd to select multiple):
     - `AtAGlanceCard.swift`
     - `RadialDashboard.swift`
     - `LiftLinePredictorCard.swift`
   - Make sure "Copy items if needed" is **unchecked** (they're already in the right place)
   - Make sure "Add to targets: PowderTracker" is **checked**
   - Click "Add"

2. **Add Services folder:**
   - In Xcode's left sidebar, right-click on `PowderTracker` (the top-level folder)
   - Select "New Group"
   - Name it: `Services`
   - Right-click on the new `Services` folder
   - Select "Add Files to 'PowderTracker'..."
   - Navigate to: `/Users/kevin/Downloads/shredders/ios/PowderTracker/PowderTracker/Services`
   - Select: `LiftLinePredictor.swift`
   - Make sure "Copy items if needed" is **unchecked**
   - Make sure "Add to targets: PowderTracker" is **checked**
   - Click "Add"

3. **Fix RoadConditionsSection (if needed):**
   - In Xcode's left sidebar, right-click on `PowderTracker/Views/Location`
   - Select "Add Files to 'PowderTracker'..."
   - Navigate to: `/Users/kevin/Downloads/shredders/ios/PowderTracker/PowderTracker/Views/Location`
   - Select: `RoadConditionsSection.swift`
   - Make sure "Copy items if needed" is **unchecked**
   - Make sure "Add to targets: PowderTracker" is **checked**
   - Click "Add"
   - If it says the file already exists, skip this step

### Step 2: Enable the New Visualizations

Once files are added, open `LocationView.swift` and make these changes:

1. **Uncomment the view mode toggle** (around line 35-38):
   ```swift
   // Change from:
   // // View mode toggle
   // // viewModeToggle
   //
   // To:
   // View mode toggle
   viewModeToggle
       .padding(.horizontal)
   ```

2. **Uncomment the main visualization** (around line 40-49):
   ```swift
   // Uncomment this entire Group block:
   Group {
       switch viewMode {
       case .glance:
           AtAGlanceCard(viewModel: viewModel)
       case .radial:
           RadialDashboard(viewModel: viewModel)
       }
   }
   .padding(.horizontal)
   ```

3. **Uncomment the lift line predictor** (around line 51-55):
   ```swift
   // Uncomment:
   if viewModel.locationData?.conditions.liftStatus != nil {
       LiftLinePredictorCard(viewModel: viewModel)
           .padding(.horizontal)
   }
   ```

4. **Remove temporary sections and add collapsible sections**:
   Delete these lines (around 58-86):
   ```swift
   // Temporary: Keep existing sections visible
   // Lift Status Section
   LiftStatusSection(viewModel: viewModel)
       .padding(.horizontal)
   // ... etc
   ```

   Replace with:
   ```swift
   // Detailed sections toggle
   Button {
       withAnimation(.spring()) {
           showingDetailedSections.toggle()
       }
   } label: {
       HStack {
           Image(systemName: showingDetailedSections ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
           Text(showingDetailedSections ? "Hide Detailed Sections" : "Show More Details")
               .fontWeight(.medium)
       }
       .font(.subheadline)
       .foregroundColor(.blue)
       .frame(maxWidth: .infinity)
       .padding()
       .background(Color(.secondarySystemBackground))
       .cornerRadius(12)
   }
   .buttonStyle(.plain)
   .padding(.horizontal)

   // Detailed sections (collapsible)
   if showingDetailedSections {
       VStack(spacing: 16) {
           // Snow Depth Section
           SnowDepthSection(viewModel: viewModel)
               .transition(.move(edge: .top).combined(with: .opacity))

           // Weather Conditions Section
           WeatherConditionsSection(viewModel: viewModel)
               .transition(.move(edge: .top).combined(with: .opacity))

           // Map Section
           if let mountainDetail = viewModel.locationData?.mountain {
               LocationMapSection(mountain: mountain, mountainDetail: mountainDetail)
                   .transition(.move(edge: .top).combined(with: .opacity))
           }

           // Road Conditions Section (only if has data)
           if viewModel.hasRoadData {
               RoadConditionsSection(viewModel: viewModel)
                   .transition(.move(edge: .top).combined(with: .opacity))
           }

           // Webcams Section (only if has webcams)
           if viewModel.hasWebcams {
               WebcamsSection(viewModel: viewModel)
                   .transition(.move(edge: .top).combined(with: .opacity))
           }
       }
       .padding(.horizontal)
   }
   ```

5. **Uncomment the viewModeToggle at the bottom** (around line 135-163):
   ```swift
   // Make sure this private var is uncommented:
   private var viewModeToggle: some View {
       HStack(spacing: 12) {
           ForEach([ViewMode.glance, ViewMode.radial], id: \.self) { mode in
               Button {
                   withAnimation(.spring(response: 0.3)) {
                       viewMode = mode
                   }
               } label: {
                   HStack(spacing: 6) {
                       Image(systemName: mode == .glance ? "square.grid.2x2.fill" : "circle.grid.cross.fill")
                           .font(.caption)
                       Text(mode == .glance ? "At a Glance" : "Radial View")
                           .font(.caption)
                           .fontWeight(.semibold)
                   }
                   .foregroundColor(viewMode == mode ? .white : .blue)
                   .padding(.horizontal, 16)
                   .padding(.vertical, 8)
                   .background(
                       Capsule()
                           .fill(viewMode == mode ? Color.blue : Color.blue.opacity(0.1))
                   )
               }
               .buttonStyle(.plain)
           }
       }
   }
   ```

### Step 3: Build and Run

1. Press **Cmd+B** to build
2. If successful, press **Cmd+R** to run
3. Navigate to a mountain detail view
4. You should now see:
   - Toggle buttons at top ("At a Glance" / "Radial View")
   - Main visualization (switchable)
   - Lift Line Predictor card
   - "Show More Details" button to expand full sections

## If You Get Build Errors

If you see errors after uncommenting:

1. **"Cannot find 'AtAGlanceCard' in scope"**
   - Make sure you added the files in Step 1
   - Check that "Target Membership" is checked for PowderTracker

2. **"Cannot find 'RoadConditionsSection' in scope"**
   - Repeat Step 1.3 to add RoadConditionsSection.swift

3. **Other Swift errors**
   - Try cleaning the build: **Product → Clean Build Folder** (Shift+Cmd+K)
   - Then rebuild: **Cmd+B**

## What You're Getting

### 1. At a Glance Card
- Powder score banner
- 3-column grid: Snow | Weather | Lifts
- Tap any section to expand details
- 80% of info visible without scrolling

### 2. Radial Dashboard
- Apple Watch-style activity rings
- Center: Powder score
- Inner ring: Snow (24h/48h/72h)
- Middle ring: Weather (temp/wind)
- Outer ring: Lifts/roads
- Tap rings to see metrics

### 3. Lift Line Predictor
- AI-powered wait time predictions
- Considers time, day, conditions, terrain
- Shows busyness for different lift types
- Includes confidence scores
- **First-of-its-kind in ski apps!**

---

Need help? Check `CREATIVE_VISUALIZATIONS.md` for full documentation.
