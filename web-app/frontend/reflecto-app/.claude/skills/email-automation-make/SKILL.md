---
name: email-automation-make
description: Sets up automated email notifications using Make.com (Integromat) webhooks for both logged-in users (daily event, weather & outfit digest) and guest demo users (lead capture modal + instant welcome & outfit recap).
---

# 🏷️ Skill: Automatisation des Notifications par E-mail via Make (Integromat)

## 📌 Rôle & Contexte
Ce skill guide Claude Code pour intégrer un système d'envoi d'e-mails automatisé et intelligent pour **Reflecto** en s'appuyant sur des webhooks **Make.com** (Integromat), couvrant à la fois les utilisateurs enregistrés et les visiteurs du portail public.

---

## 🎯 Objectifs
1. **Flow Utilisateur Connecté** : Automatiser l'envoi de rappels matinaux contenant les événements de l'agenda, la météo locale et la suggestion de tenue du jour.
2. **Flow Portail Public / Démo** : Intégrer une modale élégante de capture d'e-mail à la fin du scan pour envoyer un e-mail de bienvenue instantané avec le récapitulatif de la tenue suggérée.
3. **Architecture Webhook Make** : Créer un service robuste `notification-service.ts` avec validation d'email, payloads structurés et gestion des erreurs non-bloquante.

---

## 🛠️ Instructions d'Exécution Pas-à-Pas

### Étape 1 : Création du Service de Notification (`lib/services/notification-service.ts`)
Créer un service TypeScript gérant les appels HTTP vers les webhooks Make :
```typescript
export interface DailyDigestPayload {
  type: "daily_digest";
  user_email: string;
  user_name: string;
  weather: { temp: number; condition: string; advice: string; location: string };
  events: Array<{ title: string; time: string; type: string }>;
  recommended_outfit: {
    name: string;
    description: string;
    context: string;
    image_url: string;
    tags: string[];
    match: number;
  };
}

export interface GuestWelcomePayload {
  type: "guest_welcome_and_recap";
  user_email: string;
  event_context: string;
  detected_profile: {
    gender: string;
    morphology: string;
    skin_tone: string;
  };
  weather: { temp: number; condition: string; location: string };
  recommended_outfit: {
    name: string;
    description: string;
    image_url: string;
    match: number;
  };
}

export async function sendNotificationWebhook(
  payload: DailyDigestPayload | GuestWelcomePayload
): Promise<{ success: boolean; error?: string }>;
```

### Étape 2 : Modale de Capture d'Email pour le Portail Public (Guest)
- Créer un composant UI `components/ui/EmailCaptureModal.tsx` avec style Glassmorphism :
  - Déclenchée après l'affichage des 3 recommandations dans le flux public.
  - Message : *"Recevez le récapitulatif de votre tenue et vos conseils personnalisés par email !"*.
  - Champ de saisie d'email avec validation regex.
  - Bouton *"Envoyer mon récapitulatif"* (avec spinner de chargement et notification toast de succès).
  - Possibilité de fermer / ignorer facilement sans bloquer la navigation.

### Étape 3 : Route API Backend pour l'Envoi Sécurisé (`/api/notifications/send`)
- Créer une API Route Next.js pour relayer la requête vers Make.com de manière sécurisée sans exposer l'URL du Webhook côté client.
- Utiliser la variable d'environnement `MAKE_WEBHOOK_URL`.
- Inclure un rate-limiting simple ou une vérification pour éviter le spam.

### Étape 4 : Déclenchement Automatisé pour les Utilisateurs Connectés
- Créer une API Route `/api/cron/daily-digest` ou un trigger Supabase :
  - Peut être appelé par un cron externe (ex. Vercel Cron, GitHub Actions, ou planificateur Make).
  - Parcourt les utilisateurs actifs ayant activé les notifications par email dans leurs paramètres.
  - Génère et transmet le payload `DailyDigestPayload` à Make.

### Étape 5 : Spécification du Scénario Make.com
Documenter précisément les modules à configurer dans Make :
1. **Module 1 : Custom Webhook** $\to$ Réception du JSON.
2. **Module 2 : Router** (Filtre sur `type === "daily_digest"` vs `type === "guest_welcome_and_recap"`).
3. **Module 3 : Email / Gmail / SendGrid / Resend** :
   - Template HTML responsive avec le logo Reflecto, la météo, la photo de la tenue et les conseils de style.

---

## 📋 Livrable Obligatoire
À la fin de l'exécution, générer un fichier **`WALKTHROUGH_SKILL_3.md`** à la racine contenant :
- [ ] Le schéma JSON des payloads envoyés à Make.
- [ ] Le guide de configuration étape par étape du scénario Make.com.
- [ ] Le test de la modale de capture d'email sur le portail public.
- [ ] Le test d'envoi du digest quotidien pour utilisateur connecté.
