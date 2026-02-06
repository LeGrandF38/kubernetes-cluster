# Kubernetes Cluster - Installation rapide 🚀

Ce dépôt contient deux scripts pour installer un cluster Kubernetes simple (master + worker) sur des VMs Debian/Ubuntu :

- `k8s-master-install.sh` : initialise le master (kubeadm) et installe Flannel
- `k8s-node-install.sh` : prépare un worker et laisse prêt pour `kubeadm join`

---

## ✅ Changements récents

- Détection automatique de l'adresse IP du master (plus besoin de modifier une IP en dur)
- Variable `K8S_VERSION` pour contrôler la version du dépôt APT Kubernetes
- Gestion améliorée de la clé GPG (suppression avant création afin d'éviter des conflits)

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

---

## Notes et bonnes pratiques 💡

- Assurez-vous que la variable `K8S_VERSION` dans les scripts correspond entre master et nodes pour éviter des incompatibilités de version.
- Le script détecte l'IP principale via `hostname -I | awk '{print $1}'` — vous pouvez modifier si votre interface réseau est différente.
- Si vous souhaitez utiliser un autre CNI (Calico, Cilium...), remplacez l'appel à Flannel dans le script master.

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
