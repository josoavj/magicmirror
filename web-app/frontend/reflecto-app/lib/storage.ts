import { createClient } from './supabase/client'

const BUCKET_NAME = 'reflecto-assets'

export async function uploadUserPhoto(userId: string, file: File, type: 'photos' | 'avatars' = 'photos') {
  const supabase = createClient()
  const fileExt = file.name.split('.').pop()
  const fileName = `${Math.random()}.${fileExt}`
  const filePath = `users/${userId}/${type}/${fileName}`

  const { data, error } = await supabase.storage
    .from(BUCKET_NAME)
    .upload(filePath, file, { upsert: true })

  if (error) {
    console.error('Error uploading file:', error)
    throw error
  }

  return data
}

export function getUserAvatar(userId: string, path: string) {
  const supabase = createClient()
  
  const { data } = supabase.storage
    .from(BUCKET_NAME)
    .getPublicUrl(`users/${userId}/avatars/${path}`)

  return data.publicUrl
}
