import { supabaseAdmin } from '@/lib/supabase/server';

export type Profile = {
  name: string | null;
  referral_code: string | null;
  referred_by: string | null;
  double_credits: boolean;
  sub_credits_mills: number;
  extra_credits_mills: number;
  active_sub_product_id: string | null;
};

export async function getProfile(userId: string): Promise<Profile> {
  const { data, error } = await supabaseAdmin
    .from('user_profiles')
    .select(
      'name, referral_code, referred_by, double_credits, sub_credits_mills, extra_credits_mills, active_sub_product_id'
    )
    .eq('user_id', userId)
    .maybeSingle();

  if (error) throw error;

  return {
    name: data?.name ?? null,
    referral_code: data?.referral_code ?? null,
    referred_by: data?.referred_by ?? null,
    double_credits: data?.double_credits ?? false,
    sub_credits_mills: data?.sub_credits_mills ?? 0,
    extra_credits_mills: data?.extra_credits_mills ?? 0,
    active_sub_product_id: data?.active_sub_product_id ?? null,
  };
}
