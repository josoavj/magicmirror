# Démarrage rapide — Magic Mirror

> Ce guide vous permettra d'avoir Magic Mirror fonctionnel en local en moins de 5 minutes.

---

## 1. Installation préalable

### Vérifier Flutter
```bash
flutter --version
```
Nécessite Flutter ≥ 3.1.0.

### Cloner et préparer le projet
```bash
git clone https://github.com/josoavj/magicmirror.git
cd magicmirror
flutter pub get
```

---

## 2. Configuration minimale

### Créer le fichier `.env`
```bash
cp .env.example assets/.env
```
Remplissez les variables suivantes dans `assets/.env` :
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `OPENWEATHERMAP_API_KEY`

---

## 3. Lancer l'application

```bash
# Sur l'appareil par défaut
flutter run
```

---

## 4. Tests & Vérification

Avant de soumettre une modification, assurez-vous que la suite de tests est au vert :

```bash
# Analyse statique
flutter analyze

# Lancer tous les tests
flutter test
```

La structure des tests est organisée comme suit :
- `test/unit/` : Logique de ranking et algorithmes.
- `test/presentation/` : Comportement des providers et notifiers.
- `test/data/` : Validation du parsing JSON.
- `test/widgets/` : Validation des flux UI.

---

## ✅ Prochaines étapes

| Guide | Contenu |
|---|---|
| [SUPABASE_SETUP.md](SUPABASE_SETUP.md) | Configurer la base de données et le stockage |
| [ARCHITECTURE.md](../ARCHITECTURE.md) | Comprendre la structure modulaire |
| [OUTFIT_ML_PIPELINE.md](OUTFIT_ML_PIPELINE.md) | Intégrer le pipeline de Machine Learning |
