#Requires -Version 7.0
<#
.SYNOPSIS
    Generatore universale di repository (Scaffolding) per Fabry Toolbox.
.DESCRIPTION
    Crea la struttura di supporto (avvia.bat, licenza, git-config, actions)
    per un progetto PowerShell esistente. NON genera il file .ps1 principale,
    che deve essere già presente nella cartella.
#>

Clear-Host
Write-Host "============================================================" -ForegroundColor Green
Write-Host "       FABRY TOOLBOX - REPO BOOTSTRAPPER                    " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""

# 1. Raccolta dati
$RepoName = Read-Host "Inserisci il nome del progetto (es. Video-Upscaler)"
if ([string]::IsNullOrWhiteSpace($RepoName)) {
    Write-Host "Nome non valido. Uscita." -ForegroundColor Red
    return
}

# Gestione parametrica dell'utente GitHub
Write-Host "`nInserisci il tuo username GitHub (premi INVIO per usare 'fabrytoolbox'):" -ForegroundColor Cyan
$InputUser = Read-Host "Username"
if ([string]::IsNullOrWhiteSpace($InputUser)) {
    $GitHubUser = "fabrytoolbox"
} else {
    $GitHubUser = $InputUser
}

$Description = Read-Host "`nInserisci una breve descrizione (per la licenza e i metadati)"
$Year = (Get-Date).Year

# --- NUOVA DOMANDA: Richiede FFmpeg? ---
Write-Host "`nQuesto tool richiede FFmpeg per funzionare? (S/N)" -ForegroundColor Cyan
$NeedsFFmpeg = Read-Host "Scelta"
$IsFFmpegNeeded = $NeedsFFmpeg -match "^[sS]"

# 2. Controllo di sicurezza
Write-Host "`nATTENZIONE: Stai per generare i file di contorno nella cartella corrente:" -ForegroundColor Yellow
Write-Host " -> $(Get-Location)" -ForegroundColor Cyan
Write-Host "Assicurati che il tuo file .ps1 originale sia già qui dentro." -ForegroundColor Yellow
$Confirm = Read-Host "Vuoi procedere? (S/N)"

if ($Confirm -notmatch "^[sS]") {
    Write-Host "Operazione annullata." -ForegroundColor Red
    return
}

Write-Host "`nGenerazione in corso..." -ForegroundColor Yellow

# 3. Generazione file tramite Here-String

# --- avvia.bat (Versione Trampolino Anti-Loop + FFmpeg condizionale) ---
$BatContent = @"
@echo off
REM ============================================================
REM  Launcher per $RepoName.ps1
REM  Versione: 1.0 (Matrix Edition)
REM ============================================================
title $RepoName - Matrix Edition
setlocal
cd /d "%~dp0"

REM --- 1. Controllo PowerShell 7 ---
where pwsh.exe >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo  [ERRORE] PowerShell 7 non trovato!
    echo  Scaricalo da: https://aka.ms/powershell
    echo.
    pause
    exit /b 1
)
"@

if ($IsFFmpegNeeded) {
    $BatContent += @"

REM --- 2. Controllo FFmpeg ---
where ffmpeg.exe >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    if not exist "C:\ffmpeg\bin\ffmpeg.exe" (
        echo.
        echo  [ATTENZIONE] FFmpeg non trovato nel PATH ne' in C:\ffmpeg\bin\
        echo  Il tool potrebbe non funzionare.
        echo.
        echo  Installa con: winget install Gyan.FFmpeg
        echo  oppure scaricalo da: https://ffmpeg.org/download.html
        echo.
        pause
    )
)
"@
}

$BatContent += @"

REM --- 3. Avvio del tool ---
echo.
echo  ============================================================
echo   $RepoName - MATRIX EDITION
echo  ============================================================
echo   Avvio in corso...
echo.
pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0$RepoName.ps1"

REM --- 4. Gestione eventuale errore ---
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo  [ERRORE] Esecuzione terminata con codice %ERRORLEVEL%.
    pause
)
endlocal
"@

$BatContent | Set-Content -Path .\avvia.bat -Encoding ASCII
Write-Host "[OK] avvia.bat (versione trampolino + controllo FFmpeg condizionale)" -ForegroundColor Green


# --- .gitignore (Dinamico) ---
$GitignoreContent = @"
# ============================================================
# $RepoName - .gitignore
# ============================================================

# --- Log generati dal tool ---
*.log
matrix_*_*.log

# --- Configurazione utente (futura) ---
config.json

# --- File temporanei e archivi ---
*.tmp
*.zip
*.7z
*.rar
*.bak
*.old

# --- Sistema operativo ---
Thumbs.db
Thumbs.db:encryptable
ehthumbs.db
Desktop.ini
desktop.ini
`$RECYCLE.BIN/
.DS_Store

# --- Editor / IDE ---
.vscode/
.idea/
*.swp
*.swo
*~
"@

if ($IsFFmpegNeeded) {
    $GitignoreContent += @"

# --- FFmpeg (se scaricato localmente) ---
ffmpeg.exe
ffprobe.exe
ffplay.exe
ffmpeg-*.zip
tools/
"@
}

$GitignoreContent | Set-Content -Path .\.gitignore -Encoding UTF8
Write-Host "[OK] .gitignore (dinamico)" -ForegroundColor Green


# --- .gitattributes ---
@'
* text=auto eol=lf
*.ps1 text eol=crlf
*.psm1 text eol=crlf
*.psd1 text eol=crlf
*.bat text eol=crlf
*.cmd text eol=crlf
*.exe binary
*.dll binary
*.zip binary
*.jpg binary
*.png binary
'@ | Set-Content -Path .\.gitattributes -Encoding UTF8
Write-Host "[OK] .gitattributes" -ForegroundColor Green

# --- LICENSE ---
@"
MIT License

Copyright (c) $Year Fabry Toolbox

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"@ | Set-Content -Path .\LICENSE -Encoding UTF8
Write-Host "[OK] LICENSE" -ForegroundColor Green

# --- CHANGELOG.md ---
@"
# Changelog

## [1.0.0] - $(Get-Date -Format "yyyy-MM-dd")
### Added
- Rilascio iniziale di $RepoName
- GUI Matrix (tema scuro, testo verde)
"@ | Set-Content -Path .\CHANGELOG.md -Encoding UTF8
Write-Host "[OK] CHANGELOG.md" -ForegroundColor Green

# --- .github/workflows/lint.yml ---
New-Item -ItemType Directory -Path .\.github\workflows -Force | Out-Null
@'
name: Lint PowerShell
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:
jobs:
  psscriptanalyzer:
    name: PSScriptAnalyzer
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install PSScriptAnalyzer
        shell: pwsh
        run: |
          Set-PSRepository PSGallery -InstallationPolicy Trusted
          Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
      - name: Run PSScriptAnalyzer
        shell: pwsh
        run: |
          $results = Invoke-ScriptAnalyzer -Path . -Recurse -Severity Error, Warning
          if ($results) { $results | Format-Table -AutoSize; exit 1 }
          Write-Host "Nessun problema rilevato." -ForegroundColor Green
'@ | Set-Content -Path .\.github\workflows\lint.yml -Encoding UTF8
Write-Host "[OK] .github/workflows/lint.yml" -ForegroundColor Green

# --- RIEPILOGO FINALE E COMANDI GIT ---
$GitCommands = @"
git init
git add .
git commit -m "Rilascio iniziale: $RepoName v1.0.0"
git branch -M main
git remote add origin https://github.com/$GitHubUser/$RepoName.git
git push -u origin main
"@

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host " GENERAZIONE COMPLETATA! File di contorno pronti." -ForegroundColor Cyan
Write-Host " RICORDA: Il tuo file $RepoName.ps1 non è stato toccato." -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host " Ora non ti resta che creare il repository su GitHub e lanciare" -ForegroundColor Yellow
Write-Host " questi comandi nel terminale per completare il push:" -ForegroundColor Yellow
Write-Host ""
Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host $GitCommands -ForegroundColor Green
Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""
Write-Host " NOTA: Assicurati di aver creato il repo su GitHub con il nome '$RepoName'" -ForegroundColor DarkYellow
Write-Host " e che il link nel comando 'git remote add' sia corretto." -ForegroundColor DarkYellow
Write-Host "============================================================" -ForegroundColor Cyan