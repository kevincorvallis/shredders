/**
 * Scraper alerting system
 * Sends alerts when scraper performance degrades or fails
 */

export type AlertType = 'failure' | 'degraded' | 'recovered';

export interface AlertParams {
  type: AlertType;
  successRate: number;
  failedMountains: string[];
  runId: string;
}

/**
 * Send alert to configured channels (Slack, email, etc.)
 */
export async function sendScraperAlert(params: AlertParams): Promise<void> {
  const { type, successRate, failedMountains, runId } = params;

  // Skip alert if success rate is acceptable for degraded status
  if (type === 'degraded' && successRate >= 80) {
    return;
  }

  const message = {
    failure: `🚨 Scraper Run Failed (${Math.round(successRate)}% success)`,
    degraded: `⚠️  Scraper Performance Degraded (${Math.round(successRate)}% success)`,
    recovered: `✅ Scraper Recovered (${Math.round(successRate)}% success)`,
  }[type];

  const details = [
    `*${message}*`,
    ``,
    `Run ID: \`${runId}\``,
    `Success Rate: ${Math.round(successRate)}%`,
    `Failed Mountains: ${failedMountains.length > 0 ? failedMountains.join(', ') : 'None'}`,
  ].join('\n');

  // Send to Slack if configured
  if (process.env.SLACK_WEBHOOK_URL) {
    await sendSlackAlert(message, details);
  }

  // Send to email if configured
  if (process.env.ALERT_EMAIL_TO) {
    await sendEmailAlert(message, details);
  }

  console.log(`[Alert] Sent ${type} alert for run ${runId}`);
}

/**
 * Send alert to Slack webhook
 */
async function sendSlackAlert(message: string, details: string): Promise<void> {
  try {
    const response = await fetch(process.env.SLACK_WEBHOOK_URL!, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        text: message,
        blocks: [
          {
            type: 'section',
            text: {
              type: 'mrkdwn',
              text: details,
            },
          },
        ],
      }),
    });

    if (!response.ok) {
      console.error('[Alert] Failed to send Slack alert:', response.statusText);
    }
  } catch (error) {
    console.error('[Alert] Error sending Slack alert:', error);
  }
}

/**
 * Send alert via email
 * Note: Requires email service configuration (SendGrid, Resend, etc.)
 */
async function sendEmailAlert(subject: string, body: string): Promise<void> {
  // Placeholder for email integration
  // You would integrate with your preferred email service here
  console.log('[Alert] Email alerts not yet configured');
  console.log(`[Alert] Would send email: ${subject}`);

  // Example with SendGrid (requires @sendgrid/mail package):
  /*
  if (process.env.SENDGRID_API_KEY) {
    const sgMail = require('@sendgrid/mail');
    sgMail.setApiKey(process.env.SENDGRID_API_KEY);

    const msg = {
      to: process.env.ALERT_EMAIL_TO,
      from: process.env.ALERT_EMAIL_FROM,
      subject,
      text: body,
      html: body.replace(/\n/g, '<br>'),
    };

    await sgMail.send(msg);
  }
  */
}
