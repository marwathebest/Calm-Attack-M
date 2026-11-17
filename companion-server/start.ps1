# Starts the Bloom companion server on Windows.
#
# The key is read from companion-server\.env (ignored by git, so it never
# goes to GitHub). If there's no saved key yet, this asks for it once
# (typing is hidden) and offers to save it to .env for next time.

Set-Location -LiteralPath $PSScriptRoot

if (-not (Test-Path -LiteralPath "node_modules")) {
    Write-Host "Installing packages..."
    npm install
}

$envFile = Join-Path $PSScriptRoot ".env"
$hasSavedKey = (Test-Path -LiteralPath $envFile) -and
    (Select-String -LiteralPath $envFile -Pattern '^\s*OPENAI_API_KEY\s*=\s*\S' -Quiet)

if (-not $hasSavedKey -and -not $env:OPENAI_API_KEY) {
    $secure = Read-Host "Paste your OpenAI API key, then press Enter" -AsSecureString
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        $key = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }
    if (-not $key) {
        Write-Host "No key entered. Stopping."
        exit 1
    }
    $env:OPENAI_API_KEY = $key

    $answer = Read-Host "Save the key in companion-server\.env so you don't have to enter it again? (y/n)"
    if ($answer -match '^[yY]') {
        # Keep any other settings already in .env, replace only the key.
        $lines = @()
        if (Test-Path -LiteralPath $envFile) {
            $lines = Get-Content -LiteralPath $envFile | Where-Object { $_ -notmatch '^\s*OPENAI_API_KEY\s*=' }
        }
        $lines += "OPENAI_API_KEY=$key"
        Set-Content -LiteralPath $envFile -Value $lines -Encoding ascii
        Write-Host "Saved. Next time the server starts without asking."
    }
}

npm start
