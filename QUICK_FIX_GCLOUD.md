# 🔧 Quick Fix: gcloud Installation

## The Problem

Brew is trying to find Python 3.13 at a path that doesn't exist on your system.

## ✅ Solution: Manual Installation

Run this command:

```bash
./scripts/install_gcloud_manual.sh
```

This will:
1. ✅ Download gcloud directly (bypasses brew)
2. ✅ Use your existing Python 3.13.5
3. ✅ Install to `~/google-cloud-sdk`
4. ✅ Add to PATH

---

## After Installation

1. **Restart terminal** or run:
   ```bash
   source ~/.zshrc
   ```

2. **Verify installation:**
   ```bash
   gcloud --version
   ```

3. **Login:**
   ```bash
   gcloud auth login
   ```

4. **Initialize:**
   ```bash
   gcloud init
   ```

5. **Then run setup:**
   ```bash
   ./scripts/setup_firebase_test_lab.sh
   ```

---

## Alternative: One-Line Install

If you prefer to do it manually:

```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init
```

---

## ✅ That's It!

Once gcloud is installed, you can run:
```bash
./scripts/build_and_test_firebase.sh
```

