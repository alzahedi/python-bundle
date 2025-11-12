param(
    [Parameter(Mandatory=$true)]
    [string]$Config
)

# Get the directory where this script is located
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Path to bundled Python executable
$PythonExe = Join-Path $ScriptDir "windows\python3\python.exe"

# Path to main.py
$MainScript = Join-Path $ScriptDir "main.py"

$ActivateScript = Join-Path $ScriptDir "windows\activate.ps1"

# Check if Python executable exists
if (-not (Test-Path $PythonExe)) {
    Write-Error "Bundled Python not found at: $PythonExe"
    exit 1
}

# Check if main.py exists
if (-not (Test-Path $MainScript)) {
    Write-Error "main.py not found at: $MainScript"
    exit 1
}

# Check if config file exists
if (-not (Test-Path $Config)) {
    Write-Error "Config file not found at: $Config"
    exit 1
}

if (Test-Path $ActivateScript) {
    # Source the activate.ps1 script to set up the environment
    . $ActivateScript
} else {
    Write-Warning "Activation script not found at: $ActivateScript."
    exit 1
}

Write-Host "Using Python: $PythonExe"
Write-Host "Running: $MainScript"
Write-Host "Config: $Config"
Write-Host ""

# Run main.py with the config file
& $PythonExe $MainScript --config $Config

# Deactivate
Deactivate

# Exit with the same exit code as the Python script
exit $LASTEXITCODE