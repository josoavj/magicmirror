import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'

export interface Profile {
  id: string
  user_id: string
  first_name: string | null
  age: number | null
  height_cm: number | null
  weight_kg: number | null
  gender: string | null
  body_type: string | null
  skin_tone: string | null
  style_preference: string | null
  voice_enabled: boolean
  onboarding_completed: boolean
  created_at: string
  updated_at: string
}

export function useProfile() {
  const supabase = createClient()
  const [profile, setProfile] = useState<Profile | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const syncProfile = async (userId: string) => {
    setLoading(true)
    setError(null)
    try {
      // Use the API route that utilizes the service role key to bypass RLS
      const res = await fetch('/api/auth/sync-profile', { 
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId })
      })
      const json = await res.json()
      
      if (!res.ok) {
        throw new Error(json.error || 'Failed to sync profile via API')
      }

      setProfile(json.profile)
      return json.profile
    } catch (err: any) {
      console.error('Error syncing profile:', err)
      setError(err.message)
      return null
    } finally {
      setLoading(false)
    }
  }

  const fetchProfile = async (userId: string) => {
    try {
      setLoading(true)
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('user_id', userId)
        .single()

      if (error) throw error
      setProfile(data)
      return data
    } catch (err: any) {
      console.error('Error fetching profile:', err)
      setError(err.message)
      return null
    } finally {
      setLoading(false)
    }
  }

  const updateProfile = async (userId: string, updates: Partial<Profile>) => {
    try {
      setLoading(true)
      const { data, error } = await supabase
        .from('profiles')
        .update({ ...updates, updated_at: new Date().toISOString() })
        .eq('user_id', userId)
        .select()
        .single()

      if (error) throw error
      setProfile(data)
      return data
    } catch (err: any) {
      console.error('Error updating profile:', err)
      setError(err.message)
      return null
    } finally {
      setLoading(false)
    }
  }

  return { profile, loading, error, syncProfile, fetchProfile, updateProfile }
}
