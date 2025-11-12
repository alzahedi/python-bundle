<#
Creates a portable Python bundle inside:
  .\windows

Default Python version: 3.11.9
Needs to be run from Powershell core 7+
#>

$CurrentDir = (Get-Location).Path
$BundleRoot = Join-Path $CurrentDir "windows"
$PythonVersion = "3.11.9"
$TempDir = Join-Path $BundleRoot "_tmp"
$pythonDir = "$BundleRoot\python3"

mkdir $pythonDir -Force | Out-Null

Write-Host "Creating portable Python bundle in: $BundleRoot"
Write-Host "Python version: $PythonVersion"

# Step 1: Create folder
if (-Not (Test-Path $BundleRoot)) {
    New-Item -ItemType Directory -Path $BundleRoot | Out-Null
}

# Step 2: Download Python NuGet package
$nugetUrl = "https://www.nuget.org/api/v2/package/python/$PythonVersion"
curl.exe -L $nugetUrl -o python3.zip

# Step 3: Extract NuGet package
Write-Host "Extracting Python NuGet package..."
Expand-Archive .\python3.zip -DestinationPath extracted_nuget

# Step 4: Move Python files
move .\extracted_nuget\tools\* $pythonDir

# Step 5: Cleanup
Write-Host "Cleaning temporary files..."
rm -R extracted_nuget
rm .\python3.zip

# Step 6: Ensure Scripts folder exists
$scriptsDir = Join-Path $pythonDir "Scripts"
if (-Not (Test-Path $scriptsDir)) {
    New-Item -ItemType Directory -Path $scriptsDir | Out-Null
}

# Step 7: Install pip
Write-Host "Installing pip..."
& "$pythonDir\python.exe" -m ensurepip

# Step 8: Create pip wrapper folder structure
$wrapperRoot = Join-Path $BundleRoot "pip_wrapper"
$wrapperScripts = Join-Path $wrapperRoot "scripts"
$wrapperBin     = Join-Path $wrapperRoot "bin"

New-Item -ItemType Directory -Path $wrapperScripts -Force | Out-Null
New-Item -ItemType Directory -Path $wrapperBin -Force | Out-Null

# Step 9: Write pip wrapper (pip.py)
@"
#!/usr/bin/python
import sys
if __name__ == "__main__":
    from pip._vendor.distlib.scripts import ScriptMaker
    ScriptMaker.executable = r"python.exe"
    from pip._internal.cli.main import main
    sys.exit(main())
"@ | Out-File -Encoding UTF8 -FilePath "$wrapperScripts\pip.py"

# Step 10: Create pip.exe launcher (PowerShell-safe)
Write-Host "Generating pip.exe..."

$pyCode = @"
from pip._vendor.distlib.scripts import ScriptMaker
maker = ScriptMaker('windows/pip_wrapper/scripts', 'windows/pip_wrapper/bin')
maker.executable = r'python.exe'
maker.make('pip.py')
"@

& "$pythonDir\python.exe" -c $pyCode

# Step 11: Activation scripts
Write-Host "Writing activation scripts..."

# activate.cmd
@"
@echo off
set PATH=%~dp0pip_wrapper\bin\;%~dp0python3\Scripts\;%~dp0python3\;%PATH%
"@ | Out-File -Encoding ASCII -FilePath "$BundleRoot\activate.cmd"

# activate.ps1 with deactivate support
@'
$ScriptDir = (Split-Path -Parent $MyInvocation.MyCommand.Definition)

# Save original environment if not already saved
if (-not $Global:_PythonBundleActive) {
    $Global:_OriginalPath = $Env:PATH
    $Global:_PythonBundleActive = $true
    $Global:_PythonBundlePaths = @(
        "$ScriptDir\pip_wrapper\bin",
        "$ScriptDir\python3\Scripts",
        "$ScriptDir\python3"
    )
}

# Activate
$Env:PATH = "$ScriptDir\pip_wrapper\bin;$ScriptDir\python3\Scripts;$ScriptDir\python3;$Env:PATH"

# Create deactivate function
function Global:Deactivate {
    if ($Global:_PythonBundleActive) {
        # Restore original PATH
        $Env:PATH = $Global:_OriginalPath
        
        # Clean up
        Remove-Variable -Name _OriginalPath -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name _PythonBundleActive -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name _PythonBundlePaths -Scope Global -ErrorAction SilentlyContinue
        Remove-Item -Path Function:\Deactivate-PythonBundle -ErrorAction SilentlyContinue
        
        Write-Host "Python bundle deactivated"
    } else {
        Write-Host "Python bundle is not active"
    }
}

Write-Host "Python bundle activated. Use 'Deactivate' to restore environment."
'@ | Out-File -Encoding UTF8 -FilePath "$BundleRoot\activate.ps1"

Write-Host "`nPortable Python bundle created successfully!"
Write-Host "To activate:"
Write-Host "  CMD:        call $BundleRoot\activate.cmd"
Write-Host "  PowerShell: . $BundleRoot\activate.ps1"
