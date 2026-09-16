// website/app/api/scrape-agency-theme/route.ts
// Delegates to root api/scrape-agency-theme.ts for unified Brandfetch & Theme Scraping

import { handler } from "../../../../api/scrape-agency-theme";

export const config = {
  runtime: "edge",
};

export async function POST(req: Request) {
  return handler(req);
}

export async function OPTIONS(req: Request) {
  return handler(req);
}
