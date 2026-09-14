import { createClient } from '@supabase/supabase-js'

// This client uses the service role key, DO NOT use it in the browser!
// It bypasses Row Level Security (RLS) entirely.
export const createAdminClient = () => {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    }
  )
}
