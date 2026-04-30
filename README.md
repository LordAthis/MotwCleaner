# MotwCleaner
## ZoneStripper - WebMarkCleaner - UnmarkWeb - TrustLocal - Unlocker - UnlockFlow


- UnlockFlow — folyamat-feloldó, semleges
- FileUnlocker — egyszerű, egyértelmű
- ZoneStripper — utal a Windows "Zone.Identifier" NTFS stream-re, ami a zárolás valódi neve
- MotwCleaner — MOTW = Mark of the Web, ez a hivatalos neve a Windows letöltési zárolásnak
- WebMarkCleaner — ugyanez, de érthetőbb
- UnmarkWeb — rövid, igés forma
- TrustLocal — azt fejezi ki, amit csinál: "megbízhatóvá teszi a helyi fájlokat"


--------------------------------


## 🇭🇺 Magyar leírás
A Windows az internetről letöltött fájlokra egy láthatatlan **"Mark of the Web" (MOTW)** jelzést tesz. Ez a biztonsági funkció gyakran megakadályozza a scriptek futtatását vagy a dokumentumok megnyitását. A **MotwCleaner** egy PowerShell eszköz, amely rekurzívan (minden almappában) eltávolítja ezt a korlátozást.

---

## 🇺🇸 English Description
Windows applies a hidden **"Mark of the Web" (MOTW)** tag to files downloaded from the internet. This often prevents scripts from running or documents from opening correctly. **MotwCleaner** is a PowerShell utility designed to recursively remove these locks.

---

## 🇩🇪 Deutsche Beschreibung
Windows versieht aus dem Internet heruntergeladene Dateien mit einer versteckten Kennzeichnung namens **"Mark of the Web" (MOTW)**. Dies verhindert oft das Ausführen von Skripten oder das Öffnen von Dokumenten. **MotwCleaner** ist ein PowerShell-Tool, das diese Sperren rekursiv aufhebt.

---

## 🇫🇷 Description Française
Windows applique une étiquette invisible **"Mark of the Web" (MOTW)** aux fichiers téléchargés sur Internet. Cela empêche souvent l'exécution de scripts ou l'ouverture de documents. **MotwCleaner** est un outil PowerShell conçu pour supprimer ces blocages de manière récursive.

---

## 🛠 Telepítés / Installation / Installation / Installation

| 🇭🇺 | 🇺🇸 | 🇩🇪 | 🇫🇷 |
|---|---|---|---|
| `MotwCleaner-Hu.ps1` | `MotwCleaner-En.ps1` | `MotwCleaner-De.ps1` | `MotwCleaner-Fr.ps1` |
| Jóváhagyás: **`i`** | Confirm: **`y`** | Bestätigung: **`j`** | Confirmer: **`o`** |
| Menü: *Zárolás Feloldása* | Menu: *Remove Lock* | Menü: *Sperre aufheben* | Menu: *Supprimer le verrou* |

1. 🇭🇺 Futtasd a fájlt → fogadd el az UAC (admin) kérést → nyomj **`i`**-t
2. 🇺🇸 Run the file → accept the UAC (admin) prompt → press **`y`**
3. 🇩🇪 Datei ausführen → UAC-Abfrage bestätigen → **`j`** drücken
4. 🇫🇷 Exécuter le fichier → accepter l'invite UAC (admin) → appuyer sur **`o`**

Ezután a jobb klikk menüben megjelenik az opció mappán, mappa hátterén és fájlon egyaránt.  
The option then appears in the right-click menu on folders, folder backgrounds, and files.

---

## ⚙️ Technical Details

The project stands out due to its hybrid parameter handling and direct .NET calls.

### 1. Registry API (.NET)
Instead of traditional `reg.exe` or PowerShell's `Set-ItemProperty`, the script uses the `[Microsoft.Win32.Registry]` class directly. This eliminates potential freezes of the PowerShell registry provider — especially on the `HKCR\*` key which is known to hang both `reg.exe` and the PS provider — ensuring a reliable installation.

### 2. Advanced Path Handling
The script operates in three different right-click contexts, each requiring a different Windows shell variable:

| Context | Variable | Meaning |
|---|---|---|
| Folder (`Directory`) | `%1` | The selected folder path |
| Background (`Background`) | `%V` | The current open folder |
| File (`*`) | `%1` | The selected file's full path |

For the **file** context, `%1` carries the file path itself. The script detects this on startup using `Test-Path -PathType Leaf` and automatically extracts the parent folder with `Split-Path -Parent`, so the unlock runs on the correct directory.

### 3. Accurate Lock Detection
The script uses `Get-Item -Stream "Zone.Identifier"` to check whether a file actually has a MOTW lock before counting it as "unlocked". This avoids false positives on files that were never locked in the first place.

### 4. Safety Guard
The script has a built-in blocklist (`BlockedPaths`). If the target path matches or is inside a critical system directory (e.g. `C:\Windows`, `C:\Program Files`, `C:\ProgramData`), execution stops immediately with a clear error message — preventing any accidental modification of system files.

---

**Enjoy!** 🚀

