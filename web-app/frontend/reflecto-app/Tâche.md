DB Supabase : Reflecto (Diana's project)
Password : Fanilonombana8;&

Structure bucket : 
reflecto-assets/
├── users/
│   └── {user_id}/
│       ├── photos/
│       └── avatars/
├── outfits/
│   ├── casual/
│   ├── work/
│   └── events/
├── temp/


Schema DB : 
-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.events (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid,
  title text,
  type text,
  start_time timestamp with time zone,
  end_time timestamp with time zone,
  CONSTRAINT events_pkey PRIMARY KEY (id),
  CONSTRAINT events_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.history (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid,
  recommendation_id uuid,
  liked boolean DEFAULT false,
  viewed_at timestamp with time zone DEFAULT now(),
  CONSTRAINT history_pkey PRIMARY KEY (id),
  CONSTRAINT history_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT history_recommendation_id_fkey FOREIGN KEY (recommendation_id) REFERENCES public.recommendations(id)
);
CREATE TABLE public.interactions (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid,
  type text,
  message text,
  response text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT interactions_pkey PRIMARY KEY (id),
  CONSTRAINT interactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.outfits (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  name text,
  description text,
  category text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT outfits_pkey PRIMARY KEY (id)
);
CREATE TABLE public.profiles (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid UNIQUE,
  gender text,
  body_type text,
  skin_tone text,
  style_preference text,
  voice_enabled boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.recommendations (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid,
  outfit_id uuid,
  weather_id uuid,
  event_id uuid,
  context text,
  ai_prompt text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT recommendations_pkey PRIMARY KEY (id),
  CONSTRAINT recommendations_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT recommendations_outfit_id_fkey FOREIGN KEY (outfit_id) REFERENCES public.outfits(id),
  CONSTRAINT recommendations_weather_id_fkey FOREIGN KEY (weather_id) REFERENCES public.weather_context(id),
  CONSTRAINT recommendations_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id)
);
CREATE TABLE public.weather_context (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  temperature double precision,
  condition text,
  city text,
  fetched_at timestamp with time zone DEFAULT now(),
  CONSTRAINT weather_context_pkey PRIMARY KEY (id)
);



Anon public : <SUPABASE_ANON_KEY - voir .env.local>

Service role : <SUPABASE_SERVICE_ROLE_KEY - voir .env.local>

API URL : https://wuflmlvopkknqjnhsexa.supabase.co

llm api key = <OPENROUTER_API_KEY - voir .env.local>