#!/usr/bin/env node
// Test SNOTEL with more detailed date range

const USER_AGENT = 'Shredders/1.0';

async function testSNOTEL(stationId, stationName) {
  // Get data for last 7 days
  const today = new Date();
  const sevenDaysAgo = new Date(today);
  sevenDaysAgo.setDate(today.getDate() - 7);
  
  const endDate = today.toISOString().split('T')[0];
  const beginDate = sevenDaysAgo.toISOString().split('T')[0];
  
  const url = `https://wcc.sc.egov.usda.gov/awdbRestApi/services/v1/data?stationTriplets=${stationId}&elements=SNWD,WTEQ,TOBS&duration=DAILY&beginDate=${beginDate}&endDate=${endDate}`;

  console.log(`\n🧪 ${stationName} (${stationId})`);
  console.log(`   Date range: ${beginDate} to ${endDate}`);

  try {
    const response = await fetch(url, {
      headers: { 'User-Agent': USER_AGENT }
    });

    if (!response.ok) {
      console.log(`   ❌ HTTP ${response.status}`);
      return;
    }

    const data = await response.json();
    
    if (!Array.isArray(data) || data.length === 0) {
      console.log(`   ❌ No data returned`);
      return;
    }

    const stationData = data[0];
    const elements = stationData.data || [];
    
    console.log(`   ✅ Station found: ${stationData.stationTriplet}`);
    console.log(`   📊 Elements available: ${elements.map(e => e.element).join(', ') || 'None'}`);
    
    elements.forEach(element => {
      const values = element.values || [];
      const latestValue = values[values.length - 1];
      
      if (latestValue) {
        const emoji = element.element === 'SNWD' ? '❄️ ' : element.element === 'WTEQ' ? '💧' : '🌡️ ';
        console.log(`   ${emoji} ${element.element}: ${latestValue.value} (${latestValue.date})`);
      }
    });

    if (elements.length === 0) {
      console.log(`   ⚠️  Station configured but no data elements returned (may be offline)`);
    }

  } catch (error) {
    console.log(`   ❌ Error: ${error.message}`);
  }
}

async function main() {
  console.log('═══════════════════════════════════════════');
  console.log('  SNOTEL Station Detailed Verification');
  console.log('═══════════════════════════════════════════');

  const stations = [
    { id: '815:OR:SNTL', name: 'Mt. Bachelor - Three Creeks Meadow' },
    { id: '648:WA:SNTL', name: 'Mission Ridge - Mount Crag' },
    { id: '594:ID:SNTL', name: 'Lookout Pass' },
    { id: '895:ID:SNTL', name: 'Sun Valley - Chocolate Gulch' },
    { id: '370:ID:SNTL', name: 'Brundage - Brundage Reservoir' },
    { id: '361:OR:SNTL', name: 'Anthony Lakes - Bourne' },
  ];

  for (const station of stations) {
    await testSNOTEL(station.id, station.name);
    await new Promise(r => setTimeout(r, 1000));
  }

  console.log('\n═══════════════════════════════════════════');
}

main();
