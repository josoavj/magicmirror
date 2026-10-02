import { withSupabase } from 'npm:@supabase/server@1'

async function listAvatarPaths(admin: any, folder: string): Promise<string[]> {
  const paths: string[] = []
  const bucket = admin.storage.from('avatars')

  for (let offset = 0; ; offset += 100) {
    const { data, error } = await bucket.list(folder, { limit: 100, offset })
    if (error) throw error

    for (const entry of data ?? []) {
      const path = `${folder}/${entry.name}`
      if (entry.id == null) {
        paths.push(...await listAvatarPaths(admin, path))
      } else {
        paths.push(path)
      }
    }

    if (!data || data.length < 100) break
  }
  return paths
}

async function eraseUserData(admin: any, userId: string) {
  // Supabase Auth refuses account deletion while owned Storage objects remain.
  const avatarPaths = await listAvatarPaths(admin, userId)
  for (let i = 0; i < avatarPaths.length; i += 100) {
    const { error } = await admin.storage
      .from('avatars')
      .remove(avatarPaths.slice(i, i + 100))
    if (error) throw error
  }

  for (const table of [
    'agenda_events',
    'outfit_feedback_events',
    'outfit_ml_scores',
    'outfit_llm_scores',
    'outfit_llm_details',
    'profiles',
  ]) {
    const { error } = await admin.from(table).delete().eq('user_id', userId)
    if (error) throw error
  }
}

export default {
  fetch: withSupabase({ auth: 'user' }, async (request, context) => {
    if (request.method !== 'POST') {
      return Response.json({ error: 'Method not allowed' }, { status: 405 })
    }

    try {
      const userId = context.userClaims?.id
      const authTime = Number(context.jwtClaims?.auth_time)
      const now = Math.floor(Date.now() / 1000)
      const authMethods = Array.isArray(context.jwtClaims?.amr)
        ? context.jwtClaims.amr as Array<Record<string, unknown>>
        : []
      const hasRecentPasswordAuth = authMethods.some((method) => {
        const timestamp = Number(method.timestamp)
        return method.method === 'password' &&
          Number.isFinite(timestamp) &&
          timestamp <= now + 30 &&
          now - timestamp <= 300
      })
      if (!userId) {
        return Response.json({ error: 'Authentication required' }, { status: 401 })
      }
      if (
        !Number.isFinite(authTime) ||
        authTime > now + 30 ||
        now - authTime > 300 ||
        !hasRecentPasswordAuth
      ) {
        return Response.json(
          { error: 'Recent password verification required' },
          { status: 401 },
        )
      }

      const body = await request.json().catch(() => ({}))
      const action = body?.action
      if (action !== 'erase_data' && action !== 'delete_account') {
        return Response.json({ error: 'Unsupported action' }, { status: 400 })
      }

      const admin = context.supabaseAdmin
      await eraseUserData(admin, userId)

      if (action === 'erase_data') {
        const { data, error: getUserError } =
          await admin.auth.admin.getUserById(userId)
        if (getUserError || !data.user) throw getUserError ?? new Error('User not found')

        const metadata = { ...data.user.user_metadata }
        delete metadata.terms_accepted_at
        delete metadata.terms_version
        delete metadata.privacy_notice_version
        const { error } = await admin.auth.admin.updateUserById(userId, {
          user_metadata: metadata,
        })
        if (error) throw error
        return Response.json({ success: true, accountDeleted: false })
      }

      const { error: deleteError } = await admin.auth.admin.deleteUser(userId)
      if (deleteError) throw deleteError
      return Response.json({ success: true, accountDeleted: true })
    } catch (error) {
      console.error('account-data operation failed', error)
      return Response.json(
        { error: 'Unable to complete the account data request' },
        { status: 500 },
      )
    }
  }),
}
