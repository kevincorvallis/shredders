import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, QueryCommand } from '@aws-sdk/lib-dynamodb';

// Initialize DynamoDB client
const client = new DynamoDBClient({
  region: process.env.AWS_REGION || 'us-west-2'
});

const ddb = DynamoDBDocumentClient.from(client);

export interface LiftStatus {
  mountainId: string;
  mountainName: string;
  isOpen: boolean;
  liftsOpen: number;
  liftsTotal: number;
  runsOpen: number;
  runsTotal: number;
  message: string | null;
  sourceUrl: string;
  scrapedAt: string;
  duration: number;
}

/**
 * Get the latest lift status for a mountain from DynamoDB
 * @param mountainId - The mountain ID (e.g., "crystal", "whistler")
 * @returns The latest lift status or null if not found
 */
export async function getLatestLiftStatus(
  mountainId: string
): Promise<LiftStatus | null> {
  try {
    const command = new QueryCommand({
      TableName: 'mountain-status',
      KeyConditionExpression: 'mountainId = :mountainId',
      ExpressionAttributeValues: {
        ':mountainId': mountainId,
      },
      ScanIndexForward: false, // Sort by scrapedAt DESC (newest first)
      Limit: 1, // Only get the latest
    });

    const response = await ddb.send(command);

    if (!response.Items || response.Items.length === 0) {
      return null;
    }

    const item = response.Items[0];

    return {
      mountainId: item.mountainId,
      mountainName: item.mountainName,
      isOpen: item.isOpen,
      liftsOpen: item.liftsOpen,
      liftsTotal: item.liftsTotal,
      runsOpen: item.runsOpen,
      runsTotal: item.runsTotal,
      message: item.message || null,
      sourceUrl: item.sourceUrl,
      scrapedAt: item.scrapedAt,
      duration: item.duration,
    };
  } catch (error) {
    console.error(`Error fetching lift status for ${mountainId}:`, error);
    return null;
  }
}

/**
 * Get lift status for multiple mountains in parallel
 * @param mountainIds - Array of mountain IDs
 * @returns Map of mountainId to LiftStatus
 */
export async function getBatchLiftStatus(
  mountainIds: string[]
): Promise<Map<string, LiftStatus>> {
  const results = await Promise.allSettled(
    mountainIds.map((id) => getLatestLiftStatus(id))
  );

  const statusMap = new Map<string, LiftStatus>();

  results.forEach((result, index) => {
    if (result.status === 'fulfilled' && result.value) {
      statusMap.set(mountainIds[index], result.value);
    }
  });

  return statusMap;
}
