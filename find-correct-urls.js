/**
 * Find correct OnTheSnow URLs for broken scrapers
 */

const brokenScrapers = [
  { id: 'whitepass', name: 'White Pass', current: 'https://www.onthesnow.com/washington/white-pass/skireport', guesses: [
    'https://www.onthesnow.com/washington/white-pass-ski-area/skireport',
    'https://www.onthesnow.com/washington/white-pass-resort/skireport'
  ]},
  { id: 'meadows', name: 'Mt. Hood Meadows', current: 'https://www.onthesnow.com/oregon/mt-hood-meadows/skireport', guesses: [
    'https://www.onthesnow.com/oregon/mount-hood-meadows/skireport',
    'https://www.onthesnow.com/oregon/hood-meadows/skireport'
  ]},
  { id: 'bachelor', name: 'Mt. Bachelor', current: 'https://www.onthesnow.com/oregon/mt-bachelor/skireport', tested: true, works: true },
  { id: 'fortynine', name: '49 Degrees North', current: 'https://www.onthesnow.com/washington/49-degrees-north/skireport', tested: false },
  { id: 'schweitzer', name: 'Schweitzer', current: 'https://www.onthesnow.com/idaho/schweitzer/skireport', guesses: [
    'https://www.onthesnow.com/idaho/schweitzer-mountain/skireport',
    'https://www.onthesnow.com/idaho/schweitzer-mountain-resort/skireport'
  ]},
  { id: 'lookout', name: 'Lookout Pass', current: 'https://www.onthesnow.com/idaho/lookout-pass-ski-area/skireport', tested: false },
  { id: 'ashland', name: 'Mt. Ashland', current: 'https://www.onthesnow.com/oregon/mount-ashland/skireport', tested: false },
  { id: 'willamette', name: 'Willamette Pass', current: 'https://www.onthesnow.com/oregon/willamette-pass/skireport', tested: false },
  { id: 'hoodoo', name: 'Hoodoo', current: 'https://www.onthesnow.com/oregon/hoodoo-ski-area/skireport', tested: false },
];

async function testUrl(url) {
  try {
    const response = await fetch(url, { method: 'HEAD' });
    return response.ok;
  } catch (error) {
    return false;
  }
}

async function findCorrectUrls() {
  console.log('Finding correct OnTheSnow URLs...\n');

  for (const scraper of brokenScrapers) {
    console.log(`${scraper.name} (${scraper.id}):`);
    console.log(`  Current: ${scraper.current}`);

    // Test current URL
    const currentWorks = await testUrl(scraper.current);
    console.log(`  Current URL works: ${currentWorks ? '✅' : '❌'}`);

    // Test guesses if any
    if (scraper.guesses && !currentWorks) {
      for (const guess of scraper.guesses) {
        const works = await testUrl(guess);
        console.log(`  ${works ? '✅' : '❌'} ${guess}`);
        if (works) {
          console.log(`  → USE THIS URL`);
          break;
        }
      }
    }

    console.log('');
  }
}

findCorrectUrls();
