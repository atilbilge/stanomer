export const config = {
  runtime: 'edge',
};

export default async function handler(req: Request) {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405 });
  }

  const body = await req.json();
  const { subject, email, category, message } = body;

  const notionToken = process.env.NOTION_TOKEN;
  const databaseId = process.env.NOTION_DATABASE_ID;

  if (!notionToken || !databaseId) {
    return new Response(JSON.stringify({ error: 'Notion credentials not configured' }), { status: 500 });
  }

  try {
    const response = await fetch("https://api.notion.com/v1/pages", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${notionToken}`,
        "Content-Type": "application/json",
        "Notion-Version": "2022-06-28",
      },
      body: JSON.stringify({
        parent: { database_id: databaseId },
        properties: {
          Subject: { title: [{ text: { content: subject } }] },
          'User Email': { email: email },
          Category: { rich_text: [{ text: { content: category } }] },
          Message: { rich_text: [{ text: { content: message } }] },
          Status: { rich_text: [{ text: { content: 'Open' } }] },
          Priority: { rich_text: [{ text: { content: 'Normal' } }] },
          Platform: { rich_text: [{ text: { content: 'Web' } }] },
          'App Version': { rich_text: [{ text: { content: '1.0.0' } }] },
          'Created Date': { date: { start: new Date().toISOString().split('T')[0] } },
        },
      }),
    });

    if (!response.ok) {
      const errorData = await response.json();
      console.error("Notion API error:", errorData);
      return new Response(JSON.stringify({ 
        error: 'Notion API error', 
        details: errorData.message || errorData 
      }), { status: response.status });
    }

    return new Response(JSON.stringify({ success: true }), { status: 200 });
  } catch (error) {
    console.error("Fetch error:", error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), { status: 500 });
  }
}
