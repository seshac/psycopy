param (
    [string]$PackageName,
    [string]$NewVersion
)

function updatePackage {
    param (
        [string]$File,
        [string]$Package,
        [string]$Version
    )

    # get the folder containing package.json to delete lock file
    $Folder = Split-Path -Parent $File

    # read package.json
    $PackageJson = Get-Content $File -Raw | ConvertFrom-Json

    # check if the package exists in dependencies or devDependencies and update it if exists
    $Updated = $false
    if ($PackageJson.dependencies.$Package) {
        $PackageJson.dependencies.$Package = $Version
        $Updated = $true
    }
    if ($PackageJson.devDependencies.$Package) {
        $PackageJson.devDependencies.$Package = $Version
        $Updated = $true
    }

    if ($Updated) {
        Write-Host "Updating $Package in $File to version $Version"

        # Write updated content back to package.json
        $PackageJson | ConvertTo-Json -Depth 10 | Set-Content $File

        # Navigate to the folder, remove package-lock.json and node_modules, and run npm install
        Set-Location $Folder

        if (Test-Path "package-lock.json") {
            Remove-Item "package-lock.json"
            Write-Host "Removed package-lock.json"
        }

        if (Test-Path "node_modules") {
            Remove-Item -Recurse -Force "node_modules"
            Write-Host "Removed node_modules"
        }

        Write-Host "Running npm install in $Folder"
        npm install

        # Delete node_modules after installation
        if (Test-Path "node_modules") {
            Remove-Item -Recurse -Force "node_modules"
            Write-Host "Deleted node_modules after npm install"
        }

        # Return to original folder
        Set-Location -Path $PSScriptRoot
    } else {
        Write-Host "$Package not found in $File"
    }
}

# Find all package.json files and update the specified package
Get-ChildItem -Recurse -Filter 'package.json' | ForEach-Object {
    updatePackage -File $_.FullName -Package $PackageName -Version $NewVersion
}

Write-Host "$PackageName $NewVersion version update complete!"

# usage  .\update-package.ps1 -PackageName "webpack" -NewVersion "5.94.0"
