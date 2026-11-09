# Butch-Coolidge-CUE-Splitter.ps1 - v1.0 (Matrix Edition)
# Codename: "Butch Coolidge" (Pulp Fiction)
# Estrattore di tracce audio da file FLAC/CUE.
# Richiede PowerShell 7.2+ e FFmpeg.

#Requires -Version 7.2

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$script:logFile = $null
$global:ffmpegPath = $null

# ============================================================
# LOGGING
# ============================================================
function Start-Log {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $script:logFile = Join-Path $scriptPath "butch_coolidge_splitter_$timestamp.log"
    @(
        "============================================================",
        " BUTCH COOLIDGE CUE SPLITTER v1.0 - LOG",
        "============================================================",
        "Data inizio: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
        "PowerShell : $($PSVersionTable.PSVersion)",
        "============================================================",
        ""
    ) | Set-Content -Path $script:logFile -Encoding UTF8
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    if (-not $script:logFile) { return }
    $line = "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message"
    Add-Content -Path $script:logFile -Value $line -Encoding UTF8
}

Start-Log

# ============================================================
# CONTROLLO FFMPEG
# ============================================================
function Test-FFmpeg {
    $cmd = Get-Command ffmpeg.exe -ErrorAction SilentlyContinue
    if (-not $cmd) {
        $commonPaths = @(
            "$env:ProgramFiles\ffmpeg\bin\ffmpeg.exe",
            "$env:LOCALAPPDATA\Microsoft\WinGet\Links\ffmpeg.exe",
            "C:\ffmpeg\bin\ffmpeg.exe"
        )
        foreach ($p in $commonPaths) {
            if (Test-Path $p) { $cmd = Get-Item $p; break }
        }
    }
    if ($cmd) { $global:ffmpegPath = $cmd.Source; return $true } 
    else { return $false }
}

# ============================================================
# INTERFACCIA GRAFICA
# ============================================================
$form = New-Object System.Windows.Forms.Form
$form.Text            = "BUTCH COOLIDGE CUE SPLITTER v1.0"
$form.Size            = New-Object System.Drawing.Size(800, 680)
$form.StartPosition   = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox     = $false
$form.BackColor       = [System.Drawing.Color]::Black
$form.ForeColor       = [System.Drawing.Color]::Lime
$form.Font            = New-Object System.Drawing.Font("Consolas", 10)

# Header
$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text      = "BUTCH COOLIDGE CUE SPLITTER v1.0"
$lblTitle.ForeColor = [System.Drawing.Color]::Lime
$lblTitle.Font      = New-Object System.Drawing.Font("Consolas", 16, [System.Drawing.FontStyle]::Bold)
$lblTitle.Location  = New-Object System.Drawing.Point(20, 15)
$lblTitle.Size      = New-Object System.Drawing.Size(760, 30)
$form.Controls.Add($lblTitle)

$lblSubtitle = New-Object System.Windows.Forms.Label
$lblSubtitle.Text      = ":: ESTRATTORE DI TRACCE DA FLAC/CUE : MATRIX EDITION ::"
$lblSubtitle.ForeColor = [System.Drawing.Color]::FromArgb(0, 180, 0)
$lblSubtitle.Font      = New-Object System.Drawing.Font("Consolas", 9)
$lblSubtitle.Location  = New-Object System.Drawing.Point(20, 50)
$lblSubtitle.Size      = New-Object System.Drawing.Size(760, 18)
$form.Controls.Add($lblSubtitle)

# --- SELEZIONE FILE FLAC ---
$lblFlac = New-Object System.Windows.Forms.Label
$lblFlac.Text = "File FLAC:"; $lblFlac.Location = New-Object System.Drawing.Point(20, 85)
$lblFlac.Size = New-Object System.Drawing.Size(100, 20); $form.Controls.Add($lblFlac)

$global:txtFlac = New-Object System.Windows.Forms.TextBox
$global:txtFlac.Location = New-Object System.Drawing.Point(130, 82); $global:txtFlac.Size = New-Object System.Drawing.Size(530, 26)
$global:txtFlac.BackColor = [System.Drawing.Color]::Black; $global:txtFlac.ForeColor = [System.Drawing.Color]::Lime
$form.Controls.Add($global:txtFlac)

$global:btnBrowseFlac = New-Object System.Windows.Forms.Button
$global:btnBrowseFlac.Text = "SFOGLIA"; $global:btnBrowseFlac.Location = New-Object System.Drawing.Point(670, 80)
$global:btnBrowseFlac.Size = New-Object System.Drawing.Size(100, 30); $global:btnBrowseFlac.FlatStyle = "Flat"
$global:btnBrowseFlac.ForeColor = [System.Drawing.Color]::Lime; $global:btnBrowseFlac.FlatAppearance.BorderColor = [System.Drawing.Color]::Lime
$form.Controls.Add($global:btnBrowseFlac)

# --- SELEZIONE FILE CUE ---
$lblCue = New-Object System.Windows.Forms.Label
$lblCue.Text = "File CUE:"; $lblCue.Location = New-Object System.Drawing.Point(20, 125)
$lblCue.Size = New-Object System.Drawing.Size(100, 20); $form.Controls.Add($lblCue)

$global:txtCue = New-Object System.Windows.Forms.TextBox
$global:txtCue.Location = New-Object System.Drawing.Point(130, 122); $global:txtCue.Size = New-Object System.Drawing.Size(530, 26)
$global:txtCue.BackColor = [System.Drawing.Color]::Black; $global:txtCue.ForeColor = [System.Drawing.Color]::Lime
$form.Controls.Add($global:txtCue)

$global:btnBrowseCue = New-Object System.Windows.Forms.Button
$global:btnBrowseCue.Text = "SFOGLIA"; $global:btnBrowseCue.Location = New-Object System.Drawing.Point(670, 120)
$global:btnBrowseCue.Size = New-Object System.Drawing.Size(100, 30); $global:btnBrowseCue.FlatStyle = "Flat"
$global:btnBrowseCue.ForeColor = [System.Drawing.Color]::Lime; $global:btnBrowseCue.FlatAppearance.BorderColor = [System.Drawing.Color]::Lime
$form.Controls.Add($global:btnBrowseCue)

# --- CARTELLA DESTINAZIONE ---
$lblDest = New-Object System.Windows.Forms.Label
$lblDest.Text = "Destinazione:"; $lblDest.Location = New-Object System.Drawing.Point(20, 165)
$lblDest.Size = New-Object System.Drawing.Size(100, 20); $form.Controls.Add($lblDest)

$global:txtDest = New-Object System.Windows.Forms.TextBox
$global:txtDest.Location = New-Object System.Drawing.Point(130, 162); $global:txtDest.Size = New-Object System.Drawing.Size(530, 26)
$global:txtDest.BackColor = [System.Drawing.Color]::Black; $global:txtDest.ForeColor = [System.Drawing.Color]::Lime
$form.Controls.Add($global:txtDest)

$global:btnBrowseDest = New-Object System.Windows.Forms.Button
$global:btnBrowseDest.Text = "SFOGLIA"; $global:btnBrowseDest.Location = New-Object System.Drawing.Point(670, 160)
$global:btnBrowseDest.Size = New-Object System.Drawing.Size(100, 30); $global:btnBrowseDest.FlatStyle = "Flat"
$global:btnBrowseDest.ForeColor = [System.Drawing.Color]::Lime; $global:btnBrowseDest.FlatAppearance.BorderColor = [System.Drawing.Color]::Lime
$form.Controls.Add($global:btnBrowseDest)

# --- PULSANTI AZIONE ---
$global:btnSplit = New-Object System.Windows.Forms.Button
$global:btnSplit.Text = "▶  ESTRAI TRACCE"
$global:btnSplit.Location = New-Object System.Drawing.Point(20, 210)
$global:btnSplit.Size = New-Object System.Drawing.Size(750, 45)
$global:btnSplit.FlatStyle = "Flat"
$global:btnSplit.BackColor = [System.Drawing.Color]::Black
$global:btnSplit.ForeColor = [System.Drawing.Color]::Lime
$global:btnSplit.FlatAppearance.BorderColor = [System.Drawing.Color]::Lime
$global:btnSplit.FlatAppearance.BorderSize = 2
$global:btnSplit.Font = New-Object System.Drawing.Font("Consolas", 12, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($global:btnSplit)

# --- LOG ---
$global:txtLog = New-Object System.Windows.Forms.TextBox
$global:txtLog.Multiline = $true; $global:txtLog.ScrollBars = "Vertical"; $global:txtLog.ReadOnly = $true
$global:txtLog.BackColor = [System.Drawing.Color]::FromArgb(10, 10, 10); $global:txtLog.ForeColor = [System.Drawing.Color]::Lime
$global:txtLog.Font = New-Object System.Drawing.Font("Consolas", 9)
$global:txtLog.Location = New-Object System.Drawing.Point(20, 270); $global:txtLog.Size = New-Object System.Drawing.Size(750, 320)
$global:txtLog.BorderStyle = "FixedSingle"
$form.Controls.Add($global:txtLog)

function Write-ScreenLog {
    param([string]$Message, [string]$Color = "Lime")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $global:txtLog.AppendText("[$timestamp] $Message`r`n")
    $global:txtLog.SelectionStart = $global:txtLog.Text.Length
    $global:txtLog.ScrollToCaret()
    Write-Log $Message "INFO"
}

# --- STATUS BAR E EXIT ---
$global:lblStatus = New-Object System.Windows.Forms.Label
$global:lblStatus.Text = "> Pronto. Seleziona i file."
$global:lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(0, 200, 0)
$global:lblStatus.Font = New-Object System.Drawing.Font("Consolas", 11, [System.Drawing.FontStyle]::Bold)
$global:lblStatus.Location = New-Object System.Drawing.Point(20, 605); $global:lblStatus.Size = New-Object System.Drawing.Size(600, 25)
$form.Controls.Add($global:lblStatus)

$btnExit = New-Object System.Windows.Forms.Button
$btnExit.Text = "EXIT"; $btnExit.Location = New-Object System.Drawing.Point(660, 600)
$btnExit.Size = New-Object System.Drawing.Size(110, 30); $btnExit.FlatStyle = "Flat"
$btnExit.BackColor = [System.Drawing.Color]::Black; $btnExit.ForeColor = [System.Drawing.Color]::Red
$btnExit.FlatAppearance.BorderColor = [System.Drawing.Color]::Red
$btnExit.Add_Click({ $form.Close() })
$form.Controls.Add($btnExit)
# ---------------------------------------------------
# 						primo blocco
# ---------------------------------------------------
# ============================================================
# FUNZIONE DI PARSING DEL FILE CUE
# ============================================================
function Parse-CueFile {
    param([string]$CuePath)

    if (-not (Test-Path $CuePath)) {
        Write-ScreenLog "File CUE non trovato: $CuePath" "Red"
        return $null
    }

    Write-ScreenLog "Lettura del file CUE in corso..." "Cyan"
    $lines = Get-Content -Path $CuePath -Encoding UTF8
    $tracks = @()
    $currentArtist = "Unknown Artist"
    $currentAlbum = "Unknown Album"
    $currentTrack = $null

    foreach ($line in $lines) {
        $line = $line.Trim()
        
        # Se la riga è vuota, salta
        if ([string]::IsNullOrWhiteSpace($line)) { continue }

        # Inizio di una nuova traccia
        if ($line -match '^TRACK\s+(\d+)\s+AUDIO') {
            $trackNum = [int]$Matches[1]
            $currentTrack = [PSCustomObject]@{
                Number  = $trackNum
                Title   = ""
                Artist  = $currentArtist
                Album   = $currentAlbum
                StartMs = 0
                EndMs   = 0
            }
            $tracks += $currentTrack
        }
        # Titolo della traccia (se siamo dentro una traccia)
        elseif ($line -match '^TITLE\s+"(.+)"') {
            if ($currentTrack) {
                # Se il titolo della traccia è vuoto, assegniamolo
                if ([string]::IsNullOrWhiteSpace($currentTrack.Title)) {
                    $currentTrack.Title = $Matches[1]
                }
            } else {
                # Altrimenti è il titolo dell'album
                $currentAlbum = $Matches[1]
            }
        }
        # Performer (artista)
        elseif ($line -match '^PERFORMER\s+"(.+)"') {
            if ($currentTrack) {
                $currentTrack.Artist = $Matches[1]
            } else {
                $currentArtist = $Matches[1]
            }
        }
        # Tempo di inizio (INDEX 01 mm:ss:ff)
        elseif ($line -match '^INDEX\s+01\s+(\d+):(\d+):(\d+)') {
            if ($currentTrack) {
                $min = [int]$Matches[1]
                $sec = [int]$Matches[2]
                $frames = [int]$Matches[3]
                $ms = ($min * 60 * 1000) + ($sec * 1000) + [math]::Round(($frames / 75) * 1000)
                $currentTrack.StartMs = $ms
            }
        }
    }

    # Calcolo dei tempi di fine
    for ($i = 0; $i -lt $tracks.Count; $i++) {
        if ($i -lt ($tracks.Count - 1)) {
            $tracks[$i].EndMs = $tracks[$i+1].StartMs
        } else {
            $tracks[$i].EndMs = -1 
        }
    }

    # Se un titolo è vuoto, usa "Track N" come fallback
    foreach ($track in $tracks) {
        if ([string]::IsNullOrWhiteSpace($track.Title)) {
            $track.Title = "Track $($track.Number)"
        }
        if ([string]::IsNullOrWhiteSpace($track.Album)) {
            $track.Album = $currentAlbum
        }
        if ([string]::IsNullOrWhiteSpace($track.Artist)) {
            $track.Artist = $currentArtist
        }
    }

    Write-ScreenLog "Trovate $($tracks.Count) tracce nel file CUE." "Lime"
    return $tracks
}

# ============================================================
# FUNZIONE DI ESTRAZIONE (FFmpeg)
# ============================================================
function Extract-Tracks {
    param(
        [string]$FlacPath,
        [string]$CuePath,
        [string]$DestinationFolder
    )

    # 1. Parsing del CUE
    $tracks = Parse-CueFile -CuePath $CuePath
    if (-not $tracks -or $tracks.Count -eq 0) {
        Write-ScreenLog "Impossibile estrarre le tracce. Il file CUE potrebbe essere vuoto o non valido." "Red"
        return
    }

    # 2. Crea la cartella di destinazione se non esiste
    if (-not (Test-Path $DestinationFolder)) {
        try {
            New-Item -ItemType Directory -Path $DestinationFolder -Force | Out-Null
            Write-ScreenLog "Creata cartella di destinazione: $DestinationFolder" "Cyan"
        } catch {
            Write-ScreenLog "Impossibile creare la cartella: $($_.Exception.Message)" "Red"
            return
        }
    }

    # 3. Ottieni la durata totale del file FLAC (per l'ultima traccia)
    $totalDurationMs = 0
    try {
        # Usiamo ffprobe (incluso con ffmpeg) per leggere la durata
        $ffprobePath = $global:ffmpegPath -replace 'ffmpeg\.exe$', 'ffprobe.exe'
        $args = "-v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 `"$FlacPath`""
        $durationSec = & $ffprobePath $args 2>&1
        if ($durationSec -match '^\d+\.\d+$') {
            $totalDurationMs = [math]::Round([double]$durationSec * 1000)
        }
    } catch {
        Write-ScreenLog "Impossibile leggere la durata totale del FLAC. L'ultima traccia potrebbe fallire." "Yellow"
    }

    # Se l'ultima traccia ha EndMs = -1, impostiamo la durata totale
    if ($tracks[-1].EndMs -eq -1 -and $totalDurationMs -gt 0) {
        $tracks[-1].EndMs = $totalDurationMs
    }

    # 4. Ciclo di estrazione
    $total = $tracks.Count
    $current = 0
    $successCount = 0
    $errorCount = 0

    foreach ($track in $tracks) {
        $current++
        
        # Costruzione del nome file (es. "01 - Titolo.flac")
        $safeTitle = $track.Title -replace '[<>:"/\\|?*]', ''
        if (-not $safeTitle) { $safeTitle = "Track $($track.Number)" }
        $fileName = "{0:D2} - {1}.flac" -f $track.Number, $safeTitle
        $outputPath = Join-Path $DestinationFolder $fileName

        # Calcolo durata in secondi (FFmpeg usa i secondi con i decimali)
        $startSec = $track.StartMs / 1000.0
        $endSec = $track.EndMs / 1000.0
        $durationSec = $endSec - $startSec

        Write-ScreenLog "[$current/$total] Estrazione: $fileName" "Lime"

        # Costruzione comando FFmpeg
        # -ss: inizio, -t: durata, -c copy: nessuna ricodifica, -metadata: tag ID3
        # Calcolo durata in secondi (FFmpeg usa i secondi con i decimali)
        $startSec = $track.StartMs / 1000.0
        
        $ffmpegArgs = @(
            "-ss", "$startSec",
            "-i", "`"$FlacPath`"",
            "-c:a", "flac",
            "-compression_level", "0",
            "-metadata", "title=`"$($track.Title)`"",
            "-metadata", "artist=`"$($track.Artist)`"",
            "-metadata", "album=`"$($track.Album)`"",
            "-metadata", "track=$($track.Number)",
            "-y",
            "`"$outputPath`""
        )
        
        # Se non è l'ultima traccia, aggiungiamo la durata (-t)
        if ($current -lt $total) {
            $endSec = $track.EndMs / 1000.0
            $durationSec = $endSec - $startSec
            # Inserisce -t subito dopo -ss
            $ffmpegArgs = @("-ss", "$startSec", "-t", "$durationSec") + $ffmpegArgs[2..($ffmpegArgs.Count - 1)]
        }
        
        $ffmpegArgs = $ffmpegArgs -join " "

        # Esecuzione FFmpeg
        try {
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = $global:ffmpegPath
            $psi.Arguments = $ffmpegArgs
            $psi.UseShellExecute = $false
            $psi.CreateNoWindow = $true
            $psi.RedirectStandardError = $true
            $psi.RedirectStandardOutput = $true
            
            $proc = New-Object System.Diagnostics.Process
            $proc.StartInfo = $psi
            $proc.Start() | Out-Null
            $proc.WaitForExit()

            if ($proc.ExitCode -eq 0) {
                $successCount++
                Write-ScreenLog "  [OK] Estratto con successo." "Green"
            } else {
                $errorCount++
                Write-ScreenLog "  [ERRORE] FFmpeg ha restituito codice $($proc.ExitCode)" "Red"
            }
        } catch {
            $errorCount++
            Write-ScreenLog "  [ERRORE CRITICO] $($_.Exception.Message)" "Red"
        }
    }

    # 5. Riepilogo finale
    Write-ScreenLog "============================================================" "Cyan"
    Write-ScreenLog " RIEPILOGO ESTRAZIONE" "Cyan"
    Write-ScreenLog " Tracce totali: $total" "White"
    Write-ScreenLog " Successi:      $successCount" "Green"
    Write-ScreenLog " Errori:        $errorCount" "Red"
    Write-ScreenLog "============================================================" "Cyan"
}
# ---------------------------------------------------
# 					secondo blocco
# ---------------------------------------------------
# ============================================================
# EVENTI DELLA GUI
# ============================================================

# SFOGLIA FILE FLAC
$global:btnBrowseFlac.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = "Seleziona il file FLAC dell'album"
    $dialog.Filter = "File FLAC|*.flac|Tutti i file|*.*"
    if ($dialog.ShowDialog() -eq "OK") {
        $global:txtFlac.Text = $dialog.FileName
        # Auto-compila la cartella di destinazione (sottocartella "Estratti")
        if (-not $global:txtDest.Text) {
            $parentDir = [System.IO.Path]::GetDirectoryName($dialog.FileName)
            $global:txtDest.Text = Join-Path $parentDir "Estratti"
        }
    }
})

# SFOGLIA FILE CUE
$global:btnBrowseCue.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = "Seleziona il file CUE"
    $dialog.Filter = "File CUE|*.cue|Tutti i file|*.*"
    if ($dialog.ShowDialog() -eq "OK") {
        $global:txtCue.Text = $dialog.FileName
    }
})

# SFOGLIA CARTELLA DESTINAZIONE
$global:btnBrowseDest.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "Seleziona la cartella di destinazione"
    if ($dialog.ShowDialog() -eq "OK") {
        $global:txtDest.Text = $dialog.SelectedPath
    }
})

# AVVIA ESTRAZIONE
$global:btnSplit.Add_Click({
    $flacPath = $global:txtFlac.Text.Trim()
    $cuePath = $global:txtCue.Text.Trim()
    $destFolder = $global:txtDest.Text.Trim()

    # Validazione input
    if (-not $flacPath -or -not (Test-Path $flacPath)) {
        [System.Windows.Forms.MessageBox]::Show("Seleziona un file FLAC valido.", "MATRIX - ATTENZIONE", "OK", "Warning") | Out-Null
        return
    }
    if (-not $cuePath -or -not (Test-Path $cuePath)) {
        [System.Windows.Forms.MessageBox]::Show("Seleziona un file CUE valido.", "MATRIX - ATTENZIONE", "OK", "Warning") | Out-Null
        return
    }
    if (-not $destFolder) {
        [System.Windows.Forms.MessageBox]::Show("Seleziona una cartella di destinazione.", "MATRIX - ATTENZIONE", "OK", "Warning") | Out-Null
        return
    }

    # Disabilita UI
    $global:btnSplit.Enabled = $false
    $global:btnSplit.Text = "ESTRAZIONE IN CORSO..."
    $global:btnSplit.ForeColor = [System.Drawing.Color]::Yellow
    $global:btnSplit.FlatAppearance.BorderColor = [System.Drawing.Color]::Yellow
    $global:txtLog.Clear()
    $global:lblStatus.Text = "> Estrazione in corso..."
    $form.Refresh()

    # Chiamata alla funzione di estrazione
    Extract-Tracks -FlacPath $flacPath -CuePath $cuePath -DestinationFolder $destFolder

    # Ripristina UI
    $global:btnSplit.Enabled = $true
    $global:btnSplit.Text = "▶  ESTRAI TRACCE"
    $global:btnSplit.ForeColor = [System.Drawing.Color]::Lime
    $global:btnSplit.FlatAppearance.BorderColor = [System.Drawing.Color]::Lime
    $global:lblStatus.Text = "> Estrazione completata."

    # Apri la cartella di destinazione alla fine
    if (Test-Path $destFolder) {
        Start-Process explorer.exe -ArgumentList $destFolder
    }
})

# ============================================================
# AVVIO FORM
# ============================================================
$form.Add_Load({
    Write-ScreenLog "MATRIX BUTCH COOLIDGE CUE SPLITTER v1.0 avviato." "Lime"
    Write-ScreenLog "Log file: $(Split-Path $script:logFile -Leaf)" "Cyan"
    Write-ScreenLog "PowerShell: $($PSVersionTable.PSVersion)" "Cyan"
    
    # Controllo FFmpeg
    if (Test-FFmpeg) {
        Write-ScreenLog "FFmpeg trovato: $($global:ffmpegPath)" "Cyan"
        $global:lblStatus.Text = "> Pronto. Seleziona i file."
    } else {
        Write-ScreenLog "ERRORE CRITICO: FFmpeg non trovato nel sistema!" "Red"
        [System.Windows.Forms.MessageBox]::Show("FFmpeg non e' stato trovato.`nInstalla con: winget install Gyan.FFmpeg", "MATRIX - ERRORE", "OK", "Error") | Out-Null
        $global:btnSplit.Enabled = $false
        $global:btnSplit.ForeColor = [System.Drawing.Color]::Gray
        $global:btnSplit.FlatAppearance.BorderColor = [System.Drawing.Color]::Gray
        $global:lblStatus.Text = "> Errore: FFmpeg mancante."
    }
})

# Avvio della GUI
[void]$form.ShowDialog()
