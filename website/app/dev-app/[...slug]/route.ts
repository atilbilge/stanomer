import { NextRequest, NextResponse } from "next/server";
import fs from "fs";
import path from "path";

export async function GET(req: NextRequest) {
  try {
    const indexPath = path.join(process.cwd(), "public", "dev-app", "index.html");
    if (fs.existsSync(indexPath)) {
      const html = fs.readFileSync(indexPath, "utf-8");
      return new NextResponse(html, {
        headers: {
          "Content-Type": "text/html; charset=utf-8",
          "Cache-Control": "public, max-age=0, must-revalidate",
        },
      });
    }
  } catch (err) {
    console.error("Error serving dev-app index.html:", err);
  }
  return new NextResponse("Not Found", { status: 404 });
}
