# Devfile Registry für OpenShift Dev Spaces

Custom Devfile Registry für OpenShift Dev Spaces, gehostet auf GitLab und bereitgestellt über einen nginx-Container im Cluster.

## Architektur

```
GitLab Repository                    OpenShift Cluster
┌─────────────────────┐              ┌─────────────────────────────┐
│ devfile-registry/   │              │ devfile-registry Pod        │
│ ├── index.json      │   ──────►    │ ├── Init: curl von GitLab   │
│ ├── stacks/         │              │ └── nginx: statische Files  │
│ │   └── python-.../ │              └─────────────────────────────┘
│ │       └── devfile.yaml           
│ └── images/         │              
└─────────────────────┘              
```

## Repository-Struktur

```
devfile-registry/
├── index.json                    # Registry-Index (Liste aller Stacks)
├── stacks/
│   ├── python-workspace/
│   │   └── devfile.yaml          # Python Devfile
│   ├── nodejs-workspace/
│   │   └── devfile.yaml          # Node.js Devfile (Beispiel)
│   └── <weitere-stacks>/
│       └── devfile.yaml
├── images/
│   └── python.svg                # Stack-Icons (optional)
├── k8s/
│   └── deployment.yaml           # Kubernetes Deployment
└── README.md
```

## Neuen Stack hinzufügen

### 1. Devfile erstellen

Erstelle einen neuen Ordner unter `stacks/` mit einer `devfile.yaml`:

```bash
mkdir -p stacks/nodejs-workspace
```

Beispiel `stacks/nodejs-workspace/devfile.yaml`:

```yaml
schemaVersion: 2.2.0
metadata:
  name: nodejs-workspace
  displayName: Node.js Workspace
  description: Node.js development workspace
  tags:
    - Node.js
    - JavaScript
  projectType: Node.js
  language: JavaScript
  version: 1.0.0

components:
  - name: nodejs
    container:
      image: registry.redhat.io/devspaces/udi-rhel9:latest
      memoryLimit: 4Gi
      mountSources: true
      endpoints:
        - name: nodejs
          targetPort: 3000
          exposure: public

commands:
  - id: install
    exec:
      component: nodejs
      commandLine: npm install
      workingDir: ${PROJECT_SOURCE}
      group:
        kind: build
  - id: run
    exec:
      component: nodejs
      commandLine: npm start
      workingDir: ${PROJECT_SOURCE}
      group:
        kind: run
```

### 2. index.json erweitern

Füge einen neuen Eintrag zur `index.json` hinzu:

```json
[
  {
    "name": "python-workspace",
    "version": "1.0.0",
    "displayName": "Python Workspace",
    "description": "Python development workspace with CUDA support",
    "type": "stack",
    "tags": ["Python", "CUDA", "Jupyter"],
    "icon": "https://raw.githubusercontent.com/devfile-samples/devfile-stack-icons/main/python.svg",
    "projectType": "Python",
    "language": "Python",
    "links": {
      "self": "devfile-catalog/python-workspace:1.0.0"
    },
    "resources": ["devfile.yaml"]
  },
  {
    "name": "nodejs-workspace",
    "version": "1.0.0",
    "displayName": "Node.js Workspace",
    "description": "Node.js development workspace",
    "type": "stack",
    "tags": ["Node.js", "JavaScript", "TypeScript"],
    "icon": "https://raw.githubusercontent.com/devfile-samples/devfile-stack-icons/main/nodejs.svg",
    "projectType": "Node.js",
    "language": "JavaScript",
    "links": {
      "self": "devfile-catalog/nodejs-workspace:1.0.0"
    },
    "resources": ["devfile.yaml"]
  }
]
```

### 3. Änderungen pushen

```bash
git add .
git commit -m "Add nodejs-workspace stack"
git push
```

### 4. Deployment aktualisieren

Bearbeite `k8s/deployment.yaml` und füge den neuen Stack zur `STACKS` Variable hinzu:

```yaml
STACKS="python-workspace nodejs-workspace"
```

Dann anwenden:

```bash
oc apply -f k8s/deployment.yaml
oc delete pod -n openshift-operators -l app=devfile-registry
```

## Erstinstallation

### Voraussetzungen

- OpenShift Cluster mit Dev Spaces Operator
- GitLab Repository mit diesem Inhalt
- GitLab Personal Access Token mit `read_repository` Berechtigung
- `oc` CLI mit Cluster-Zugriff

### Deployment

1. **GitLab Access Token erstellen:**

   - GitLab → Settings → Access Tokens → "Add new token"
   - Name: z.B. `devfile-registry-reader`
   - Scopes: `read_repository`
   - Expiration: nach Bedarf

2. **Secret erstellen:**

```bash
# Option A: Template verwenden
cp k8s/secret.yaml.template k8s/secret.yaml
# Bearbeite k8s/secret.yaml und ersetze die Platzhalter
oc apply -f k8s/secret.yaml

# Option B: Direkt erstellen
oc create secret generic gitlab-credentials \
  -n openshift-operators \
  --from-literal=username=<GITLAB_USERNAME> \
  --from-literal=password=<GITLAB_ACCESS_TOKEN> \
  --from-literal=repo-url=http://gitlab.home.lab/devspaces/devfile-registry.git
```

3. **Kubernetes-Ressourcen deployen:**

```bash
oc apply -f k8s/deployment.yaml
```

4. **CheCluster konfigurieren:**

```bash
oc patch checluster/devspaces -n openshift-operators --type=merge -p '
spec:
  components:
    devfileRegistry:
      externalDevfileRegistries:
        - url: "http://devfile-registry-openshift-operators.apps.sno.home.lab"
'
```

3. **Verifizieren:**

```bash
# Pod-Status prüfen
oc get pods -n openshift-operators -l app=devfile-registry

# Registry-Index abrufen
curl http://devfile-registry-openshift-operators.apps.sno.home.lab/index
```

## Registry aktualisieren

Nach Änderungen in GitLab einfach den Pod neustarten:

```bash
oc delete pod -n openshift-operators -l app=devfile-registry
```

Der Init-Container lädt automatisch die aktuellen Dateien von GitLab.

## Troubleshooting

### Logs prüfen

```bash
# nginx Logs
oc logs -n openshift-operators -l app=devfile-registry

# Init-Container Logs
oc logs -n openshift-operators -l app=devfile-registry -c git-clone
```

### Registry-Endpunkte testen

```bash
# Index
curl http://devfile-registry-openshift-operators.apps.sno.home.lab/index

# Devfile abrufen
curl http://devfile-registry-openshift-operators.apps.sno.home.lab/devfiles/python-workspace/1.0.0
```

### Häufige Fehler

| Fehler | Ursache | Lösung |
|--------|---------|--------|
| 404 auf `/index` | Dateien nicht geladen | Init-Container Logs prüfen |
| CORS-Fehler | Header fehlen | nginx-Config prüfen |
| Stack nicht sichtbar | Nicht in index.json | index.json erweitern |

## Konfiguration

### Umgebungsvariablen im Deployment

| Variable | Beschreibung | Standard |
|----------|--------------|----------|
| `REGISTRY_URL` | GitLab Raw-URL | `http://gitlab.home.lab/devspaces/devfile-registry/-/raw/main` |
| `STACKS` | Liste der Stack-Namen | `python-workspace` |

### nginx-Endpunkte

| Pfad | Beschreibung |
|------|--------------|
| `/` | Redirect zu `/index` |
| `/index` | Registry-Index (JSON) |
| `/index/all` | Registry-Index (JSON) |
| `/devfiles/index.json` | Registry-Index (JSON) |
| `/devfiles/{name}/{version}` | Devfile YAML |
| `/devfiles/{name}` | Devfile YAML |

## Links

- [Devfile.io Dokumentation](https://devfile.io/docs)
- [OpenShift Dev Spaces Dokumentation](https://access.redhat.com/documentation/en-us/red_hat_openshift_dev_spaces)
- [Devfile Registry Format](https://devfile.io/docs/2.2.0/adding-a-devfile-registry)
