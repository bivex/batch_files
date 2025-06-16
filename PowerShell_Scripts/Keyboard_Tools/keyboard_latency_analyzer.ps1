# Keyboard Latency Analyzer for Professional Programming
# This script analyzes keyboard latency and performance metrics

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create log file
$logFile = "keyboard_analyzer_log.txt"
"Starting Keyboard Latency Analyzer at $(Get-Date)" | Out-File $logFile

# Function to log debug information
function Write-Log {
    param(
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    "$timestamp - $Message" | Out-File $logFile -Append
    Write-Host $Message
}

Write-Log "Initializing form..."

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Keyboard Latency Analyzer"
$form.Size = New-Object System.Drawing.Size(800, 600)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::White
$form.KeyPreview = $true  # Enable key preview for the form

Write-Log "Creating controls..."

# Create rich text box for results
$resultsBox = New-Object System.Windows.Forms.RichTextBox
$resultsBox.Location = New-Object System.Drawing.Point(20, 20)
$resultsBox.Size = New-Object System.Drawing.Size(740, 400)
$resultsBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$resultsBox.ReadOnly = $true
$resultsBox.BackColor = [System.Drawing.Color]::White
$form.Controls.Add($resultsBox)

# Create start button
$startButton = New-Object System.Windows.Forms.Button
$startButton.Location = New-Object System.Drawing.Point(20, 440)
$startButton.Size = New-Object System.Drawing.Size(120, 30)
$startButton.Text = "Start Analysis"
$startButton.BackColor = [System.Drawing.Color]::LightGray
$form.Controls.Add($startButton)

# Create export button
$exportButton = New-Object System.Windows.Forms.Button
$exportButton.Location = New-Object System.Drawing.Point(160, 440)
$exportButton.Size = New-Object System.Drawing.Size(120, 30)
$exportButton.Text = "Export Results"
$exportButton.BackColor = [System.Drawing.Color]::LightGray
$exportButton.Enabled = $false
$form.Controls.Add($exportButton)

# Create progress bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, 480)
$progressBar.Size = New-Object System.Drawing.Size(740, 20)
$progressBar.Style = "Continuous"
$form.Controls.Add($progressBar)

# Create instruction label
$instructionLabel = New-Object System.Windows.Forms.Label
$instructionLabel.Location = New-Object System.Drawing.Point(20, 520)
$instructionLabel.Size = New-Object System.Drawing.Size(740, 40)
$instructionLabel.Text = "Press any key when prompted to test keyboard latency"
$instructionLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$form.Controls.Add($instructionLabel)

Write-Log "Initializing variables..."

# Variables to store analysis results
$script:keyLatency = @()
$script:keyRepeatRate = @()
$script:keyDebounceTime = @()
$script:keyResponseTime = @()
$script:keyGhosting = @()
$script:analysisComplete = $false
$script:keyPressed = $false
$script:keyPressTime = $null
$script:keyReleaseTime = $null
$script:keyCount = 0
$script:testInProgress = $false
$script:currentTest = ""

# Function to log results
function Write-Result {
    param(
        [string]$Message,
        [string]$Color = "Black"
    )
    Write-Log "Result: $Message"
    $resultsBox.SelectionStart = $resultsBox.TextLength
    $resultsBox.SelectionLength = 0
    $resultsBox.SelectionColor = $Color
    $resultsBox.AppendText("$Message`r`n")
    $resultsBox.ScrollToCaret()
}

# Function to handle key press
function Handle-KeyPress {
    param($sender, $e)
    
    Write-Log "Key pressed: $($e.KeyCode) - Test in progress: $script:testInProgress - Current test: $script:currentTest"
    
    if (-not $script:testInProgress) { 
        Write-Log "Ignoring key press - test not in progress"
        return 
    }
    
    if (-not $script:keyPressed) {
        $script:keyPressed = $true
        $script:keyPressTime = Get-Date
        $script:keyCount++
        Write-Log "Key press registered at $script:keyPressTime"
    }
}

# Function to handle key release
function Handle-KeyRelease {
    param($sender, $e)
    
    Write-Log "Key released: $($e.KeyCode) - Test in progress: $script:testInProgress - Current test: $script:currentTest"
    
    if (-not $script:testInProgress) { 
        Write-Log "Ignoring key release - test not in progress"
        return 
    }
    
    if ($script:keyPressed) {
        $script:keyPressed = $false
        $script:keyReleaseTime = Get-Date
        Write-Log "Key release registered at $script:keyReleaseTime"
    }
}

# Function to test key latency
function Test-KeyLatency {
    Write-Log "Starting key latency test..."
    $script:currentTest = "KeyLatency"
    Write-Result "`nTesting key latency..." "Blue"
    $script:keyLatency = @()
    $script:testInProgress = $true
    
    for ($i = 1; $i -le 10; $i++) {
        Write-Log "Starting latency test $i of 10"
        Write-Result "Press any key $i of 10..."
        $script:keyPressed = $false
        $script:keyPressTime = $null
        $script:startTime = Get-Date
        
        Write-Log "Waiting for key press..."
        while (-not $script:keyPressed) {
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 10
        }
        
        $latency = ($script:keyPressTime - $script:startTime).TotalMilliseconds
        Write-Log "Latency measured: $latency ms"
        $script:keyLatency += $latency
        Write-Result "Key latency: $latency ms"
        Start-Sleep -Milliseconds 500
    }
    
    $avgLatency = ($script:keyLatency | Measure-Object -Average).Average
    Write-Log "Average latency: $avgLatency ms"
    Write-Result "Average key latency: $avgLatency ms" "Green"
    $script:testInProgress = $false
    $script:currentTest = ""
}

# Function to test key repeat rate
function Test-KeyRepeatRate {
    Write-Log "Starting key repeat rate test..."
    $script:currentTest = "KeyRepeatRate"
    Write-Result "`nTesting key repeat rate..." "Blue"
    $script:keyRepeatRate = @()
    $script:testInProgress = $true
    $script:keyCount = 0
    
    Write-Result "Hold down any key for 2 seconds..."
    $startTime = Get-Date
    $endTime = $startTime.AddSeconds(2)
    
    Write-Log "Waiting for key presses..."
    while ((Get-Date) -lt $endTime) {
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 10
    }
    
    $repeatRate = $script:keyCount / 2 # repeats per second
    Write-Log "Repeat rate measured: $repeatRate Hz"
    $script:keyRepeatRate = $repeatRate
    Write-Result "Key repeat rate: $repeatRate Hz" "Green"
    $script:testInProgress = $false
    $script:currentTest = ""
}

# Function to test key debounce time
function Test-KeyDebounce {
    Write-Log "Starting key debounce test..."
    $script:currentTest = "KeyDebounce"
    Write-Result "`nTesting key debounce time..." "Blue"
    $script:keyDebounceTime = @()
    $script:testInProgress = $true
    
    for ($i = 1; $i -le 5; $i++) {
        Write-Log "Starting debounce test $i of 5"
        Write-Result "Press and release any key quickly $i of 5..."
        $script:keyPressed = $false
        $script:keyPressTime = $null
        $script:keyReleaseTime = $null
        
        Write-Log "Waiting for key press and release..."
        while (-not $script:keyReleaseTime) {
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 10
        }
        
        $debounceTime = ($script:keyReleaseTime - $script:keyPressTime).TotalMilliseconds
        Write-Log "Debounce time measured: $debounceTime ms"
        $script:keyDebounceTime += $debounceTime
        Write-Result "Debounce time: $debounceTime ms"
        Start-Sleep -Milliseconds 500
    }
    
    $avgDebounce = ($script:keyDebounceTime | Measure-Object -Average).Average
    Write-Log "Average debounce time: $avgDebounce ms"
    Write-Result "Average debounce time: $avgDebounce ms" "Green"
    $script:testInProgress = $false
    $script:currentTest = ""
}

# Function to test key response time
function Test-KeyResponse {
    Write-Log "Starting key response test..."
    $script:currentTest = "KeyResponse"
    Write-Result "`nTesting key response time..." "Blue"
    $script:keyResponseTime = @()
    $script:testInProgress = $true
    
    for ($i = 1; $i -le 10; $i++) {
        Write-Log "Starting response test $i of 10"
        Write-Result "Press any key $i of 10..."
        $script:keyPressed = $false
        $script:keyPressTime = $null
        $script:startTime = Get-Date
        
        Write-Log "Waiting for key press..."
        while (-not $script:keyPressed) {
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 10
        }
        
        $responseTime = ($script:keyPressTime - $script:startTime).TotalMilliseconds
        Write-Log "Response time measured: $responseTime ms"
        $script:keyResponseTime += $responseTime
        Write-Result "Response time: $responseTime ms"
        Start-Sleep -Milliseconds 500
    }
    
    $avgResponse = ($script:keyResponseTime | Measure-Object -Average).Average
    Write-Log "Average response time: $avgResponse ms"
    Write-Result "Average response time: $avgResponse ms" "Green"
    $script:testInProgress = $false
    $script:currentTest = ""
}

# Function to test key ghosting
function Test-KeyGhosting {
    Write-Log "Starting key ghosting test..."
    $script:currentTest = "KeyGhosting"
    Write-Result "`nTesting key ghosting..." "Blue"
    $script:keyGhosting = @()
    $script:testInProgress = $true
    $script:keyCount = 0
    
    Write-Result "Press multiple keys simultaneously (up to 6 keys)..."
    $startTime = Get-Date
    $endTime = $startTime.AddSeconds(3)
    
    Write-Log "Waiting for key presses..."
    while ((Get-Date) -lt $endTime) {
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 10
    }
    
    $ghostingScore = $script:keyCount
    Write-Log "Ghosting score measured: $ghostingScore"
    $script:keyGhosting = $ghostingScore
    Write-Result "Key ghosting score: $ghostingScore keys" "Green"
    $script:testInProgress = $false
    $script:currentTest = ""
}

# Function to run full analysis
function Start-Analysis {
    Write-Log "Starting full analysis..."
    $resultsBox.Clear()
    Write-Result "Starting Keyboard Latency Analysis..." "Blue"
    Write-Result "===========================================" "Blue"
    Write-Result "Please follow the on-screen instructions for each test."
    Write-Result "Press keys naturally during the tests."
    Write-Result "===========================================" "Blue"
    
    $progressBar.Value = 0
    $startButton.Enabled = $false
    $exportButton.Enabled = $false
    
    try {
        $script:startTime = Get-Date
        Write-Log "Running key latency test..."
        Test-KeyLatency
        $progressBar.Value = 20
        
        Write-Log "Running key repeat rate test..."
        Test-KeyRepeatRate
        $progressBar.Value = 40
        
        Write-Log "Running key debounce test..."
        Test-KeyDebounce
        $progressBar.Value = 60
        
        Write-Log "Running key response test..."
        Test-KeyResponse
        $progressBar.Value = 80
        
        Write-Log "Running key ghosting test..."
        Test-KeyGhosting
        $progressBar.Value = 100
        
        $script:analysisComplete = $true
        $exportButton.Enabled = $true
        
        # Generate recommendations
        Write-Result "`nAnalysis Complete!" "Green"
        Write-Result "Total analysis time: $((Get-Date).Subtract($script:startTime).TotalSeconds) seconds" "Green"
        Write-Result "`nRecommendations:" "Yellow"
        
        $avgLatency = ($script:keyLatency | Measure-Object -Average).Average
        if ($avgLatency -gt 50) {
            Write-Result "- High key latency detected. Consider checking keyboard drivers or USB port." "Red"
        }
        
        $avgResponse = ($script:keyResponseTime | Measure-Object -Average).Average
        if ($avgResponse -gt 30) {
            Write-Result "- High response time detected. Try using a USB 3.0 port." "Red"
        }
        
        if ($script:keyGhosting -lt 4) {
            Write-Result "- Low key ghosting score. Consider a keyboard with better anti-ghosting." "Red"
        }
        
        if ($script:keyRepeatRate -lt 10) {
            Write-Result "- Low key repeat rate. Check keyboard settings in Windows." "Red"
        }
    }
    catch {
        Write-Log "Error during analysis: $($_.Exception.Message)"
        Write-Log "Stack trace: $($_.Exception.StackTrace)"
        Write-Result "Error during analysis: $($_.Exception.Message)" "Red"
    }
    finally {
        $startButton.Enabled = $true
        $script:testInProgress = $false
        $script:currentTest = ""
    }
}

# Function to export results
function Export-Results {
    Write-Log "Exporting results..."
    if (-not $script:analysisComplete) {
        Write-Result "Please run the analysis first." "Red"
        return
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $filename = "keyboard_latency_results_$timestamp.csv"
    
    $results = @"
Timestamp,Test,Value,Unit
$timestamp,Key Latency,$(($script:keyLatency | Measure-Object -Average).Average),ms
$timestamp,Key Repeat Rate,$script:keyRepeatRate,Hz
$timestamp,Key Debounce Time,$(($script:keyDebounceTime | Measure-Object -Average).Average),ms
$timestamp,Key Response Time,$(($script:keyResponseTime | Measure-Object -Average).Average),ms
$timestamp,Key Ghosting Score,$script:keyGhosting,keys
"@
    
    $results | Out-File -FilePath $filename -Encoding UTF8
    Write-Log "Results exported to $filename"
    Write-Result "`nResults exported to $filename" "Green"
}

Write-Log "Adding event handlers..."

# Add event handlers
$form.Add_KeyDown({ Handle-KeyPress $this $args[1] })
$form.Add_KeyUp({ Handle-KeyRelease $this $args[1] })
$startButton.Add_Click({ Start-Analysis })
$exportButton.Add_Click({ Export-Results })

Write-Log "Showing form..."

# Show the form
$form.ShowDialog()

Write-Log "Form closed" 