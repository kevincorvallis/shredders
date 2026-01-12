const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');

// Initialize DynamoDB client
const client = new DynamoDBClient({ region: process.env.AWS_REGION || 'us-west-2' });
const ddb = DynamoDBDocumentClient.from(client);

function parseRatio(text) {
  const match = text.match(/(\d+)\s*\/\s*(\d+)/);
  return match
    ? { open: parseInt(match[1], 10), total: parseInt(match[2], 10) }
    : { open: 0, total: 0 };
}

function extractPercentage(text) {
  const match = text.match(/(\d+)%/);
  return match ? parseInt(match[1], 10) : null;
}

async function saveToDynamoDB(data) {
  try {
    console.log(`Saving ${data.length} mountains to DynamoDB...`);

    for (const mountain of data) {
      const item = {
        mountainId: mountain.mountainId,
        scrapedAt: mountain.scrapedAt,
        mountainName: mountain.mountainName,
        isOpen: mountain.isOpen,
        liftsOpen: mountain.liftsOpen,
        liftsTotal: mountain.liftsTotal,
        runsOpen: mountain.runsOpen,
        runsTotal: mountain.runsTotal,
        message: mountain.message,
        sourceUrl: mountain.sourceUrl,
        duration: mountain.duration,
        ttl: Math.floor(Date.now() / 1000) + (90 * 24 * 60 * 60), // Expire after 90 days
      };

      const command = new PutCommand({
        TableName: 'mountain-status',
        Item: item,
      });

      await ddb.send(command);
      console.log(`✓ Saved ${mountain.mountainName} to DynamoDB`);
    }

    console.log('All data saved to DynamoDB successfully');
  } catch (error) {
    console.error('DynamoDB error:', error);
    throw error;
  }
}

module.exports = {
  parseRatio,
  extractPercentage,
  saveToDynamoDB,
};
