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

## 🛠 Telepítés / Installation

1. Futtasd a **MotwCleaner-Hu.ps1** (vagy a választott nyelvű) fájlt.
2. Hagyd jóvá az **Adminisztrátori** jogkérést.
3. Nyomj **'i'** (igen) gombot a telepítéshez.
4. Használd a jobb klikk: **"Zárolás Feloldása (MotwCleaner)"** opciót bárhol az Intézőben.

--------------------------------

## ⚙️ Technikai részletek / Technical Details

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

### 3. Biztonság (Safety Guard)
A script tartalmaz egy beépített tiltólistát (`BlockedPaths`). Ha a célútvonal megegyezik vagy része egy kritikus rendszermappának (pl. `C:\Windows`, `C:\Program Files`), a futás azonnal leáll, megelőzve a rendszerfájlok véletlen módosítását.

--------------------------------

**Enjoy!** 🚀


