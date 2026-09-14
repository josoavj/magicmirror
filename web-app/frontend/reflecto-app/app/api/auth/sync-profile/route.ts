import { NextResponse } from 'next/server'
import { createAdminClient } from '@/lib/supabase/admin'

export async function POST(request: Request) {
  try {
    const { userId } = await request.json()
    
    if (!userId) {
      return NextResponse.json({ error: 'Missing userId' }, { status: 400 })
    }

    const adminSupabase = createAdminClient()

    // 2. Try to fetch the profile first
    let { data: profile, error: fetchError } = await adminSupabase
      .from('profiles')
      .select('*')
      .eq('user_id', userId)
      .single()

    // 3. If profile doesn't exist, try to insert it
    if (fetchError && (fetchError.code === 'PGRST116' || fetchError.code === '406')) {
      const { data: newProfile, error: insertError } = await adminSupabase
        .from('profiles')
        .insert([{ user_id: userId, onboarding_completed: false }])
        .select()
        .single()

      if (insertError) {
        // If it still fails with FK error, it might be a race condition with auth.users
        // or a genuine error. Try one last fetch in case the trigger worked.
        const { data: retryProfile } = await adminSupabase
          .from('profiles')
          .select('*')
          .eq('user_id', userId)
          .single()
        
        if (retryProfile) {
          profile = retryProfile
        } else {
          console.error('Insert error after fetch failed:', insertError)
          return NextResponse.json({ error: insertError.message }, { status: 500 })
        }
      } else {
        profile = newProfile
      }
    } else if (fetchError) {
      console.error('Fetch error:', fetchError)
      return NextResponse.json({ error: fetchError.message }, { status: 500 })
    }

    return NextResponse.json({ profile })
  } catch (error: any) {
    console.error('API Error syncing profile:', error)
    return NextResponse.json({ error: error.message }, { status: 500 })
  }
}
