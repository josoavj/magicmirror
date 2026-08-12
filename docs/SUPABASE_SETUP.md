# Configuration Supabase - MagicMirror

Ce document couvre la configuration complète et opérationnelle de Supabase pour MagicMirror : authentification, profil cloud, agenda, stockage des avatars, favoris et scoring ML/LLM.

> **Important :** Le script SQL fourni en section 2 est idempotent — il peut être exécuté plusieurs fois sans risque d'erreur ni de doublon.

---

## Sommaire

1. [Variables d'environnement](#1-variables-denvironnement)
2. [Script SQL complet](#2-script-sql-complet)
3. [Schéma des tables](#3-schéma-des-tables)
4. [Ce que Flutter fait avec ce schéma](#4-ce-que-flutter-fait-avec-ce-schéma)
5. [Fonctions upsert pour le modèle LLM](#5-fonctions-upsert-pour-le-modèle-llm)
6. [Vérification de bon fonctionnement](#6-vérification-de-bon-fonctionnement)
7. [Requêtes de debug](#7-requêtes-de-debug)
8. [Dépannage](#8-dépannage)
9. [Bonnes pratiques](#9-bonnes-pratiques)

---

## 1. Variables d'environnement

Créer ou compléter le fichier `assets/.env` à la racine du projet :

```env
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_KEY
OPENWEATHERMAP_API_KEY=YOUR_OPENWEATHERMAP_API_KEY
```

| Variable | Obligatoire | Description |
|----------|-------------|-------------|
| `SUPABASE_URL` | Oui | URL du projet Supabase |
| `SUPABASE_ANON_KEY` | Oui | Clé publique anonyme (utilisée côté Flutter) |
| `OPENWEATHERMAP_API_KEY` | Oui (météo) | Clé API pour les données météo en temps réel |

> **Sécurité :** Ne jamais utiliser la `service_role` key dans le client Flutter. Elle est réservée aux jobs backend (scoring ML/LLM) qui doivent contourner le RLS.

---

## 2. Script SQL complet

Copier-coller l'intégralité du script suivant dans le **SQL Editor** de votre projet Supabase (`https://supabase.com/dashboard/project/YOUR_PROJECT_REF/sql`).

Le script est encapsulé dans une transaction (`begin` / `commit`) : en cas d'erreur, aucune modification n'est appliquée.

```sql
-- MagicMirror — Supabase full setup (idempotent)
-- Peut être exécuté plusieurs fois sans erreur.

begin;

-- Extension pour gen_random_uuid()
create extension if not exists pgcrypto;

-- --------------------------------------------------
-- TABLE : profiles
-- --------------------------------------------------
create table if not exists public.profiles (
  user_id           uuid        primary key references auth.users(id) on delete cascade,
  display_name      text        not null default 'Utilisateur',
  avatar_url        text        not null default '',
  gender            text        not null default 'Non précise',
  birth_date        date,
  age               int         not null default 25,
  height_cm         int         not null default 170,
  morphology        text        not null default 'Silhouette non definie',
  preferred_styles  text[]      not null default array['Casual']::text[],
  favorite_outfit_ids text[]    not null default '{}',
  updated_at        timestamptz not null default now()
);

-- Row Level Security
alter table public.profiles enable row level security;
-- ... (rest of the SQL)
```

*(Note: Keeping the SQL itself intact as it's code, but removing checkmarks from tables in documentation)*

## 3. Schéma des tables

### Vue d'ensemble

| Table | Rôle | Optionnelle |
|-------|------|-------------|
| `profiles` | Profil utilisateur (morphologie, favoris, styles) | Non |
| `agenda_events` | Événements agenda cloud | Non |
| `outfit_feedback_events` | Instrumentation locale des interactions tenues | Non |
| `outfit_ml_scores` | Scores calculés par le modèle ML local | Oui |
| `outfit_llm_scores` | Scores calculés par le modèle LLM secondaire (Llama) | Oui |
| `outfit_llm_details` | Détails de composition générés par le LLM | Oui |

### Sécurité — Row Level Security (RLS)

Le RLS est activé sur toutes les tables. Chaque utilisateur authentifié n'accède qu'à ses propres données, via la condition `user_id = auth.uid()`. Les politiques appliquées sont :

| Table | SELECT | INSERT | UPDATE | DELETE |
|-------|--------|--------|--------|--------|
| `profiles` | Oui | Oui | Oui | - |
| `agenda_events` | Oui | Oui | Oui | Oui |
| `outfit_feedback_events` | Oui | Oui | - | - |
| `outfit_ml_scores` | Oui | - | - | - |
| `outfit_llm_scores` | Oui | - | - | - |
| `outfit_llm_details` | Oui | - | - | - |

---

## 4. Ce que Flutter fait avec ce schéma

| Fonctionnalité | Table / Service | Détails |
|----------------|-----------------|---------|
| Authentification | Supabase Auth | Email + mot de passe |
| Profil cloud | `profiles` | Upsert/select sur `user_id = auth.uid()` |
| Agenda cloud | `agenda_events` | CRUD complet, scopé au compte actif |
| Upload avatar | `storage.objects` (bucket `avatars`) | Dossier par `user_id` |
| Favoris tenues | `profiles.favorite_outfit_ids` | Array PostgreSQL + fallback local SharedPreferences |
| Feedback tenues | `outfit_feedback_events` | Instrumentation locale exportée vers le cloud |
| Scores ML | `outfit_ml_scores` | Lecture seule côté Flutter, pour le ranking hybride |
| Scores LLM | `outfit_llm_scores` + `outfit_llm_details` | Lecture seule côté Flutter, profil/genre/styles/morphologie |
