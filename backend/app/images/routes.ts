import { NextRequest, NextResponse } from 'next/server';

// Endpoint to fetch user's generated images
// GET /api/images?user_id=xxx&limit=20&offset=0

export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams;
    const userId = searchParams.get('user_id');
    const limit = parseInt(searchParams.get('limit') || '20');
    const offset = parseInt(searchParams.get('offset') || '0');

    if (!userId) {
      return NextResponse.json({ error: 'user_id is required' }, { status: 400 });
    }

    // TODO:
    // 1. Verify Supabase JWT token
    // 2. Query generations table from Supabase
    // 3. Return paginated results

    return NextResponse.json({ message: 'Images endpoint - to be implemented' }, { status: 501 });
  } catch (error) {
    console.error('Images fetch error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
