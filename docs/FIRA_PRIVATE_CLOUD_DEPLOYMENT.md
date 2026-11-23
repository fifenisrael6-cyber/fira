# FIRA — déploiement cloud privé et gratuit (phase pilote)

## Décision d'architecture

- Hébergement visé : Oracle Cloud Infrastructure (OCI) Always Free, VM Ubuntu Server ARM64.
- Ressources de départ visées : 2 OCPU Ampere A1 et 12 Go de RAM au total, dans les limites Always Free de la région d'origine du compte.
- Application : API Python/FastAPI dans Docker Compose.
- Données : volume Docker persistant pour les checkpoints JSON et NPZ de FIRA.
- Accès privé : Tailscale sur l'hôte + Tailscale Serve en HTTPS. Le port de l'API est publié uniquement sur 127.0.0.1.
- Client : l'application Flutter utilise l'URL HTTPS `https://<nom-machine>.<tailnet>.ts.net` affichée par Tailscale Serve.

Cette configuration n'appelle aucun fournisseur d'IA et ne télécharge aucun poids de modèle préentraîné. Elle héberge le moteur expérimental actuellement présent dans le dépôt. Ce moteur apprend des transitions de mots et ne constitue pas encore un assistant conversationnel capable de raisonner ou de programmer de façon fiable.

## Limites du gratuit

OCI publie des ressources Always Free, dont une capacité Ampere A1 équivalente à 2 OCPU et 12 Go de mémoire, ainsi qu'un quota de stockage en blocs. Ces ressources sont soumises à la disponibilité de capacité dans la région choisie. Oracle peut récupérer les instances Always Free jugées inactives selon ses critères. Le niveau gratuit n'est donc pas une garantie de disponibilité permanente ni de GPU.

Références officielles :
- https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm
- https://www.oracle.com/cloud/free/

Ne sélectionne pas de forme payante, de disque payant, d'adresse IP payante ou de mise à niveau payante. Vérifie le récapitulatif tarifaire avant toute création. Si le portail demande une vérification de paiement, respecte les conditions du fournisseur et n'essaie pas de les contourner.

## Schéma réseau privé

```text
Téléphone Android (Tailscale activé)
          |
          | HTTPS dans le tailnet privé
          v
Tailscale Serve sur la VM
          |
          | proxy local uniquement
          v
127.0.0.1:8000
          |
          v
Docker Compose : fira-engine
          |
          +--> /app/data/fira_ngram_model.json
          +--> /app/data/fira_tiny_neural.npz
```

Ne configure jamais Tailscale Funnel pour FIRA. Ne publie pas le port 8000 dans le pare-feu cloud. Tailscale Serve est accessible aux appareils autorisés du même tailnet et applique les règles d'accès de ce tailnet.

## Préparation du compte et de la VM

1. Crée ou utilise ton propre compte OCI selon les conditions du fournisseur.
2. Sélectionne ta région d'origine, puis vérifie dans la console qu'une VM Ampere A1 Ubuntu ARM64 est bien marquée **Always Free Eligible**.
3. Crée une VM avec 2 OCPU, 12 Go de RAM et un volume de démarrage de taille incluse dans le quota gratuit.
4. Pour le premier accès SSH, limite temporairement la règle entrante TCP 22 à ton adresse IP d'administration. N'ouvre aucun autre port entrant.
5. Une fois Tailscale connecté et testé, supprime cette règle SSH publique et administre la VM via le réseau privé lorsque possible.

Les ressources Always Free peuvent être indisponibles dans certaines régions. Ne choisis pas une ressource payante pour contourner une indisponibilité.

## Installation sur Ubuntu

Après connexion à la VM, installe Docker Engine et le plugin Docker Compose en suivant la documentation officielle Docker pour Ubuntu. Installe ensuite Tailscale en suivant sa documentation Linux officielle. N'utilise pas de script d'installation non vérifié provenant d'un dépôt tiers.

Connecte la VM et ton téléphone au même tailnet personnel. Active MagicDNS et les certificats HTTPS dans les paramètres DNS du tailnet si Tailscale le demande.

## Déploiement de FIRA

Sur la VM :

```bash
git clone --branch feat/fira-from-scratch-learning-engine https://github.com/fifenisrael6-cyber/FIRA.git
cd FIRA/deploy/oracle-cloud
docker compose config
docker compose up -d --build
docker compose ps
curl --fail http://127.0.0.1:8000/health
```

Quand la VM est configurée pour Tailscale, publie l'API uniquement dans le tailnet :

```bash
sudo tailscale serve --bg 8000
sudo tailscale serve status
```

La sortie donne le nom HTTPS privé de la machine. N'utilise pas `tailscale funnel`.

Dans FIRA sur Android, ouvre Réglages et enregistre l'URL HTTPS affichée, sans ajouter `/v1`. Le téléphone doit être connecté au même tailnet pour joindre l'API.

## Persistance, sauvegarde et mise à jour

- Les fichiers de modèle se trouvent dans le volume Docker `fira-model-data`, séparé du conteneur.
- Avant une mise à jour, crée une sauvegarde du volume et vérifie qu'elle est lisible.
- Mise à jour : `git pull`, puis `docker compose up -d --build`.
- Arrêt : `docker compose down`. Ne lance pas `docker compose down -v`, car cela supprimerait le volume des apprentissages.
- Une VM récupérée ou supprimée par le fournisseur peut entraîner une perte des données locales si aucune sauvegarde séparée n'existe.

## Contrôles de validation

1. `docker compose ps` affiche le service en état sain.
2. `curl http://127.0.0.1:8000/health` renvoie `status=ok`.
3. `tailscale serve status` montre un proxy vers `127.0.0.1:8000`.
4. L'URL HTTPS fonctionne sur le téléphone avec Tailscale activé.
5. La même URL ne répond plus depuis un appareil non connecté au tailnet.
6. Après un redémarrage de la VM, le conteneur redémarre et `/v1/learn/neural/status` conserve les compteurs d'entraînement.

## Limites fonctionnelles actuelles

- Le déploiement héberge le moteur n-gram et le petit réseau neuronal de FIRA.
- Le petit réseau neuronal est un modèle de prédiction du mot suivant, initialisé aléatoirement ; ce n'est pas un LLM.
- La route de conversation ne devient pas un assistant fiable par le seul fait d'être hébergée dans le cloud. Sans service d'inférence local, elle ne peut fournir qu'une continuation expérimentale après entraînement.
- Cette VM pilote n'a pas de GPU. Elle convient aux tests et à l'apprentissage de base, pas à l'entraînement d'un grand modèle.
- Les fonctions de cybersécurité restent limitées aux analyses défensives et aux environnements explicitement autorisés ; aucun moteur d'exploitation n'est déployé.

## Ce qui reste nécessaire avant l'activation réelle

Le dépôt contient les fichiers de déploiement, mais aucun compte OCI ou Tailscale n'est créé depuis GitHub. La VM, le tailnet et l'URL privée doivent être créés dans les comptes de l'utilisateur. Ne place aucun mot de passe, clé SSH privée ou jeton Tailscale dans le dépôt.
