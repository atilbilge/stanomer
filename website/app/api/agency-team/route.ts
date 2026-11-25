// website/app/api/agency-team/route.ts
// Local Next.js App Router bridge for /api/agency-team (mirrors root api/agency-team.ts for Vercel)
import { handler } from "../../../../api/agency-team";

export async function POST(request: Request) {
  return handler(request);
}

export async function PATCH(request: Request) {
  return handler(request);
}

export async function DELETE(request: Request) {
  return handler(request);
}

export async function OPTIONS(request: Request) {
  return handler(request);
}
