# FIRA AI

FIRA est une application mobile Flutter destinée à piloter un assistant de développement logiciel.

## Fondation 0.1.0
- Interface mobile en français : Assistant, Projets, Historique et Réglages.
- Profils prévus : autonomie élevée et sécurité sensible.
- Service Python minimal avec endpoints de santé et de capacités.
- GitHub Actions vérifie le code et compile l'APK Android.

**Limite actuelle :** aucun modèle IA n'est encore connecté. L'écran Assistant affiche une réponse de démonstration, pas une réponse produite par un modèle. Ne placez aucune clé API ou aucun secret dans le dépôt.

## Structure
- `lib/` : application Flutter.
- `engine/` : API Python et contrat de sécurité de l'agent.
- `.github/workflows/` : intégration continue et compilation APK.

## Compiler
```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

L'autonomie élevée autorisera la planification multi-étapes et la vérification des résultats. Les actions sensibles (suppression, publication, déploiement, accès aux secrets) devront demander une validation explicite et s'exécuter dans un environnement isolé.
