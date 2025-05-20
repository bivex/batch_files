  # Define the note content as a script parameter
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true,
               Position=0,
               HelpMessage="Enter the note content to be stored.")]
    [string]$NoteContent
)

# Define the request URL for creating a note on 1ty.me
$Url = "https://1ty.me/?mode=ajax&cmd=create_note"

# Prepare the data for the POST request
# We are sending the note content, and empty values for email, reference, newsletter, and expiration days.
$FormData = @{
    note = $NoteContent
    email = ""
    reference = ""
    newsletter = ""
    expires_on = ""
}

# Send the POST request to the 1ty.me API
Write-Host "Creating note..."
$Response = Invoke-RestMethod -Uri $Url -Method Post -ContentType "application/x-www-form-urlencoded; charset=UTF-8" -Body $FormData

# Check the response and provide feedback to the user
if ($Response.url) {
    # Construct the full URL from the response
    $NoteUrl = "https://1ty.me/" + $Response.url
    Write-Host "Successfully created note. Link: $NoteUrl"
} else {
    # Handle potential errors returned by the API
    Write-Host "Failed to create note."
    if ($Response.error) {
        Write-Host "Error: $($Response.error)"
    }
    exit 1 # Exit with a non-zero code to indicate failure
} 
