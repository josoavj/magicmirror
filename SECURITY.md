# Politique de Sécurité — Magic Mirror

## Versions supportées

Les versions officielles en release (`1.0.0-beta`, `1.0.1-beta`) disposent des protections de base. La version actuelle/à venir (**`1.1.0-beta+`**) renforce considérablement la sécurité globale du projet par rapport aux versions précédentes.

| Version | Statut de sécurité | Supporté |
| ------- | ------------------ | -------- |
| `>= 1.1.0-beta` | Sécurité renforcée (RLS strict, chiffrement local, ProGuard R8) | Oui |
| `1.0.1-beta` | Sécurisé | Maintenance minimale |
| `1.0.0-beta` | Sécurisé | Obsolète |
| `< 1.0.0` | Incompatible | Non |

---

## Améliorations de sécurité majeures (`v1.1.0+`)

Par rapport aux versions précédentes, la version actuelle intègre des mécanismes de sécurité avancés :

1. **Isolation stricte des données (Row Level Security - RLS)**
   - Toutes les tables Supabase (`profiles`, `agenda_events`, `outfit_feedback_events`) appliquent le RLS strict avec la règle `user_id = auth.uid()`.
   - Impossible pour un utilisateur d'accéder aux données ou favoris d'un autre utilisateur.

2. **Chiffrement local des jetons d'accès**
   - Utilisation de `flutter_secure_storage` pour le stockage sécurisé des secrets et jetons d'authentification sur appareil.

3. **Protection des clés d'API & Clé Service Role**
   - Aucune clé privilège (`service_role`) n'est exposée ou intégrée au client mobile Flutter.
   - Les variables sensibles sont chargées via `flutter_dotenv` à partir de `assets/.env`.

4. **Anonymisation et traitement local de l'IA**
   - Le traitement d'analyse morphologique et de posture (Google ML Kit) s'effectue à 100% en local sur l'appareil. Aucune image ou flux vidéo n'est envoyé sur des serveurs tiers.

5. **Protection du binaire & Obfuscation (R8/ProGuard)**
   - Activation des règles R8/ProGuard dans `android/app/proguard-rules.pro` pour masquer les symboles et prévenir l'ingénierie inverse.

6. **Isolation des logs d'application**
   - Stockage des fichiers de logs dans les répertoires sandboxés/privés natifs de chaque plateforme (`AppData/Support`, `cache/logs/`).

---

## Signalement d'une vulnérabilité

Si vous découvrez une vulnérabilité de sécurité dans Magic Mirror, veuillez ne pas ouvrir d'issue publique.

Vous pouvez contacter directement le mainteneur :
- **Mainteneur** : josoavj (Développeur Fullstack)
- **Profil GitHub** : [github.com/josoavj](https://github.com/josoavj)
- **Contact public** : +261 33 60 223 60

Nous nous engageons à traiter les rapports de sécurité sous **48 heures**.
