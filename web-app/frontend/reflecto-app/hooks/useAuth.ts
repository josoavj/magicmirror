import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { useProfile } from './useProfile'
import type { User } from '@supabase/supabase-js'

export function useAuth() {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)
  const [authError, setAuthError] = useState<string | null>(null)
  const router = useRouter()
  const supabase = createClient()
  const { syncProfile } = useProfile()

  useEffect(() => {
    let mounted = true

    async function getUser() {
      const { data: { user } } = await supabase.auth.getUser()
      if (mounted) {
        setUser(user)
        setLoading(false)
      }
    }

    getUser()

    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (_event, session) => {
        if (mounted) {
          setUser(session?.user ?? null)
        }
      }
    )

    return () => {
      mounted = false
      subscription.unsubscribe()
    }
  }, [supabase.auth])

  const login = async (email: string, pass: string) => {
    setLoading(true)
    setAuthError(null)
    
    const { data: { user: signedInUser }, error } = await supabase.auth.signInWithPassword({
      email,
      password: pass,
    })

    if (error) {
      setAuthError(error.message)
      setLoading(false)
      return { success: false, error: error.message }
    }

    if (signedInUser) {
      const prof = await syncProfile(signedInUser.id)
      if (prof && !prof.onboarding_completed) {
        router.push('/onboarding')
      } else {
        router.push('/dashboard')
      }
      router.refresh()
      return { success: true }
    }

    setLoading(false)
    return { success: false, error: 'Failed to login' }
  }

  const signup = async (email: string, pass: string) => {
    setLoading(true)
    setAuthError(null)

    const { data: { user: signedUpUser }, error } = await supabase.auth.signUp({
      email,
      password: pass,
    })

    if (error) {
      setAuthError(error.message)
      setLoading(false)
      return { success: false, error: error.message }
    }

    if (signedUpUser) {
      try {
        await syncProfile(signedUpUser.id)
      } catch (e) {
        console.error("Signup sync error (probably handled by trigger):", e)
      }
      router.push('/onboarding')
      router.refresh()
      return { success: true }
    }

    setLoading(false)
    return { success: false, error: 'Registration failed' }
  }

  const logout = async () => {
    await supabase.auth.signOut()
    router.push('/login')
    router.refresh()
  }

  return { user, loading, authError, login, signup, logout }
}
