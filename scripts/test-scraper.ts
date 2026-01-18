import { HTMLScraper } from '../src/lib/scraper/HTMLScraper';
import { scraperConfigs } from '../src/lib/scraper/configs';

// Test Stevens Pass scraper with OnTheSnow fallback
const config = scraperConfigs.stevens;
const scraper = new HTMLScraper(config);

console.log('Testing Stevens Pass scraper with OnTheSnow fallback...');
console.log(`URL: ${config.dataUrl}`);
console.log(`Selectors:`, JSON.stringify(config.selectors, null, 2));

scraper.scrape().then((result) => {
  console.log('\nResult:', JSON.stringify(result, null, 2));
  process.exit(result.success ? 0 : 1);
}).catch((error) => {
  console.error('\nError:', error);
  process.exit(1);
});
