const { getEnabledConfigs } = require('./configs');
const { createScraper } = require('./scrapers');
const { saveToDynamoDB } = require('./utils');

exports.handler = async (event) => {
  console.log('Starting Lambda scraper');
  const results = [];
  const errors = [];

  const enabled = getEnabledConfigs();
  console.log(`Scraping ${enabled.length} mountains: ${enabled.map(c => c.id).join(', ')}`);

  // Scrape each mountain sequentially
  for (const config of enabled) {
    try {
      console.log(`[${config.id}] Creating ${config.type} scraper...`);
      const scraper = createScraper(config);

      console.log(`[${config.id}] Scraping...`);
      const result = await scraper.scrape();

      if (result.success) {
        results.push(result.data);
      } else {
        errors.push({ mountainId: config.id, error: result.error });
      }

    } catch (error) {
      errors.push({ mountainId: config.id, error: error.message });
      console.error(`[${config.id}] Fatal:`, error);
    }
  }

  // Save to DynamoDB
  if (results.length > 0) {
    try {
      await saveToDynamoDB(results);
    } catch (error) {
      console.error('DynamoDB save failed:', error);
      errors.push({ dynamodb: error.message });
    }
  }

  console.log(`Scraping complete: ${results.length} successful, ${errors.length} failed`);

  return {
    statusCode: results.length > 0 ? 200 : 500,
    body: JSON.stringify({
      success: results.length > 0,
      mountains: results.length,
      results,
      errors: errors.length > 0 ? errors : undefined,
    }),
  };
};
