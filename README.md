# Kubernetes Cluster - Installation rapide 🚀

Ce dépôt contient trois scripts pour installer et gérer un cluster Kubernetes simple (master + worker) sur des VMs Debian/Ubuntu :

- `k8s-master-install.sh` : initialise le master (kubeadm) et installe Flannel
- `k8s-node-install.sh` : prépare un worker et laisse prêt pour `kubeadm join`
- `k8s-cleanup.sh` : nettoyage complet du cluster (reset total)

---

## ✅ Changements récents

- Détection automatique de l'adresse IP du master (plus besoin de modifier une IP en dur)
- Variable `K8S_VERSION` pour contrôler la version du dépôt APT Kubernetes
- Gestion améliorée de la clé GPG (suppression avant création afin d'éviter des conflits)
- Support des VMs 1 CPU avec `--ignore-preflight-errors=NumCPU`
- Script de nettoyage complet `k8s-cleanup.sh` pour reset le cluster

---

## Pré requis

- Systèmes : Debian / Ubuntu
- Accès root (sudo)
- 2 VMs minimum (1 master, 1 worker) sur le même réseau
- Ports nécessaires ouverts entre les nœuds (master <-> node) :
  - API Server: 6443
  - etcd: 2379-2380
  - kubelet: 10250
  - kube-scheduler / kube-controller-manager / kube-proxy as needed
- Au moins 2GB RAM et 2 vCPU (recommandé pour le master)

---

## 🧹 Nettoyage complet du cluster

Si vous devez réinstaller ou corriger des erreurs, utilisez le script de nettoyage :

```bash
curl -o k8s-cleanup.sh https://raw.githubusercontent.com/LeGrandF38/kubernetes-cluster/main/k8s-cleanup.sh
chmod +x k8s-cleanup.sh
sudo ./k8s-cleanup.sh
```

Ce script :
- Fait un `kubeadm reset` propre
- Supprime toutes les interfaces réseau (cni0, flannel.1, etc.)
- Nettoie les dossiers Kubernetes et K3s
- Réinitialise les règles iptables
- Demande confirmation avant suppression

Après nettoyage, vous pouvez relancer les scripts d'installation normalement.

---

## Procédure d'installation (Master)

1. Télécharger et rendre exécutable :

```bash
curl -o k8s-master-install.sh https://raw.githubusercontent.com/LeGrandF38/kubernetes-cluster/main/k8s-master-install.sh
chmod +x k8s-master-install.sh
sudo ./k8s-master-install.sh
```

2. À la fin de l'installation, copiez la commande affichée `kubeadm join ...` (elle contient le token et le hash CA).

3. Vérifier le status :

```bash
kubectl get nodes
kubectl get pods -A
```

---

## Procédure d'installation (Worker)

1. Télécharger et exécuter le script de préparation :

```bash
curl -o k8s-node-install.sh https://raw.githubusercontent.com/LeGrandF38/kubernetes-cluster/main/k8s-node-install.sh
chmod +x k8s-node-install.sh
sudo ./k8s-node-install.sh
```

2. Rejoindre le cluster avec la commande copiée depuis le master :

```bash
sudo kubeadm join <IP_MASTER>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

**Si erreur CPU sur le worker :**
```bash
sudo kubeadm join <IP_MASTER>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash> --ignore-preflight-errors=NumCPU
```

**Si `sudo: kubeadm: command not found` mais que `which kubeadm` retourne `/usr/bin/kubeadm` :**
- Vous êtes probablement déjà root, utilisez simplement :

```bash
kubeadm join <IP_MASTER>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash> --ignore-preflight-errors=NumCPU
```

  ou bien le chemin complet :

```bash
sudo /usr/bin/kubeadm join <IP_MASTER>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash> --ignore-preflight-errors=NumCPU
```

---

## Notes et bonnes pratiques 💡

- Assurez-vous que la variable `K8S_VERSION` dans les scripts correspond entre master et nodes pour éviter des incompatibilités de version.
- Le script détecte l'IP principale via `hostname -I | awk '{print $1}'` — vous pouvez modifier si votre interface réseau est différente.
- Si vous souhaitez utiliser un autre CNI (Calico, Cilium...), remplacez l'appel à Flannel dans le script master.

---

## Gestion du cluster depuis une autre machine (kubeconfig)

Vous pouvez gérer le cluster depuis votre PC (ou une autre VM) sans vous connecter en SSH au master à chaque fois.

1. Sur le **master**, vérifiez que le fichier kubeconfig existe (créé par le script) :

```bash
ls /root/.kube/config
```

2. Depuis votre machine cliente (Linux/macOS avec `kubectl` installé), copiez la configuration :

```bash
scp root@<IP_MASTER>:/root/.kube/config ~/.kube/config
```

3. Testez l'accès au cluster depuis votre machine :

```bash
kubectl get nodes
```

Si vous avez plusieurs clusters, vous pouvez renommer le fichier (`~/.kube/config-mindy`) et utiliser la variable `KUBECONFIG` :

```bash
export KUBECONFIG=~/.kube/config-mindy
kubectl config get-contexts
```

---

## Déployer le minimum nécessaire

Quelques exemples rapides à lancer depuis la machine qui a `kubectl` configuré :

1. **Déployer metrics-server** (pour `kubectl top`) :

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

2. **Déployer une appli de test (nginx)** :

```bash
kubectl create deployment nginx-demo --image=nginx --replicas=1
kubectl expose deployment nginx-demo --type=NodePort --port=80
kubectl get svc nginx-demo
```

3. **Vérifier que tout tourne bien** :

```bash
kubectl get pods -A
kubectl top nodes
```

---

## Commandes utiles

- Voir les nœuds : `kubectl get nodes`
- Voir tous les pods : `kubectl get pods -A`
- Pour re-générer la commande de join sur le master :

```bash
kubeadm token create --print-join-command
```

---

Si vous voulez, je peux aussi pousser le commit vers le remote (`origin`). Dites-moi si je dois le faire 👍
