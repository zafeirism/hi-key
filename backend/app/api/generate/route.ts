import { NextResponse } from 'next/server';
import { withAuth } from '@/lib/auth/jwt';

// Main endpoint for AI image generation
// iOS app will POST to this with: { prompt: string, user_id: string }
// Returns: { generation_id: string, images: string[] }

export const POST = withAuth(async (request, user) => {
  const body = await request.json();
  const { prompt, session_id, request_id } = body;

  if (!prompt || !session_id || !request_id) {
    return NextResponse.json(
      { error: 'prompt, session_id, and request_id are required' },
      { status: 400 }
    );
  }
  // user.id, user.email, user.user_metadata are all available
  console.log('User:', user.id, user.email);

  // TODO:
  // 1. Verify Supabase JWT token
  // 2. Check user's subscription status via RevenueCat
  // 3. Analyze prompt with OpenAI (gpt-4o-mini)
  // 4. Trigger parallel image generation on Replicate
  // 5. Upload images to Cloudflare R2
  // 6. Store metadata in Supabase
  // 7. Return image URLs to iOS app

  return NextResponse.json({
    message: 'Generation endpoint ready',
    user_id: user.id,
    user_email: user.email,
    prompt,
    session_id,
    request_id,
  });
});
