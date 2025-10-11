# ArgoCD HTTPS Access - Complete Solution

## Current Issues Fixed

1. **HTTPS Certificate Issue**: Self-signed certificate created and configured
2. **DNS Resolution**: `argocd.local` added to `/etc/hosts`
3. **Port Access**: Port forwarding configured on `8443:443`
4. **ArgoCD Configuration**: Server configured for HTTPS mode

## Access Methods

### Method 1: Using localhost:8443 (Recommended)

**URL**: `https://localhost:8443`
**Username**: `admin`
**Password**: Run `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

**Steps**:
1. Ensure port forwarding is active:
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8443:443 &
   ```

2. Access via browser: `https://localhost:8443`
   - **Accept the security warning** (self-signed certificate)
   - Or install the certificate: `/tmp/argocd-localhost.crt`

### Method 2: Using argocd.local (Alternative)

**URL**: `https://argocd.local:8443`
**Prerequisites**: 
- `/etc/hosts` entry: `127.0.0.1 argocd.local` ✅ (already added)
- Same port forwarding as Method 1

## Certificate Trust Solutions

### Option A: Accept Browser Warning (Simplest)
- Click "Advanced" → "Proceed to localhost (unsafe)"
- This works for development environments

### Option B: Install Certificate in Browser
1. Certificate exported to: `/tmp/argocd-localhost.crt`
2. In Chrome/Edge: Settings → Privacy and Security → Security → Manage Certificates → Import
3. In Firefox: Settings → Privacy & Security → Certificates → View Certificates → Import

### Option C: Add Certificate to System Trust Store
```bash
# Ubuntu/Debian
sudo cp /tmp/argocd-localhost.crt /usr/local/share/ca-certificates/argocd-localhost.crt
sudo update-ca-certificates

# CentOS/RHEL
sudo cp /tmp/argocd-localhost.crt /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust
```

## Verification Commands

```bash
# Check port forwarding
ps aux | grep port-forward | grep argocd

# Check certificate
kubectl get certificate argocd-localhost-tls -n argocd

# Test HTTPS access
curl -k -I https://localhost:8443

# Check ArgoCD configuration
kubectl get configmap argocd-cm -n argocd -o yaml | grep url
```

## Troubleshooting

### Port Forwarding Not Working
```bash
# Kill existing port forward
pkill -f "port-forward.*argocd"

# Restart port forwarding
kubectl port-forward svc/argocd-server -n argocd 8443:443 &
```

### Certificate Errors
- Use `-k` flag with curl for testing: `curl -k https://localhost:8443`
- Check certificate validity: `openssl x509 -in /tmp/argocd-localhost.crt -text -noout`

### DNS Issues
- Verify `/etc/hosts`: `grep argocd /etc/hosts`
- Should show: `127.0.0.1 argocd.local`

## Current Status
✅ ArgoCD HTTPS configured  
✅ Self-signed certificate created  
✅ DNS resolution configured  
✅ Port forwarding active  
✅ Server in HTTPS mode  

**Ready for secure access at**: `https://localhost:8443`