#!/usr/bin/env node
/**
 * Test weather.gov API integration for all 15 mountains
 */

const mountains = {
  baker: { name: 'Mt. Baker', lat: 48.857, lng: -121.669, noaa: { gridOffice: 'SEW', gridX: 157, gridY: 123 } },
  stevens: { name: 'Stevens Pass', lat: 47.745, lng: -121.089, noaa: { gridOffice: 'SEW', gridX: 163, gridY: 108 } },
  crystal: { name: 'Crystal Mountain', lat: 46.935, lng: -121.474, noaa: { gridOffice: 'SEW', gridX: 142, gridY: 90 } },
  snoqualmie: { name: 'Summit at Snoqualmie', lat: 47.428, lng: -121.413, noaa: { gridOffice: 'SEW', gridX: 152, gridY: 97 } },
  whitepass: { name: 'White Pass', lat: 46.637, lng: -121.391, noaa: { gridOffice: 'PDT', gridX: 131, gridY: 80 } },
  meadows: { name: 'Mt. Hood Meadows', lat: 45.331, lng: -121.665, noaa: { gridOffice: 'PQR', gridX: 138, gridY: 105 } },
  timberline: { name: 'Timberline Lodge', lat: 45.331, lng: -121.711, noaa: { gridOffice: 'PQR', gridX: 136, gridY: 103 } },
  bachelor: { name: 'Mt. Bachelor', lat: 43.979, lng: -121.688, noaa: { gridOffice: 'PDT', gridX: 118, gridY: 43 } },
  missionridge: { name: 'Mission Ridge', lat: 47.293, lng: -120.398, noaa: { gridOffice: 'OTX', gridX: 53, gridY: 107 } },
  fortynine: { name: '49 Degrees North', lat: 48.795, lng: -117.565, noaa: { gridOffice: 'OTX', gridX: 118, gridY: 135 } },
  schweitzer: { name: 'Schweitzer Mountain', lat: 48.368, lng: -116.622, noaa: { gridOffice: 'OTX', gridX: 131, gridY: 123 } },
  lookout: { name: 'Lookout Pass', lat: 47.454, lng: -115.713, noaa: { gridOffice: 'MSO', gridX: 159, gridY: 82 } },
  ashland: { name: 'Mt. Ashland', lat: 42.086, lng: -122.715, noaa: { gridOffice: 'MFR', gridX: 89, gridY: 62 } },
  willamette: { name: 'Willamette Pass', lat: 43.596, lng: -122.039, noaa: { gridOffice: 'PQR', gridX: 112, gridY: 69 } },
  hoodoo: { name: 'Hoodoo Ski Area', lat: 44.408, lng: -121.870, noaa: { gridOffice: 'PDT', gridX: 107, gridY: 65 } },
};

const USER_AGENT = 'Shredders/1.0 (contact@pookieb.com)';

async function fetchWithRetry(url, retries = 2) {
  for (let i = 0; i < retries; i++) {
    try {
      const response = await fetch(url, {
        headers: {
          'User-Agent': USER_AGENT,
          'Accept': 'application/geo+json',
        },
      });

      if (response.ok) return response;

      if (response.status === 503 && i < retries - 1) {
        await new Promise(r => setTimeout(r, 1000 * (i + 1)));
        continue;
      }

      return response;
    } catch (error) {
      if (i === retries - 1) throw error;
      await new Promise(r => setTimeout(r, 1000 * (i + 1)));
    }
  }
}

async function testMountain(id, mountain) {
  const { gridOffice, gridX, gridY } = mountain.noaa;
  const results = {
    mountain: mountain.name,
    forecast: '❌',
    hourly: '❌',
    alerts: '❌',
    gridData: '❌',
    forecastPeriods: 0,
    hourlyPeriods: 0,
    alertCount: 0,
    snowfallData: false,
  };

  console.log(`\n🏔️  Testing ${mountain.name} (${gridOffice}/${gridX},${gridY})...`);

  // Test Forecast
  try {
    const forecastUrl = `https://api.weather.gov/gridpoints/${gridOffice}/${gridX},${gridY}/forecast`;
    const response = await fetchWithRetry(forecastUrl);
    if (response.ok) {
      const data = await response.json();
      results.forecast = '✅';
      results.forecastPeriods = data.properties?.periods?.length || 0;
      console.log(`  ✓ Forecast: ${results.forecastPeriods} periods`);
    } else {
      console.log(`  ✗ Forecast: HTTP ${response.status}`);
    }
  } catch (error) {
    console.log(`  ✗ Forecast: ${error.message}`);
  }

  // Test Hourly Forecast
  try {
    const hourlyUrl = `https://api.weather.gov/gridpoints/${gridOffice}/${gridX},${gridY}/forecast/hourly`;
    const response = await fetchWithRetry(hourlyUrl);
    if (response.ok) {
      const data = await response.json();
      results.hourly = '✅';
      results.hourlyPeriods = data.properties?.periods?.length || 0;
      console.log(`  ✓ Hourly: ${results.hourlyPeriods} periods`);
    } else {
      console.log(`  ✗ Hourly: HTTP ${response.status}`);
    }
  } catch (error) {
    console.log(`  ✗ Hourly: ${error.message}`);
  }

  // Test Alerts
  try {
    const alertUrl = `https://api.weather.gov/alerts/active?point=${mountain.lat},${mountain.lng}`;
    const response = await fetchWithRetry(alertUrl);
    if (response.ok) {
      const data = await response.json();
      results.alerts = '✅';
      results.alertCount = data.features?.length || 0;
      console.log(`  ✓ Alerts: ${results.alertCount} active`);
    } else {
      console.log(`  ✗ Alerts: HTTP ${response.status}`);
    }
  } catch (error) {
    console.log(`  ✗ Alerts: ${error.message}`);
  }

  // Test Grid Data (for snowfall)
  try {
    const gridUrl = `https://api.weather.gov/gridpoints/${gridOffice}/${gridX},${gridY}`;
    const response = await fetchWithRetry(gridUrl);
    if (response.ok) {
      const data = await response.json();
      results.gridData = '✅';
      results.snowfallData = !!data.properties?.snowfallAmount?.values?.length;
      console.log(`  ✓ Grid Data: Snowfall ${results.snowfallData ? 'available' : 'not available'}`);
    } else {
      console.log(`  ✗ Grid Data: HTTP ${response.status}`);
    }
  } catch (error) {
    console.log(`  ✗ Grid Data: ${error.message}`);
  }

  // Small delay to avoid rate limiting
  await new Promise(r => setTimeout(r, 200));

  return results;
}

async function main() {
  console.log('╔════════════════════════════════════════════════════════════════╗');
  console.log('║        Weather.gov API Test - All 15 Mountains                ║');
  console.log('╚════════════════════════════════════════════════════════════════╝');

  const allResults = [];

  for (const [id, mountain] of Object.entries(mountains)) {
    const result = await testMountain(id, mountain);
    allResults.push(result);
  }

  // Summary
  console.log('\n╔════════════════════════════════════════════════════════════════╗');
  console.log('║                        TEST SUMMARY                           ║');
  console.log('╚════════════════════════════════════════════════════════════════╝\n');

  console.log('Mountain                  Forecast Hourly Alerts Grid  Snowfall');
  console.log('─────────────────────────────────────────────────────────────────');

  for (const result of allResults) {
    const name = result.mountain.padEnd(24);
    const forecast = result.forecast.padEnd(8);
    const hourly = result.hourly.padEnd(7);
    const alerts = result.alerts.padEnd(7);
    const grid = result.gridData.padEnd(6);
    const snowfall = result.snowfallData ? '✅' : '❌';
    console.log(`${name} ${forecast} ${hourly} ${alerts} ${grid} ${snowfall}`);
  }

  // Stats
  const totalMountains = allResults.length;
  const forecastOk = allResults.filter(r => r.forecast === '✅').length;
  const hourlyOk = allResults.filter(r => r.hourly === '✅').length;
  const alertsOk = allResults.filter(r => r.alerts === '✅').length;
  const gridOk = allResults.filter(r => r.gridData === '✅').length;
  const snowfallOk = allResults.filter(r => r.snowfallData).length;

  console.log('\n📊 Success Rates:');
  console.log(`   Forecast:     ${forecastOk}/${totalMountains} (${Math.round(forecastOk/totalMountains*100)}%)`);
  console.log(`   Hourly:       ${hourlyOk}/${totalMountains} (${Math.round(hourlyOk/totalMountains*100)}%)`);
  console.log(`   Alerts:       ${alertsOk}/${totalMountains} (${Math.round(alertsOk/totalMountains*100)}%)`);
  console.log(`   Grid Data:    ${gridOk}/${totalMountains} (${Math.round(gridOk/totalMountains*100)}%)`);
  console.log(`   Snowfall:     ${snowfallOk}/${totalMountains} (${Math.round(snowfallOk/totalMountains*100)}%)`);

  const totalTests = forecastOk + hourlyOk + alertsOk + gridOk;
  const maxTests = totalMountains * 4;
  const overallSuccess = Math.round(totalTests / maxTests * 100);

  console.log(`\n🎯 Overall Success: ${overallSuccess}%\n`);

  if (overallSuccess >= 90) {
    console.log('✅ EXCELLENT - Weather.gov integration is working great!');
  } else if (overallSuccess >= 75) {
    console.log('⚠️  GOOD - Most endpoints working, some issues detected');
  } else {
    console.log('❌ ISSUES - Significant problems with weather.gov API');
  }
}

main().catch(console.error);
