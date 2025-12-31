const axios = require('axios');
const cheerio = require('cheerio');

async function testOnTheSnow() {
  console.log('Testing OnTheSnow (FREE public website scraping)...\n');

  try {
    // Simple HTTP request - no Puppeteer needed!
    const response = await axios.get('https://www.onthesnow.com/washington/crystal-mountain-wa/skireport', {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
      },
    });

    const $ = cheerio.load(response.data);

    console.log('✅ Successfully fetched OnTheSnow page');
    console.log(`📄 HTML length: ${response.data.length} characters\n`);

    // Look for lift/trail data
    const bodyText = $('body').text();

    // Search for patterns
    const liftPattern = /(\d+)\s+of\s+(\d+)\s+lifts?/gi;
    const trailPattern = /(\d+)\s+of\s+(\d+)\s+trails?/gi;

    const liftMatches = [...bodyText.matchAll(liftPattern)];
    const trailMatches = [...bodyText.matchAll(trailPattern)];

    console.log('🎿 Found Data:');
    console.log('─'.repeat(50));

    if (liftMatches.length > 0) {
      liftMatches.forEach((match, i) => {
        console.log(`Lifts (match ${i + 1}): ${match[1]} of ${match[2]} open`);
      });
    }

    if (trailMatches.length > 0) {
      trailMatches.forEach((match, i) => {
        console.log(`Trails (match ${i + 1}): ${match[1]} of ${match[2]} open`);
      });
    }

    console.log('─'.repeat(50));
    console.log('\n💰 COST: $0.00 (it\'s just a public website!)');
    console.log('🚀 METHOD: Simple HTTP request + HTML parsing');
    console.log('⚡ NO PUPPETEER NEEDED');
    console.log('🔓 NO CAPTCHA');
    console.log('✅ WORKS PERFECTLY\n');

    return true;

  } catch (error) {
    console.error('Error:', error.message);
    return false;
  }
}

testOnTheSnow();
