#!/bin/bash
# ==========================================================
# Mint System Backup v1.0 — host-aware & Flatpak-safe
# ==========================================================
set -euo pipefail

# -------- 0) Helper --------
log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOGFILE"; }

# -------- 1) Environment detect + tool wiring --------
SANDBOX="${FLATPAK_ID:-}"
if [ -n "$SANDBOX" ]; then
  echo "🧱 Running inside Flatpak sandbox ($SANDBOX)"
  if command -v flatpak-spawn >/dev/null 2>&1; then
    SUDO="flatpak-spawn --host sudo"
    APT="flatpak-spawn --host apt"
    DPKG="flatpak-spawn --host dpkg"
    FLATPAK="flatpak-spawn --host flatpak"
    SNAP="flatpak-spawn --host snap"
    RSYNC_HOST="flatpak-spawn --host rsync"
    SH_HOST="flatpak-spawn --host sh -lc"
    # Resolve host home and derive the host path that mirrors sandbox $HOME
    HOST_HOME="$($SH_HOST 'printf %s "$HOME"')"
    SANDBOX_HOME="$HOME"
    HOST_SANDBOX_HOME="$HOST_HOME/.var/app/$SANDBOX"
  else
    echo "⚠️  flatpak-spawn not found — host bridging unavailable."
    SUDO="sudo"; APT="apt"; DPKG="dpkg"; FLATPAK="flatpak"; SNAP="snap"; RSYNC_HOST="rsync"
    HOST_HOME=""; HOST_SANDBOX_HOME=""
  fi
else
  echo "✅ Running natively"
  SUDO="sudo"; APT="apt"; DPKG="dpkg"; FLATPAK="flatpak"; SNAP="snap"; RSYNC_HOST="rsync"
  HOST_HOME="$HOME"; HOST_SANDBOX_HOME="$HOME"
fi

# -------- 2) Paths & logging --------
BACKUP_DIR="$HOME/Documents/LinuxMint_Backup_$(date '+%Y-%m-%d_%H-%M-%S')"
LOGFILE="$BACKUP_DIR/backup.log"
mkdir -p "$BACKUP_DIR"; : >"$LOGFILE"

echo "--------------------------------------------"
echo "💾 Linux Mint Backup — $(date)"
echo "Destination (sandbox view): $BACKUP_DIR"
[ -n "$SANDBOX" ] && echo "Host home: $HOST_HOME" && echo "Host sandbox home: $HOST_SANDBOX_HOME"
echo "--------------------------------------------"

# For host-side copies we need the *host* view of BACKUP_DIR.
# Inside Flatpak: $BACKUP_DIR = $HOME/…  -> host path is $HOST_SANDBOX_HOME + (${BACKUP_DIR} minus $HOME prefix)
if [ -n "$SANDBOX" ] && [ -n "$HOST_SANDBOX_HOME" ]; then
  REL_FROM_SANDBOX="${BACKUP_DIR#"$SANDBOX_HOME"}"     # e.g. /Documents/…
  HOST_BACKUP_DIR="$HOST_SANDBOX_HOME$REL_FROM_SANDBOX" # host-visible destination
  # Ensure host destination exists too (not just the sandbox view)
  flatpak-spawn --host mkdir -p "$HOST_BACKUP_DIR"
else
  HOST_BACKUP_DIR="$BACKUP_DIR"
fi

# -------- 3) Essentials (passwordless only) --------
log "🔧 Checking essentials..."
if $SUDO -n true 2>/dev/null; then
  $SUDO $APT update -qq || log "⚠️  APT update failed or partially skipped."
  $SUDO $APT install -y rsync flatpak snapd dselect &>>"$LOGFILE" || true
else
  log "⚠️  No passwordless sudo — skipping package updates/installs."
fi

# -------- 4) Package lists --------
log "📋 Saving installed packages..."
# Redirections happen in the sandbox shell -> files still land in $BACKUP_DIR
$DPKG --get-selections > "$BACKUP_DIR/apt-packages.txt" 2>>"$LOGFILE" || log "⚠️  Could not save APT packages."
$FLATPAK list --app --columns=application,origin > "$BACKUP_DIR/flatpak-apps.txt" 2>>"$LOGFILE" || log "⚠️  No Flatpaks found."
$SNAP list > "$BACKUP_DIR/snap-apps.txt" 2>>"$LOGFILE" || log "⚠️  No Snaps found."
find "$HOST_HOME/Applications" -name "*.AppImage" > "$BACKUP_DIR/appimage-list.txt" 2>>"$LOGFILE" || log "⚠️  No AppImages found."

# -------- 5) Configs, themes, icons --------
log "🗂 Backing up configs, themes, icons..."
if [ -n "$SANDBOX" ] && [ -n "$HOST_HOME" ]; then
  # Copy *from host* to *host* destination so we don’t depend on sandbox mounts
  $RSYNC_HOST -a --quiet "$HOST_HOME/.bashrc" "$HOST_BACKUP_DIR/" 2>>"$LOGFILE" || true
  $RSYNC_HOST -a --quiet "$HOST_HOME/.bash_aliases" "$HOST_BACKUP_DIR/" 2>>"$LOGFILE" || true
  $RSYNC_HOST -a --quiet "$HOST_HOME/.profile" "$HOST_BACKUP_DIR/" 2>>"$LOGFILE" || true
  $RSYNC_HOST -a --quiet "$HOST_HOME/.config" "$HOST_BACKUP_DIR/configs" \
    --exclude '.cache' --exclude 'Code' --exclude 'google-chrome' 2>>"$LOGFILE" || true
  [ -d "$HOST_HOME/.themes" ] && $RSYNC_HOST -a --quiet "$HOST_HOME/.themes" "$HOST_BACKUP_DIR/themes" 2>>"$LOGFILE" || true
  [ -d "$HOST_HOME/.icons" ] && $RSYNC_HOST -a --quiet "$HOST_HOME/.icons" "$HOST_BACKUP_DIR/icons" 2>>"$LOGFILE" || true
else
  # Native
  rsync -a --quiet ~/.bashrc ~/.bash_aliases ~/.profile "$BACKUP_DIR/" 2>>"$LOGFILE" || true
  rsync -a --quiet ~/.config "$BACKUP_DIR/configs" \
    --exclude '.cache' --exclude 'Code' --exclude 'google-chrome' 2>>"$LOGFILE" || true
  [ -d ~/.themes ] && rsync -a --quiet ~/.themes "$BACKUP_DIR/themes" 2>>"$LOGFILE" || true
  [ -d ~/.icons ] && rsync -a --quiet ~/.icons "$BACKUP_DIR/icons" 2>>"$LOGFILE" || true
fi

# -------- 6) System info --------
log "🧠 Capturing system info..."
{
  echo "Linux Mint system info:"
  lsb_release -a 2>/dev/null || true
  uname -a || true
  df -h || true
  free -h || true
} > "$BACKUP_DIR/system-info.txt"

# -------- 7) Local user & Flatpak data (HOST paths) --------
log "📦 Backing up local app data..."
if [ -n "$SANDBOX" ] && [ -n "$HOST_HOME" ]; then
  log "🔗 Host user data: $HOST_HOME"
  $RSYNC_HOST -a --quiet "$HOST_HOME/.local/share/" "$HOST_BACKUP_DIR/local-share/" --exclude 'Trash' 2>>"$LOGFILE" \
    && log "✅ .local/share → local-share" || log "⚠️  Could not copy .local/share"
  $RSYNC_HOST -a --quiet "$HOST_HOME/.var/app/" "$HOST_BACKUP_DIR/flatpak-data/" 2>>"$LOGFILE" \
    && log "✅ .var/app → flatpak-data"   || log "⚠️  Could not copy .var/app"
else
  rsync -a --quiet ~/.local/share/ "$BACKUP_DIR/local-share/" --exclude 'Trash' 2>>"$LOGFILE" || true
  rsync -a --quiet ~/.var/app/ "$BACKUP_DIR/flatpak-data/" 2>>"$LOGFILE" || true
fi

# -------- 8) Summary --------
SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
log "✅ Backup complete!"
log "📦 Backup size: $SIZE"
log "📄 Backup (sandbox path): $BACKUP_DIR"
[ -n "$SANDBOX" ] && log "📁 Backup (host path): $HOST_BACKUP_DIR"

echo "--------------------------------------------"
echo "✨ DONE!"
echo " Sandbox path: $BACKUP_DIR"
[ -n "$SANDBOX" ] && echo " Host path:    $HOST_BACKUP_DIR"
echo " Total size:   $SIZE"
echo "--------------------------------------------"
read -p "Press ENTER to close..."
