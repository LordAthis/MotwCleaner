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

--------------------------------

## 🇺🇸 English Description
Windows applies a hidden **"Mark of the Web" (MOTW)** tag to files downloaded from the internet. This often prevents scripts from running or documents from opening correctly. **MotwCleaner** is a PowerShell utility designed to recursively remove these locks.

--------------------------------

## 🇩🇪 Deutsche Beschreibung
Windows versieht aus dem Internet heruntergeladene Dateien mit einer versteckten Kennzeichnung namens **"Mark of the Web" (MOTW)**. Dies verhindert oft das Ausführen von Skripten oder das Öffnen von Dokumenten. **MotwCleaner** ist ein PowerShell-Tool, das diese Sperren rekursiv aufhebt.

--------------------------------

## 🇫🇷 Description Française
Windows applique une étiquette invisible **"Mark of the Web" (MOTW)** aux fichiers téléchargés sur Internet. Cela empêche souvent l'exécution de scripts ou l'ouverture de documents. **MotwCleaner** est un outil PowerShell conçu pour supprimer ces blocages de manière récursive.

--------------------------------

## 🛠 Telepítés

1. Futtasd a **MotwCleaner-Hu.ps1** (vagy a választott nyelvű) fájlt.
2. Hagyd jóvá az **Adminisztrátori** jogkérést.
3. Nyomj **'i'** (igen) gombot a telepítéshez.
4. Használd a jobb klikk: **"Zárolás Feloldása (MotwCleaner)"** opciót bárhol az Intézőben.

--------------------------------

## ⚙️ Technikai részletek

A projekt különlegessége a hibrid paraméterkezelés és a közvetlen .NET hívások:

### 1. Registry API (.NET)
A hagyományos `reg.exe` vagy a PowerShell `Set-ItemProperty` helyett a script a `[Microsoft.Win32.Registry]` osztályt használja. Ez kiküszöböli a Registry provider esetleges fagyásait és megbízhatóbbá teszi a telepítést.

### 2. Speciális elérési utak kezelése
A script három különböző környezetben működik, amihez eltérő Windows változók szükségesek a Registry-ben:
- **Mappa (`Directory`):** A `%1` paramétert használjuk az aktuális mappa átvételéhez.
- **Háttér (`Background`):** Az üres területen való kattintáskor a `%V` változó adja meg a könyvtárat.
- **Fájl (`*`):** Itt a `%~dp1.` parancssori szintaxist alkalmazzuk. 
  - `%1`: A kiválasztott fájl teljes útja.
  - `~dp`: A "Drive" (meghajtó) és "Path" (útvonal) részek kinyerése, levágva a fájlnevet.
  - `.`: A pont a végén biztosítja, hogy a PowerShell érvényes mappaként kezelje az útvonalat szóközök esetén is.
  - **Eredmény:** Ha egy fájlra kattintasz, a script a fájlt tartalmazó mappában indul el, és onnan hajtja végre a feloldást lefelé.

### 3. Biztonság
A script tartalmaz egy beépített tiltólistát (`BlockedPaths`). Ha a célútvonal megegyezik vagy része egy kritikus rendszermappának (pl. `C:\Windows`, `C:\Program Files`), a futás azonnal leáll, megelőzve a rendszerfájlok véletlen módosítását.

--------------------------------

## 🛠 Installation

1. Run the **MotwCleaner-En.ps1** (or your preferred language) file.
2. Accept the **Administrator** elevation prompt (UAC).
3. Press **'y'** (yes) to confirm the installation into the system.
4. Use the right-click option: **"Unblock Files (MotwCleaner)"** anywhere in File Explorer.

--------------------------------

## ⚙️ Technical Details

The project stands out due to its hybrid parameter handling and direct .NET calls:

### 1. Registry API (.NET)
Instead of traditional `reg.exe` or PowerShell's `Set-ItemProperty`, the script utilizes the `[Microsoft.Win32.Registry]` class. This eliminates potential hangs of the PowerShell registry provider and ensures a more reliable installation.

### 2. Advanced Path Handling
The script operates in three different contexts, requiring different Windows variables in the Registry:
- **Folder (`Directory`):** Uses the `%1` parameter to capture the selected folder path.
- **Background (`Background`):** Uses the `%V` variable when clicking on empty space to identify the current directory.
- **File (`*`):** Uses the `%~dp1.` command-line syntax.
  - `%1`: Full path of the selected file.
  - `~dp`: Extracts the "Drive" and "Path", stripping the filename.
  - `.`: The trailing dot ensures PowerShell treats the path as a valid directory even with spaces.
  - **Result:** When clicking a file, the script starts in the parent folder and performs the unblocking recursively downwards.

### 3. Safety Guard
The script features a built-in blacklist (`BlockedPaths`). If the target path matches or is part of a critical system directory (e.g., `C:\Windows`, `C:\Program Files`), the process terminates immediately to prevent accidental modification of system files.


--------------------------------

## 🛠 Installation

1. Führen Sie die Datei **MotwCleaner-De.ps1** (oder die Sprache Ihrer Wahl) aus.
2. Bestätigen Sie die Abfrage für **Administratorrechte** (UAC).
3. Drücken Sie **'j'** (ja), um die Installation im System zu bestätigen.
4. Nutzen Sie die Rechtsklick-Option: **"Dateien entsperren (MotwCleaner)"** an einer beliebigen Stelle im Explorer.

--------------------------------

## ⚙️ Technische Details

Das Projekt zeichnet sich durch hybride Parameterverwaltung und direkte .NET-Aufrufe aus:

### 1. Registry API (.NET)
Anstelle von herkömmlichen `reg.exe` oder PowerShell-Befehlen wie `Set-ItemProperty` verwendet das Skript die Klasse `[Microsoft.Win32.Registry]`. Dies verhindert mögliche Freezes des PowerShell-Registry-Providers und macht die Installation zuverlässiger.

### 2. Spezielle Pfadbehandlung
Das Skript arbeitet in drei verschiedenen Kontexten, wofür unterschiedliche Windows-Variablen in der Registry benötigt werden:
- **Ordner (`Directory`):** Verwendet den Parameter `%1`, um den Pfad des ausgewählten Ordners zu übernehmen.
- **Hintergrund (`Background`):** Beim Klick auf eine leere Fläche liefert die Variable `%V` das aktuelle Verzeichnis.
- **Datei (`*`):** Hier wird die Kommandozeilen-Syntax `%~dp1.` angewendet.
  - `%1`: Vollständiger Pfad der ausgewählten Datei.
  - `~dp`: Extrahiert "Drive" (Laufwerk) und "Path" (Pfad) und entfernt den Dateinamen.
  - `.`: Der Punkt am Ende stellt sicher, dass PowerShell den Pfad auch bei Leerzeichen als gültiges Verzeichnis erkennt.
  - **Ergebnis:** Wenn Sie auf eine Datei klicken, startet das Skript im übergeordneten Ordner und führt die Entsperrung rekursiv nach unten aus.

### 3. Sicherheitsfilter (Safety Guard)
Das Skript enthält eine integrierte Sperrliste (`BlockedPaths`). Wenn der Zielpfad mit einem kritischen Systemverzeichnis übereinstimmt oder Teil davon ist (z. B. `C:\Windows`, `C:\Program Files`), wird die Ausführung sofort gestoppt, um versehentliche Änderungen an Systemdateien zu verhindern.

--------------------------------

## 🛠 Installation

1. Exécutez le fichier **MotwCleaner-Fr.ps1** (ou la langue de votre choix).
2. Acceptez la demande de droits **Administrateur** (UAC).
3. Appuyez sur **'o'** (oui) pour confirmer l'installation dans le système.
4. Utilisez l'option du clic droit : **"Débloquer les fichiers (MotwCleaner)"** n'importe où dans l'Explorateur.

--------------------------------

## ⚙️ Détails Techniques

Le projet se distingue par sa gestion hybride des paramètres et ses appels .NET directs :

### 1. API du Registre (.NET)
Au lieu du traditionnel `reg.exe` ou de la commande PowerShell `Set-ItemProperty`, le script utilise la classe `[Microsoft.Win32.Registry]`. Cela élimine les blocages potentiels du fournisseur de registre PowerShell et sécurise l'installation.

### 2. Gestion Avancée des Chemins
Le script fonctionne dans trois contextes différents, nécessitant des variables Windows distinctes dans le Registre :
- **Dossier (`Directory`) :** Utilise le paramètre `%1` pour récupérer le chemin du dossier sélectionné.
- **Arrière-plan (`Background`) :** Lors d'un clic sur un espace vide, la variable `%V` indique le répertoire actuel.
- **Fichier (`*`) :** La syntaxe de ligne de commande `%~dp1.` est appliquée ici.
  - `%1` : Chemin complet du fichier sélectionné.
  - `~dp` : Extrait le lecteur ("Drive") et le chemin ("Path") en supprimant le nom du fichier.
  - `.` : Le point à la fin garantit que PowerShell traite le chemin comme un répertoire valide, même avec des espaces.
  - **Résultat :** Si vous cliquez sur un fichier, le script démarre dans le dossier parent et effectue le déblocage de manière récursive vers le bas.

### 3. Garde-fou de Sécurité (Safety Guard)
Le script intègre une liste d'exclusion (`BlockedPaths`). Si le chemin cible correspond ou fait partie d'un répertoire système critique (ex: `C:\Windows`, `C:\Program Files`), le processus s'arrête immédiatement pour éviter toute modification accidentelle des fichiers système.


--------------------------------

**Enjoy!** 🚀


