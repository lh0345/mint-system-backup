# 💾 Mint System Backup

> A one-click Linux Mint backup utility that saves your APT, Flatpak, Snap, and AppImage apps — plus configs, themes, icons, and system info — directly into your **Documents** folder.  
> ⚡ No setup. No bloat. Just click → full system snapshot.

---

## 🧩 Overview

**Mint System Backup** is a lightweight shell-based tool designed for **Linux Mint** (and Ubuntu derivatives).  
It automates what users normally do manually — collecting all your installed packages, themes, configs, and user data into one timestamped folder.

✅ Works both **natively** and inside **Flatpak sandbox**  
✅ Bridges system commands safely via `flatpak-spawn`  
✅ Supports `.deb` and `.flatpak` distributions  
✅ Pure bash — no Python, no Electron, no bullshit

---

## 📦 Features

- **App Inventory:** Save lists of all APT, Flatpak, Snap, and AppImage installs  
- **Config Backup:** Archive key user configs from `~/.config`, `.themes`, `.icons`  
- **System Report:** Auto-generate hardware & OS info summary  
- **User Data:** Copies local app data (`~/.local/share`, `~/.var/app`)  
- **Auto Timestamp:** Every backup is versioned and organized  
- **Logs:** Full command logs stored inside each backup folder

---

## ⚙️ Installation

### 🟢 For Linux Mint / Ubuntu users (.deb)
```bash
sudo apt install ./mint-system-backup_1.0_amd64.deb
```
or drag and drop into **Gdebi**.

### 🔵 For Flatpak users
```bash
flatpak install --user MintSystemBackup.flatpak
flatpak run io.github.lh0345.MintSystemBackup
```

---

## 🚀 Usage

**Native terminal:**
```bash
sudo mint-backup.sh
```

**Flatpak sandbox:**
```bash
flatpak run io.github.lh0345.MintSystemBackup
```

All backups are stored under:
```
~/Documents/LinuxMint_Backup_YYYY-MM-DD_HH-MM-SS
```

---

## 🧠 How It Works

1. Detects environment (native vs. Flatpak)  
2. Bridges host tools with `flatpak-spawn` if needed  
3. Collects package lists, configs, themes, user data  
4. Writes logs and system info reports  
5. Compresses and finalizes backup folder

---

## 🖼 Directory Structure

```
LinuxMint_Backup_2025-10-19_23-53-59/
├── apt-packages.txt
├── flatpak-apps.txt
├── snap-apps.txt
├── appimage-list.txt
├── configs/
├── themes/
├── icons/
├── local-share/
├── flatpak-data/
└── system-info.txt
```

---

## 🧰 Tech Stack

- `bash`
- `rsync`
- `flatpak-spawn`
- `apt`, `dpkg`, `snap`, `flatpak`
- Zero external dependencies

---

## 🔒 Permissions

The Flatpak build bridges host commands using:
```bash
flatpak-spawn --host <command>
```
allowing safe execution of backup-related tasks while remaining sandboxed.

---

## 📄 License

This project is licensed under the **GPLv3 License** — see [LICENSE](./LICENSE).

---

## 🧑‍💻 Author

**Leart H.**  
🧠 Founder & Builder obsessed with clean, scalable tools.  
🚀 GitHub: [@lh0345](https://github.com/lh0345)

---

## 🧩 Contributing

Pull requests are welcome — just keep it clean and dependency-light.  
For feature requests, open an issue tagged `[feature-request]`.

---

## 🧱 Future Plans

- Incremental backups  
- Restore manager (reverse of backup)  
- Optional compression  
- GUI frontend (GTK / Electron-lite)  
- Scheduled backup mode

---

**Mint System Backup** — make backups simple, fast, and bulletproof.
