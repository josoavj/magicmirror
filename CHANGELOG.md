# Changelog

Toutes les évolutions notables de Magic Mirror sont documentées dans ce fichier.

## [2026-03-31] - Migration agenda Supabase, comptes et documentation

### feat(agenda)
- Migration complète de l'agenda vers Supabase avec modèle enrichi (`userId`, `copyWith`, mapping DB).
- Nouveau service agenda Supabase avec opérations CRUD liées au compte actif.
- Refonte du provider agenda pour la gestion journalière, le rafraîchissement, la création, la mise à jour, la suppression et le statut terminé.
- Refonte de l'écran agenda: sélection de date, ajout, édition, suppression, marquage terminé.
- Mise à jour du widget HUD agenda pour les types d'événements utilisés côté app.

### feat(auth, account, profile)
- Ajout d'un flux d'authentification complet: connexion, inscription multi-étapes, vérification email, réinitialisation mot de passe.
- Intégration d'un `AuthGate` Supabase au démarrage de l'application.
- Ajout d'un écran dédié paramètres du compte (avatar, sécurité, synchronisation).
- Introduction du domaine profil utilisateur (modèle, provider, sync service, écran) avec persistance locale + synchronisation Supabase.
- Upload avatar vers Supabase Storage et synchronisation du profil cloud.

### feat(app, settings, outfit)
- Mise à jour du shell applicatif (`main.dart`) et des routes pour intégrer auth, profil et compte.
- Paramètres: accès direct aux paramètres du compte et wording agenda cloud Supabase.
- Suggestions de tenues: ranking personnalisé basé sur le profil utilisateur.

### refactor
- Suppression du mode fallback mock agenda dans la configuration applicative.

### chore(deps)
- Retrait des dépendances Google Calendar / Google Sign-In.
- Régénération du lockfile après migration des dépendances vers la pile Supabase.

### docs
- Ajout du guide complet Supabase (`profiles`, `avatars`, `agenda_events`, RLS).
- Mise à jour du README, de l'architecture, du guide de démarrage, de la doc caméra et du logging pour refléter la structure et les flux actuels.
- Mise à jour de l'écran About et des messages de démarrage vers une terminologie Supabase.

### removed
- Suppression du service Google Calendar legacy.
- Suppression du service mock calendrier legacy.

## [Archive] - Historique antérieur

Les entrées précédentes étaient centrées sur la phase Google Calendar/mock et ne reflètent plus l'architecture actuelle.
Cette archive a été remplacée par un changelog orienté état réel de l'application au 31/03/2026.
