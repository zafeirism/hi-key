import { NextRequest, NextResponse } from 'next/server';
import { jwtVerify, createRemoteJWKSet } from 'jose';

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const JWKS_URL = new URL(`${SUPABASE_URL}/auth/v1/.well-known/jwks.json`);

// Create JWKS client - jose will fetch and cache the keys
const jwks = createRemoteJWKSet(JWKS_URL);

// Supabase JWT payload structure
interface SupabaseJWTPayload {
  sub: string; // user_id
  email?: string;
  phone?: string;
  app_metadata?: {
    provider?: string;
    providers?: string[];
  };
  user_metadata?: {
    full_name?: string;
    [key: string]: any;
  };
  role?: string;
  aal?: string;
  session_id?: string;
  exp?: number;
  iat?: number;
}

// Simplified User object for your handlers
export interface AuthUser {
  id: string;
  email?: string;
  phone?: string;
  user_metadata?: Record<string, any>;
  app_metadata?: Record<string, any>;
  role?: string;
}

/**
 * Higher-order function that wraps API routes with authentication
 * Usage:
 *
 * export const POST = withAuth(async (request, user) => {
 *   // user is already verified here
 *   return NextResponse.json({ user_id: user.id });
 * });
 */
export function withAuth(handler: (request: NextRequest, user: AuthUser) => Promise<NextResponse>) {
  return async (request: NextRequest) => {
    try {
      // Extract token
      const authHeader = request.headers.get('authorization');

      if (!authHeader) {
        return NextResponse.json({ error: 'Missing authorization header' }, { status: 401 });
      }

      const token = authHeader.replace('Bearer ', '');

      // Verify JWT using Supabase's JWKS endpoint
      const { payload } = await jwtVerify(token, jwks, {
        issuer: `${SUPABASE_URL}/auth/v1`,
        // Optionally add audience check if needed
        // audience: 'authenticated',
      });

      const supabasePayload = payload as SupabaseJWTPayload;

      // Check role is authenticated
      if (supabasePayload.role !== 'authenticated') {
        return NextResponse.json({ error: 'Invalid token role' }, { status: 401 });
      }

      // Build user object from JWT payload
      const user: AuthUser = {
        id: supabasePayload.sub,
        email: supabasePayload.email,
        phone: supabasePayload.phone,
        user_metadata: supabasePayload.user_metadata,
        app_metadata: supabasePayload.app_metadata,
        role: supabasePayload.role,
      };

      // Call the actual handler with verified user
      return handler(request, user);
    } catch (error) {
      // JWT verification failed (invalid, expired, or malformed)
      console.error('JWT verification failed:', error);
      return NextResponse.json({ error: 'Invalid or expired token' }, { status: 401 });
    }
  };
}
