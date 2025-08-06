# Input JSON file
$jsonPath = "smells.json"

# Read and parse JSON
$data = Get-Content $jsonPath -Raw | ConvertFrom-Json

# Group by Smell, excluding "Long statement"
$data | Where-Object { $_.Smell -ne "Long statement" } |
Group-Object Smell | ForEach-Object {
    $smell = $_.Name -replace '[\\/:*?"<>|]', '_'  # sanitize filename
    $file = "$smell.txt"

    # Write to file with separator
    $_.Group | ForEach-Object {
        Add-Content $file "-----"
        Add-Content $file ($_ | ConvertTo-Json -Compress)
    }
}
Write-Host "Done!"
