import { NextResponse } from 'next/server';

export const runtime = 'edge';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Content-Type': 'application/json',
};

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: corsHeaders });
}

export async function POST(req: Request) {
  try {
    const body = await req.json();
    const { subject, email, category, message, platform = 'Web', appVersion = '1.1.0' } = body;

    const notionToken = process.env.NOTION_TOKEN;
    const databaseId = process.env.NOTION_DATABASE_ID;

    if (!notionToken || !databaseId) {
      return NextResponse.json(
        { error: 'Notion credentials not configured' },
        { status: 500, headers: corsHeaders }
      );
    }

    const response = await fetch('https://api.notion.com/v1/pages', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${notionToken}`,
        'Content-Type': 'application/json',
        'Notion-Version': '2022-06-28',
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
          Platform: { rich_text: [{ text: { content: platform } }] },
          'App Version': { rich_text: [{ text: { content: appVersion } }] },
          'Created Date': { date: { start: new Date().toISOString().split('T')[0] } },
        },
      }),
    });

    if (!response.ok) {
      const errorData = await response.json();
      console.error('Notion API error:', errorData);
      return NextResponse.json(
        {
          error: 'Notion API error',
          details: errorData.message || errorData,
        },
        { status: response.status, headers: corsHeaders }
      );
    }

    return NextResponse.json({ success: true }, { status: 200, headers: corsHeaders });
  } catch (error) {
    console.error('Fetch error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500, headers: corsHeaders }
    );
  }
}
