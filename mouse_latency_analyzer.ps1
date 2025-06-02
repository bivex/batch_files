# Mouse Latency Analyzer for Logitech MX Master 3S
# This script analyzes mouse latency, polling rate, and movement precision

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create a form for the analyzer
$form = New-Object System.Windows.Forms.Form
$form.Text = "MX Master 3S Latency Analyzer"
$form.Size = New-Object System.Drawing.Size(800, 600)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::White

# Create a rich text box for results
$resultsBox = New-Object System.Windows.Forms.RichTextBox
$resultsBox.Location = New-Object System.Drawing.Point(20, 20)
$resultsBox.Size = New-Object System.Drawing.Size(740, 400)
$resultsBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$resultsBox.ReadOnly = $true
$form.Controls.Add($resultsBox)

# Create a button to start analysis
$startButton = New-Object System.Windows.Forms.Button
$startButton.Location = New-Object System.Drawing.Point(20, 440)
$startButton.Size = New-Object System.Drawing.Size(200, 40)
$startButton.Text = "Start Analysis"
$form.Controls.Add($startButton)

# Create a button to export results
$exportButton = New-Object System.Windows.Forms.Button
$exportButton.Location = New-Object System.Drawing.Point(240, 440)
$exportButton.Size = New-Object System.Drawing.Size(200, 40)
$exportButton.Text = "Export Results"
$exportButton.Enabled = $false
$form.Controls.Add($exportButton)

# Create a progress bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, 500)
$progressBar.Size = New-Object System.Drawing.Size(740, 30)
$progressBar.Style = "Continuous"
$form.Controls.Add($progressBar)

# Create a label for click instructions
$clickLabel = New-Object System.Windows.Forms.Label
$clickLabel.Location = New-Object System.Drawing.Point(20, 540)
$clickLabel.Size = New-Object System.Drawing.Size(740, 20)
$clickLabel.Text = "Click anywhere on the form to test click latency"
$clickLabel.Visible = $false
$form.Controls.Add($clickLabel)

# Variables to store analysis results
$script:analysisResults = @{
    "ClickLatency" = @()
    "MovementLatency" = @()
    "PollingRate" = @()
    "Precision" = @()
    "Jitter" = @()
    "StartTime" = $null
    "EndTime" = $null
}

# Global variable for click detection
$script:clicked = $false

# Function to log results
function Write-AnalysisLog {
    param(
        [string]$Message,
        [string]$Color = "Black"
    )
    
    try {
        $resultsBox.SelectionStart = $resultsBox.TextLength
        $resultsBox.SelectionLength = 0
        $resultsBox.SelectionColor = $Color
        $resultsBox.AppendText("$Message`r`n")
        $resultsBox.ScrollToCaret()
    }
    catch {
        Write-Host "Error writing to log: $($_.Exception.Message)"
    }
}

# Function to handle mouse clicks
function Handle-MouseClick {
    param(
        [System.Windows.Forms.MouseEventArgs]$e
    )
    $script:clicked = $true
}

# Function to analyze click latency
function Test-ClickLatency {
    Write-AnalysisLog "Testing click latency..." "Blue"
    $progressBar.Value = 0
    $clickLabel.Visible = $true
    
    # Add click handler
    $form.Add_MouseClick({ Handle-MouseClick $args[1] })
    
    for ($i = 0; $i -lt 10; $i++) {
        $script:clicked = $false
        $startTime = [DateTime]::Now
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        
        Write-AnalysisLog "Click $($i + 1) of 10..." "Blue"
        
        # Wait for click with timeout
        $timeout = 10 # seconds
        $startWait = [DateTime]::Now
        
        while (-not $script:clicked) {
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 10
            
            # Check for timeout
            if (([DateTime]::Now - $startWait).TotalSeconds -gt $timeout) {
                Write-AnalysisLog "Click timeout - skipping test" "Red"
                break
            }
        }
        
        if ($script:clicked) {
            $endTime = [DateTime]::Now
            $latency = ($endTime - $startTime).TotalMilliseconds
            $script:analysisResults.ClickLatency += $latency
            Write-AnalysisLog "Click latency: $latency ms" "Green"
        }
        
        $progressBar.Value = ($i + 1) * 10
        Start-Sleep -Milliseconds 500
    }
    
    # Remove click handler
    $form.Remove_MouseClick({ Handle-MouseClick $args[1] })
    
    $form.Cursor = [System.Windows.Forms.Cursors]::Default
    $clickLabel.Visible = $false
    
    if ($script:analysisResults.ClickLatency.Count -gt 0) {
        $avgLatency = ($script:analysisResults.ClickLatency | Measure-Object -Average).Average
        Write-AnalysisLog "Average click latency: $avgLatency ms" "Green"
    }
    else {
        Write-AnalysisLog "No valid click latency measurements recorded" "Red"
    }
}

# Function to analyze movement latency
function Test-MovementLatency {
    Write-AnalysisLog "`nTesting movement latency..." "Blue"
    $progressBar.Value = 0
    
    $lastPosition = $form.PointToClient([System.Windows.Forms.Cursor]::Position)
    $lastTime = [DateTime]::Now
    
    for ($i = 0; $i -lt 100; $i++) {
        $currentPosition = $form.PointToClient([System.Windows.Forms.Cursor]::Position)
        $currentTime = [DateTime]::Now
        
        if ($currentPosition -ne $lastPosition) {
            $latency = ($currentTime - $lastTime).TotalMilliseconds
            $script:analysisResults.MovementLatency += $latency
            $lastPosition = $currentPosition
            $lastTime = $currentTime
        }
        
        $progressBar.Value = $i + 1
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 10
    }
    
    $avgLatency = ($script:analysisResults.MovementLatency | Measure-Object -Average).Average
    Write-AnalysisLog "Average movement latency: $avgLatency ms" "Green"
}

# Function to analyze polling rate
function Test-PollingRate {
    Write-AnalysisLog "`nTesting polling rate..." "Blue"
    $progressBar.Value = 0
    
    $positions = @()
    $times = @()
    $startTime = [DateTime]::Now
    
    for ($i = 0; $i -lt 1000; $i++) {
        $positions += $form.PointToClient([System.Windows.Forms.Cursor]::Position)
        $times += [DateTime]::Now
        $progressBar.Value = [int]($i / 10)
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 1
    }
    
    $endTime = [DateTime]::Now
    $totalTime = ($endTime - $startTime).TotalMilliseconds
    $pollingRate = 1000 / ($totalTime / 1000)
    
    $script:analysisResults.PollingRate = $pollingRate
    Write-AnalysisLog "Estimated polling rate: $pollingRate Hz" "Green"
}

# Function to analyze movement precision
function Test-MovementPrecision {
    Write-AnalysisLog "`nTesting movement precision..." "Blue"
    $progressBar.Value = 0
    
    $positions = @()
    $lastPosition = $form.PointToClient([System.Windows.Forms.Cursor]::Position)
    
    for ($i = 0; $i -lt 100; $i++) {
        $currentPosition = $form.PointToClient([System.Windows.Forms.Cursor]::Position)
        if ($currentPosition -ne $lastPosition) {
            $positions += $currentPosition
            $lastPosition = $currentPosition
        }
        $progressBar.Value = $i + 1
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 10
    }
    
    # Calculate movement precision
    $distances = @()
    for ($i = 1; $i -lt $positions.Count; $i++) {
        $dx = $positions[$i].X - $positions[$i-1].X
        $dy = $positions[$i].Y - $positions[$i-1].Y
        $distance = [Math]::Sqrt($dx * $dx + $dy * $dy)
        $distances += $distance
    }
    
    $avgDistance = ($distances | Measure-Object -Average).Average
    $script:analysisResults.Precision = $avgDistance
    Write-AnalysisLog "Average movement precision: $avgDistance pixels" "Green"
}

# Function to analyze jitter
function Test-Jitter {
    Write-AnalysisLog "`nTesting movement jitter..." "Blue"
    $progressBar.Value = 0
    
    $positions = @()
    $lastPosition = $form.PointToClient([System.Windows.Forms.Cursor]::Position)
    
    for ($i = 0; $i -lt 100; $i++) {
        $currentPosition = $form.PointToClient([System.Windows.Forms.Cursor]::Position)
        if ($currentPosition -ne $lastPosition) {
            $positions += $currentPosition
            $lastPosition = $currentPosition
        }
        $progressBar.Value = $i + 1
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 10
    }
    
    # Calculate jitter
    $jitters = @()
    for ($i = 2; $i -lt $positions.Count; $i++) {
        $dx1 = $positions[$i].X - $positions[$i-1].X
        $dy1 = $positions[$i].Y - $positions[$i-1].Y
        $dx2 = $positions[$i-1].X - $positions[$i-2].X
        $dy2 = $positions[$i-1].Y - $positions[$i-2].Y
        
        $angle1 = [Math]::Atan2($dy1, $dx1)
        $angle2 = [Math]::Atan2($dy2, $dx2)
        $jitter = [Math]::Abs($angle1 - $angle2)
        $jitters += $jitter
    }
    
    $avgJitter = ($jitters | Measure-Object -Average).Average
    $script:analysisResults.Jitter = $avgJitter
    Write-AnalysisLog "Average movement jitter: $avgJitter radians" "Green"
}

# Function to run full analysis
function Start-FullAnalysis {
    try {
        $script:analysisResults.StartTime = [DateTime]::Now
        $resultsBox.Clear()
        
        Write-AnalysisLog "Starting MX Master 3S Latency Analysis..." "Blue"
        Write-AnalysisLog "===========================================" "Blue"
        Write-AnalysisLog "Please follow the on-screen instructions for each test." "Blue"
        Write-AnalysisLog "Move your mouse naturally during the tests." "Blue"
        Write-AnalysisLog "===========================================" "Blue`n"
        
        Test-ClickLatency
        Test-MovementLatency
        Test-PollingRate
        Test-MovementPrecision
        Test-Jitter
        
        $script:analysisResults.EndTime = [DateTime]::Now
        $totalTime = ($script:analysisResults.EndTime - $script:analysisResults.StartTime).TotalSeconds
        
        Write-AnalysisLog "`nAnalysis Complete!" "Green"
        Write-AnalysisLog "Total analysis time: $totalTime seconds" "Green"
        Write-AnalysisLog "`nRecommendations:" "Blue"
        
        # Generate recommendations based on results
        $clickLatency = ($script:analysisResults.ClickLatency | Measure-Object -Average).Average
        $movementLatency = ($script:analysisResults.MovementLatency | Measure-Object -Average).Average
        $pollingRate = $script:analysisResults.PollingRate
        $precision = $script:analysisResults.Precision
        $jitter = $script:analysisResults.Jitter
        
        if ($clickLatency -gt 20) {
            Write-AnalysisLog "- High click latency detected. Consider reducing system load or checking for driver issues." "Red"
        }
        
        if ($movementLatency -gt 10) {
            Write-AnalysisLog "- High movement latency detected. Check USB port or try a different port." "Red"
        }
        
        if ($pollingRate -lt 100) {
            Write-AnalysisLog "- Low polling rate detected. Ensure you're using a USB 3.0 port." "Red"
        }
        
        if ($precision -gt 5) {
            Write-AnalysisLog "- Low movement precision detected. Consider adjusting DPI settings." "Red"
        }
        
        if ($jitter -gt 0.5) {
            Write-AnalysisLog "- High jitter detected. Check for surface issues or try a different mousepad." "Red"
        }
        
        $exportButton.Enabled = $true
    }
    catch {
        Write-AnalysisLog "Error during analysis: $($_.Exception.Message)" "Red"
    }
}

# Function to export results
function Export-AnalysisResults {
    try {
        $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
        $saveFileDialog.Filter = "CSV files (*.csv)|*.csv|All files (*.*)|*.*"
        $saveFileDialog.Title = "Export Analysis Results"
        $saveFileDialog.FileName = "mouse_analysis_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        
        if ($saveFileDialog.ShowDialog() -eq "OK") {
            $results = @"
Timestamp,ClickLatency,MovementLatency,PollingRate,Precision,Jitter
"$($script:analysisResults.StartTime)",$($script:analysisResults.ClickLatency -join ';'),$($script:analysisResults.MovementLatency -join ';'),$($script:analysisResults.PollingRate),$($script:analysisResults.Precision),$($script:analysisResults.Jitter)
"@
            
            $results | Out-File -FilePath $saveFileDialog.FileName -Encoding UTF8
            Write-AnalysisLog "`nResults exported to: $($saveFileDialog.FileName)" "Green"
        }
    }
    catch {
        Write-AnalysisLog "Error exporting results: $($_.Exception.Message)" "Red"
    }
}

# Add event handlers
$startButton.Add_Click({
    try {
        Start-FullAnalysis
    }
    catch {
        Write-AnalysisLog "Error starting analysis: $($_.Exception.Message)" "Red"
    }
})

$exportButton.Add_Click({
    try {
        Export-AnalysisResults
    }
    catch {
        Write-AnalysisLog "Error exporting results: $($_.Exception.Message)" "Red"
    }
})

# Show the form
try {
    $form.ShowDialog()
}
catch {
    Write-Host "Error showing form: $($_.Exception.Message)"
} 