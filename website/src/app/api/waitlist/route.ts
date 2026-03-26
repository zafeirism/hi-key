import { NextRequest, NextResponse } from "next/server";
import { getSupabase } from "@/lib/supabase";
import { getRatelimit } from "@/lib/ratelimit";
import { getResend } from "@/lib/resend";

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const email = (body.email as string)?.trim().toLowerCase();

    if (!email || !EMAIL_REGEX.test(email)) {
      return NextResponse.json(
        { error: "Please enter a valid email address." },
        { status: 400 },
      );
    }

    const ip =
      request.headers.get("x-forwarded-for")?.split(",")[0] ?? "127.0.0.1";
    const { success } = await getRatelimit().limit(ip);
    if (!success) {
      return NextResponse.json(
        { error: "Too many requests. Please try again later." },
        { status: 429 },
      );
    }

    const referralSource = body.referralSource as string | undefined;

    const { error } = await getSupabase()
      .from("waitlist")
      .insert({ email, referral_source: referralSource ?? null });

    if (error) {
      // Unique violation — email already exists
      if (error.code === "23505") {
        return NextResponse.json({ success: true });
      }
      console.error("Supabase insert error:", error);
      return NextResponse.json(
        { error: "Something went wrong. Please try again." },
        { status: 500 },
      );
    }

    // Fire-and-forget confirmation email (only for new signups)
    getResend()
      .emails.send({
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
      })
      .catch((err) => console.error("Resend error:", err));

    return NextResponse.json({ success: true });
  } catch {
    return NextResponse.json(
      { error: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }
}
