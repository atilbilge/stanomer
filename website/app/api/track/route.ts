// website/app/api/track/route.ts
import handler from "../../../../api/track";

export const config = {
  runtime: "edge",
};

export async function GET(req: Request) {
  return handler(req);
}

export async function HEAD(req: Request) {
  return handler(req);
}

export async function OPTIONS(req: Request) {
  return handler(req);
}
