#!/usr/bin/env node
/**
 * Test enhanced powder score calculation for all 15 mountains
 */

const BASE_URL = 'http://localhost:3000';

const mountains = [
  'baker', 'stevens', 'crystal', 'snoqualmie', 'whitepass',
  'meadows', 'timberline', 'bachelor',
  'missionridge', 'fortynine', 'schweitzer', 'lookout',
  'ashland', 'willamette', 'hoodoo'
];

async function testPowderScore(mountainId) {
  try {
    const response = await fetch(`${BASE_URL}/api/mountains/${mountainId}/powder-score`);

    if (!response.ok) {
      console.log(`❌ ${mountainId}: HTTP ${response.status}`);
      return null;
    }

    const data = await response.json();

    console.log(`\n🏔️  ${data.mountain.name}`);
    console.log(`   Score: ${data.score.toFixed(1)}/10 - ${data.verdict}`);
    console.log(`   Data Sources:`);
    console.log(`      SNOTEL: ${data.dataAvailable.snotel ? '✅' : '❌'}`);
    console.log(`      NOAA Basic: ${data.dataAvailable.noaa ? '✅' : '❌'}`);
    console.log(`      NOAA Extended: ${data.dataAvailable.noaaExtended ? '✅' : '❌'}`);
    console.log(`      Open-Meteo: ${data.dataAvailable.openMeteo ? '✅' : '❌'}`);

    console.log(`   Conditions:`);
    console.log(`      Fresh Snow (24h): ${data.conditions.snowfall24h}"`);
    console.log(`      Recent Snow (48h): ${data.conditions.snowfall48h}"`);
    console.log(`      Temperature: ${data.conditions.temperature}°F`);
    console.log(`      Wind: ${data.conditions.windSpeed} mph${data.conditions.windGust ? ` (gusts ${data.conditions.windGust})` : ''}`);
    console.log(`      Upcoming Snow: ${data.conditions.upcomingSnow.toFixed(1)}"`);

    if (data.conditions.visibility !== null) {
      console.log(`      Visibility: ${data.conditions.visibility.toFixed(1)} mi (${data.conditions.visibilityCategory})`);
    }
    if (data.conditions.skyCover !== null) {
      console.log(`      Sky Cover: ${data.conditions.skyCover}%`);
    }
    if (data.conditions.humidity !== null) {
      console.log(`      Humidity: ${data.conditions.humidity}%`);
    }

    console.log(`   Score Factors:`);
    data.factors.forEach(f => {
      const indicator = f.isPositive ? '✅' : '⚠️ ';
      console.log(`      ${indicator} ${f.name}: ${f.contribution.toFixed(2)} (${f.description})`);
    });

    return {
      mountainId,
      score: data.score,
      dataAvailable: data.dataAvailable,
      hasExtendedData: data.dataAvailable.noaaExtended,
      factorCount: data.factors.length,
    };
  } catch (error) {
    console.log(`❌ ${mountainId}: ${error.message}`);
    return null;
  }
}

async function main() {
  console.log('╔════════════════════════════════════════════════════════════════╗');
  console.log('║     Enhanced Powder Score Test - All 15 Mountains             ║');
  console.log('╚════════════════════════════════════════════════════════════════╝');
  console.log('\nStarting local dev server test...');
  console.log('Make sure `npm run dev` is running!\n');

  const results = [];

  for (const mountainId of mountains) {
    const result = await testPowderScore(mountainId);
    if (result) results.push(result);
    await new Promise(r => setTimeout(r, 500)); // Rate limiting
  }

  console.log('\n╔════════════════════════════════════════════════════════════════╗');
  console.log('║                        TEST SUMMARY                           ║');
  console.log('╚════════════════════════════════════════════════════════════════╝\n');

  const successful = results.length;
  const withExtended = results.filter(r => r.hasExtendedData).length;
  const avgScore = results.reduce((sum, r) => sum + r.score, 0) / results.length;
  const maxFactors = Math.max(...results.map(r => r.factorCount));

  console.log(`✅ Successful: ${successful}/${mountains.length}`);
  console.log(`📊 With Extended Weather.gov Data: ${withExtended}/${successful}`);
  console.log(`⭐ Average Powder Score: ${avgScore.toFixed(1)}/10`);
  console.log(`📈 Max Score Factors: ${maxFactors}`);

  if (withExtended === successful) {
    console.log('\n✅ EXCELLENT - All mountains using enhanced weather.gov data!');
  } else if (withExtended > 0) {
    console.log('\n⚠️  PARTIAL - Some mountains missing extended weather.gov data');
  } else {
    console.log('\n❌ ISSUE - No extended weather.gov data retrieved');
  }

  console.log('\n📝 Note: Scores reflect current conditions and may vary by season');
}

main().catch(console.error);
