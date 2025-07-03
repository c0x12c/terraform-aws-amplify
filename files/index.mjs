// index.mjs

/**
 * This function is triggered by an AWS EventBridge rule when an AWS Amplify build job
 * changes state. It constructs and sends a notification message to a specified
 * Slack webhook URL.
 *
 * Environment Variables:
 * - SLACK_WEBHOOK_URL: The incoming webhook URL for your Slack channel.
 */

// In AWS Lambda Node.js 20.x runtime, fetch is available globally.
// No external dependency is needed.

/**
 * Returns an emoji and a descriptive message based on the job status.
 * @param {string} status - The status of the Amplify build job.
 * @returns {{emoji: string, message: string}} An object containing the emoji and message.
 */
function getStatusInfo(status) {
    switch (status) {
      case "SUCCEED":
        return { emoji: "✅", message: "succeeded 🎉" };
      case "FAILED":
        return { emoji: "❌", message: "failed 😢" };
      case "STARTED":
        return { emoji: "🚀", message: "started" };
      default:
        return { emoji: "ℹ️", message: status || "unknown" };
    }
  }
  
  /**
   * The main handler for the Lambda function.
   * @param {object} event - The event payload from AWS EventBridge.
   * @returns {Promise<{statusCode: number, body: string}>} The response object.
   */
  export const handler = async (event) => {
    // Retrieve Slack webhook URL from environment variables
    const SLACK_WEBHOOK_URL = process.env.SLACK_WEBHOOK_URL;
    const ENV = process.env.ENVIRONMENT;

    if (!SLACK_WEBHOOK_URL) {
      console.error("Error: SLACK_WEBHOOK_URL environment variable is not set.");
      return { statusCode: 500, body: "SLACK_WEBHOOK_URL is not configured." };
    }
  
    const { detail, region = "us-east-1" } = event;
    const { appId, branchName, jobId, jobStatus } = detail || {};
  
    // Construct the URL to view the build in the AWS Amplify Console
    const buildUrl = `https://${region}.console.aws.amazon.com/amplify/apps/${appId}/branches/${branchName}/deployments`;
  
    // Get appropriate status info (emoji and message)
    const { emoji, message } = getStatusInfo(jobStatus);
  
    // Create the Slack message payload using Block Kit for rich formatting
    const slackMessage = {
      text: `Amplify Build for ${branchName || "unknown branch"} ${message}`, // Fallback text for notifications
      blocks: [
        {
          type: "header",
          text: {
            type: "plain_text",
            text: `${emoji} Amplify Build ${ENV} ${message}`,
            emoji: true,
          },
        },
        {
          type: "section",
          fields: [
            { type: "mrkdwn", text: `*App Name:*\n\`${appId || "unknown"}\`` },
            { type: "mrkdwn", text: `*Branch:*\n\`${branchName || "unknown"}\`` },
            { type: "mrkdwn", text: `*Job ID:*\n\`${jobId || "unknown"}\`` },
            { type: "mrkdwn", text: `*Status:*\n*${message}*` },
          ],
        },
        {
          type: "actions",
          elements: [
            {
              type: "button",
              text: {
                type: "plain_text",
                text: "View Build Details",
                emoji: true,
              },
              style: "primary",
              url: buildUrl,
              action_id: "view_build_button" // action_id is required for buttons in actions blocks
            },
          ],
        },
        {
          type: "context",
          elements: [
              {
                  type: "mrkdwn",
                  text: `Occurred in region: ${region}`
              }
          ]
        }
      ],
    };
  
    try {
      // Send the message to Slack using the native fetch API
      const response = await fetch(SLACK_WEBHOOK_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(slackMessage),
      });
  
      if (!response.ok) {
        // If the response is not OK, throw an error to be caught by the catch block
        const errorText = await response.text();
        throw new Error(`Slack API error: ${response.status} ${errorText}`);
      }
  
      return { statusCode: 200, body: "Notification sent successfully." };
  
    } catch (error) {
      console.error("Failed to send message to Slack:", error);
      return { statusCode: 500, body: "Failed to send notification." };
    }
  };
  