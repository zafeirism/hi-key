export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.5"
  }
  public: {
    Tables: {
      credit_transactions: {
        Row: {
          created_at: string
          delta_extra_mills: number
          delta_sub_mills: number
          generation_id: string | null
          id: string
          reason: string
          source_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          delta_extra_mills?: number
          delta_sub_mills?: number
          generation_id?: string | null
          id?: string
          reason: string
          source_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          delta_extra_mills?: number
          delta_sub_mills?: number
          generation_id?: string | null
          id?: string
          reason?: string
          source_id?: string
          user_id?: string
        }
        Relationships: []
      }
      generations: {
        Row: {
          comments: Json | null
          copied_at: string | null
          cost_usd_mills: number | null
          created_at: string | null
          error_message: string | null
          file_extension: string | null
          file_size_bytes: number | null
          generation_duration_ms: number | null
          generation_started_at: string | null
          id: string
          improved_prompt: string | null
          model: string | null
          request_id: string | null
          reserved_usd_mills: number | null
          session_id: string | null
          shared_at: string | null
          status: string | null
          text_in_image: Json | null
          total_duration_ms: number | null
          upsampling_duration_ms: number | null
          user_id: string | null
          user_prompt: string | null
        }
        Insert: {
          comments?: Json | null
          copied_at?: string | null
          cost_usd_mills?: number | null
          created_at?: string | null
          error_message?: string | null
          file_extension?: string | null
          file_size_bytes?: number | null
          generation_duration_ms?: number | null
          generation_started_at?: string | null
          id: string
          improved_prompt?: string | null
          model?: string | null
          request_id?: string | null
          reserved_usd_mills?: number | null
          session_id?: string | null
          shared_at?: string | null
          status?: string | null
          text_in_image?: Json | null
          total_duration_ms?: number | null
          upsampling_duration_ms?: number | null
          user_id?: string | null
          user_prompt?: string | null
        }
        Update: {
          comments?: Json | null
          copied_at?: string | null
          cost_usd_mills?: number | null
          created_at?: string | null
          error_message?: string | null
          file_extension?: string | null
          file_size_bytes?: number | null
          generation_duration_ms?: number | null
          generation_started_at?: string | null
          id?: string
          improved_prompt?: string | null
          model?: string | null
          request_id?: string | null
          reserved_usd_mills?: number | null
          session_id?: string | null
          shared_at?: string | null
          status?: string | null
          text_in_image?: Json | null
          total_duration_ms?: number | null
          upsampling_duration_ms?: number | null
          user_id?: string | null
          user_prompt?: string | null
        }
        Relationships: []
      }
      user_balances: {
        Row: {
          extra_credits_mills: number
          sub_credits_mills: number
          updated_at: string
          user_id: string
        }
        Insert: {
          extra_credits_mills?: number
          sub_credits_mills?: number
          updated_at?: string
          user_id: string
        }
        Update: {
          extra_credits_mills?: number
          sub_credits_mills?: number
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      waitlist: {
        Row: {
          created_at: string
          email: string
          id: string
          referral_source: string | null
        }
        Insert: {
          created_at?: string
          email: string
          id?: string
          referral_source?: string | null
        }
        Update: {
          created_at?: string
          email?: string
          id?: string
          referral_source?: string | null
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      debit_credits: {
        Args: {
          p_amount_mills: number
          p_generation_id?: string
          p_reason: string
          p_source_id: string
          p_user_id: string
        }
        Returns: Json
      }
      grant_credits: {
        Args: {
          p_delta_extra_mills: number
          p_delta_sub_mills: number
          p_generation_id?: string
          p_reason: string
          p_source_id: string
          p_user_id: string
        }
        Returns: Json
      }
      reset_sub_credits: {
        Args: {
          p_reason: string
          p_source_id: string
          p_target_mills: number
          p_user_id: string
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const
