# Effacement des données et suppression du compte

Les actions **Effacer mes données** et **Supprimer le compte** appellent la
fonction Supabase `account-data`. Cette fonction doit être déployée sur le
projet avant que les boutons de l’application puissent aboutir.

## Déploiement

1. Lier le dépôt au bon projet Supabase :

   ```sh
   supabase link --project-ref <reference-du-projet>
   ```

2. Vérifier dans les secrets Edge Functions que les variables Supabase
   injectées sont disponibles (`SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEYS` et
   `SUPABASE_SECRET_KEYS`). La fonction prend la clé `default` des deux
   dictionnaires et conserve une compatibilité avec les anciennes variables
   `SUPABASE_ANON_KEY` et `SUPABASE_SERVICE_ROLE_KEY`. La clé secrète doit
   rester côté serveur et ne doit jamais être ajoutée à Flutter ou à
   `assets/.env`.

3. Appliquer le schéma documenté dans
   [`docs/sql/supabase_full_setup.sql`](sql/supabase_full_setup.sql), puis
   déployer la fonction :

   ```sh
   supabase functions deploy account-data
   ```

`supabase/config.toml` garde la vérification JWT activée. La fonction valide
l’identité du compte, exige une authentification récente par mot de passe
(moins de cinq minutes), efface les fichiers d’avatar et les lignes associées à
l’utilisateur. La suppression de compte passe ensuite par l’API Admin Supabase
depuis le serveur.

## Données effacées

Les deux actions effacent l’avatar, le profil (favoris inclus), l’agenda, les
retours de tenues et les lignes de scores ML/LLM associées à l’utilisateur. Le
client efface également les données locales du profil, les favoris, la
personnalisation, la télémétrie locale, la file hors ligne, les caches météo,
la ville enregistrée et les journaux locaux.

- **Effacer mes données** conserve l’utilisateur Auth et son adresse e-mail.
- **Supprimer le compte** supprime ensuite l’utilisateur Auth et termine la
  session locale.

Un échec réseau peut survenir après l’effacement de certaines catégories côté
serveur. Les opérations serveur sont conçues pour être répétables : l’utilisateur
peut se réauthentifier et relancer l’action. Avant toute mise en production,
vérifier le comportement sur un projet de test, y compris les erreurs de réseau,
la présence ou l’absence d’avatars et la suppression de toutes les tables.
