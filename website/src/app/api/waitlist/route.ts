import { NextRequest, NextResponse } from "next/server";
import { getSupabase } from "@/lib/supabase";
import { getRatelimit } from "@/lib/ratelimit";
import { getResend } from "@/lib/resend";

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export async function POST(request: NextRequest) {
  const requestId = Math.random().toString(36).slice(2, 10);
  const log = (msg: string, extra?: Record<string, unknown>) =>
    console.log(`[waitlist:${requestId}] ${msg}`, extra ?? "");

  log("request received");

  try {
    const body = await request.json();
    const email = (body.email as string)?.trim().toLowerCase();
    log("parsed body");

    if (!email || !EMAIL_REGEX.test(email)) {
      log("validation failed");
      return NextResponse.json(
        { error: "Please enter a valid email address." },
        { status: 400 },
      );
    }

    const ip =
      request.headers.get("x-forwarded-for")?.split(",")[0] ?? "127.0.0.1";
    const { success } = await getRatelimit().limit(ip);
    log("ratelimit check", { ip, success });
    if (!success) {
      return NextResponse.json(
        { error: "Too many requests. Please try again later." },
        { status: 429 },
      );
    }

    const referralSource = body.referralSource as string | undefined;

    log("inserting into supabase");
    const { error } = await getSupabase()
      .from("waitlist")
      .insert({ email, referral_source: referralSource ?? null });

    if (error) {
      // Unique violation — email already exists
      if (error.code === "23505") {
        log("duplicate email, skipping confirmation email");
        return NextResponse.json({ success: true });
      }
      console.error(`[waitlist:${requestId}] supabase insert error:`, error);
      return NextResponse.json(
        { error: "Something went wrong. Please try again." },
        { status: 500 },
      );
    }

    log("supabase insert ok, sending confirmation email");

    // Awaited so the send completes before the serverless function freezes.
    // If email latency becomes a UX issue, switch to waitUntil() from
    // @vercel/functions to return early while the send runs in the background.
    try {
      const result = await getResend().emails.send({
        from: process.env.RESEND_FROM_EMAIL!,
        to: email,
        subject: "You're on the hi-key waitlist!",
        html: `
          <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; max-width: 480px; padding: 40px 20px;">
            <h1 style="font-size: 24px; font-weight: 600; color: #1a1a1a; margin: 0 0 16px 0;">You're in!</h1>
            <p style="font-size: 16px; color: #374151; line-height: 1.6; margin: 0 0 12px 0;">
              Thanks for joining the hi-key waitlist. As an early member, you'll get 2× credits forever. Every purchase, doubled.
            </p>
            <p style="font-size: 16px; color: #374151; line-height: 1.6; margin: 0 0 32px 0;">
              We'll let you know as soon as the app is ready for you. For product updates along the way, follow me on <a href="https://x.com/zafeirism" style="color: #374151; text-decoration: underline;">X/Twitter</a>.
            </p>
            <p style="font-size: 14px; color: #6b7280; margin: 0;">
              — zaf
            </p>
          </div>
        `,
      });
      log("resend send resolved", {
        id: result.data?.id,
        error: result.error,
      });
    } catch (err) {
      // Signup already succeeded in Supabase, so don't fail the request.
      console.error(`[waitlist:${requestId}] resend error:`, err);
    }

    log("returning success");
    return NextResponse.json({ success: true });
  } catch (err) {
    console.error(`[waitlist:${requestId}] unhandled error:`, err);
    return NextResponse.json(
      { error: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }
}
