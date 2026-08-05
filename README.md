# aks-deployment-cd

Ce dépôt contient l'architecture et les workflows de déploiement continu (CD) sur Azure Kubernetes Service (AKS) basés sur GitHub Actions Runner Controller (ARC).

---

## Pipeline CI (Intégration Continue)

### Déclencheurs
* Push sur la branche `main`
* Fusion (*merge*) d'une Pull Request

### Déroulement
1. **Qualité & Tests :** Exécution du linter, des tests unitaires et de la matrice de tests.
2. **Identification du registre :** Récupération dynamique du nom de l'Azure Container Registry (ACR) via ses tags Azure.
3. **Build & Push :** Construction de l'image Docker à partir du `Dockerfile` puis publication sur l'ACR avec le tag `${{ github.sha }}`.
4. **Synchronisation :** Mise à jour automatique de la variable `LAST_BUILD_SHA` sur le dépôt CD avec l'identifiant du dernier commit.

---

## Pipeline CD (Déploiement Continu)

### Contexte & Architecture
* **Exécution in-cluster :** Le workflow s'exécute sur une image custom (`arc-runner-set`) hébergée au sein d'un pod AKS via **Actions Runner Controller (ARC)**.
* **Accès réseau :** L'adresse IP publique d'outbound / Load Balancer du cluster est intégrée aux plages d'IP autorisées (*authorized IP ranges*) de l'API Server AKS.
* **Outillage embarqué :** L'image du runner contient l'ensemble des CLIs nécessaires (`az`, `kubectl`, `helm`, `kubelogin`).
* **Authentification ARC :** Le contrôleur ARC est lié au dépôt via un *Personal Access Token* (PAT) disposant des permissions `Administration: Read & Write`.

### Déclencheur
* Manuel uniquement (`workflow_dispatch`).

### Déroulement
1. **Authentification Azure :** Connexion via `azure/login` et configuration de `kubelogin` pour la gestion des accès non-interactifs.
2. **Contexte Kubernetes :** Récupération du fichier `kubeconfig` et sélection du contexte AKS via `azure/aks-set-context`.
3. **Résolution de l'ACR :** Récupération du nom de l'ACR cible via la recherche par tags Azure.
4. **Rendu des manifests (Bake) :** Génération du bundle de manifests Kubernetes avec Helm via `azure/k8s-bake`, en injectant dynamiquement l'ACR et le tag de version (`vars.LAST_BUILD_SHA`).
5. **Déploiement :** Application des manifests générés sur le cluster via `azure/k8s-deploy` dans le namespace cible.

---

## Secrets & Variables GitHub

### Secrets (`secrets.*`)
| Nom | Description |
|---|---|
| `AZURE_CLIENT_ID` | Identifiant de l'Application (Client) pour l'authentification OIDC Azure |
| `AZURE_TENANT_ID` | Identifiant du Tenant Azure Active Directory / Entra ID |
| `AZURE_SUBSCRIPTION_ID` | Identifiant de la souscription Azure hébergeant l'AKS |
| `RESOURCE_GROUP` | Nom du groupe de ressources Azure contenant le cluster |
| `CLUSTER_NAME` | Nom du cluster Azure Kubernetes Service (AKS) |

### Variables (`vars.*`)
| Nom | Description |
|---|---|
| `LAST_BUILD_SHA` | Tag du dernier commit (`github.sha`) compilé par la CI et prêt à être déployé |

---

## Endpoints & Vérification

Une fois l'application déployée et accessible via le Load Balancer, les routes suivantes peuvent être testées :

| Route | Description | Exemple d'utilisation |
|---|---|---|
| `/healthz` | Probe de santé du service (`status: ok`) | `curl http://40.114.181.10/healthz` |
| `/test` | Route de vérification visuelle (Art ASCII) | `curl http://40.114.181.10/test` |
| `/data` | Endpoint principal de données de l'API | `curl http://40.114.181.10/data` |