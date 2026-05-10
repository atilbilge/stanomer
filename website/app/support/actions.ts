"use server";

export async function sendToNotion(formData: FormData) {
  const notionToken = process.env.NOTION_TOKEN;
  const databaseId = process.env.NOTION_DATABASE_ID;

  if (!notionToken || !databaseId) {
    console.error("Notion credentials not configured in environment variables");
    return { success: false, error: "System configuration error" };
  }

  const subject = formData.get("subject") as string;
  const email = formData.get("email") as string;
  const category = formData.get("category") as string;
  const message = formData.get("message") as string;

  if (!subject || !email || !message) {
    return { success: false, error: "Missing fields" };
  }

  try {
    const dateStr = new Date().toISOString().split('T')[0];
    
    const body = {
      parent: { database_id: databaseId },
      properties: {
        'Subject': {
          title: [
            {
              text: { content: subject }
            }
          ]
        },
        'User Email': { email: email },
        'Category': {
          rich_text: [
            {
              text: { content: category }
            }
          ]
        },
        'Message': {
          rich_text: [
            {
              text: { content: message }
            }
          ]
        },
        'Status': {
          rich_text: [
            {
              text: { content: 'Open' }
            }
          ]
        },
        'Priority': {
          rich_text: [
            {
              text: { content: 'Normal' }
            }
          ]
        },
        'Platform': {
          rich_text: [
            {
              text: { content: 'Web' }
            }
          ]
        },
        'App Version': {
          rich_text: [
            {
              text: { content: '1.0.0 (Web)' }
            }
          ]
        },
        'Created Date': {
          date: { start: dateStr }
        }
      }
    };

    const response = await fetch('https://api.notion.com/v1/pages', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${notionToken}`,
        'Notion-Version': '2022-06-28',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    if (response.ok) {
      return { success: true };
    } else {
      const errorData = await response.json();
      console.error('Notion API Error:', errorData);
      return { success: false, error: errorData.message || 'Failed to send to Notion' };
    }
  } catch (error) {
    console.error('Support Action Error:', error);
    return { success: false, error: 'Internal Server Error' };
  }
}
