# ObsidianQuickLaunch Packaging Module
# Provides functions to build WiX MSI installers

$script:RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path

function Get-WixPath {
    <#
    .SYNOPSIS
        Locates WiX Toolset binaries on the system
    #>
    [CmdletBinding()]
    param()

    # Common WiX 3.x installation paths
    $wixPaths = @(
        "${env:ProgramFiles(x86)}\WiX Toolset v3.11\bin",
        "${env:ProgramFiles(x86)}\WiX Toolset v3.14\bin",
        "${env:ProgramFiles}\WiX Toolset v3.11\bin",
        "${env:ProgramFiles}\WiX Toolset v3.14\bin",
        "$env:WIX\bin"
    )

    foreach ($path in $wixPaths) {
        if ($path -and (Test-Path $path)) {
            $candlePath = Join-Path $path "candle.exe"
            $lightPath = Join-Path $path "light.exe"
            $heatPath = Join-Path $path "heat.exe"

            if ((Test-Path $candlePath) -and (Test-Path $lightPath) -and (Test-Path $heatPath)) {
                Write-Verbose "Found WiX Toolset at: $path"
                return [PSCustomObject]@{
                    wixCandleExePath = $candlePath
                    wixLightExePath  = $lightPath
                    wixHeatExePath   = $heatPath
                    wixPath          = $path
                }
            }
        }
    }

    throw "WiX Toolset v3.x not found. Please install from https://wixtoolset.org/releases/"
}

function New-MsiArgsArray {
    <#
    .SYNOPSIS
        Converts a hashtable to WiX preprocessor arguments (-dKey=Value)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Hashtable]$Argument
    )

    $buildArguments = @()
    foreach ($key in $Argument.Keys) {
        $buildArguments += "-d$key=$($Argument.$key)"
    }

    return $buildArguments
}

function Start-MsiBuild {
    <#
    .SYNOPSIS
        Compiles WiX source files (.wxs) into an MSI installer
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]] $WxsFile,

        [string[]] $Extension = @('WixUIExtension', 'WixUtilExtension'),

        [Parameter(Mandatory)]
        [Hashtable] $Argument,

        [Parameter(Mandatory)]
        [string] $MsiLocationPath,

        [string] $MsiPdbLocationPath
    )

    $outDir = $env:Temp

    $wixPaths = Get-WixPath

    # Build extension arguments
    $extensionArgs = @()
    foreach ($extensionName in $Extension) {
        $extensionArgs += '-ext'
        $extensionArgs += $extensionName
    }

    $buildArguments = New-MsiArgsArray -Argument $Argument

    # Generate object file paths
    $objectPaths = @()
    foreach ($file in $WxsFile) {
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($file)
        $objectPaths += Join-Path $outDir -ChildPath "${fileName}.wixobj"
    }

    # Clean up old object files
    foreach ($file in $objectPaths) {
        Remove-Item -ErrorAction SilentlyContinue $file -Force
    }

    # Resolve WXS file paths
    $resolvedWxsFiles = @()
    foreach ($file in $WxsFile) {
        $resolvedWxsFiles += (Resolve-Path -Path $file).ProviderPath
    }

    Write-Verbose "WXS Files: $resolvedWxsFiles" -Verbose

    # Compile with candle.exe
    Write-Host "Running WiX candle (compile)..." -ForegroundColor Cyan
    $candleArgs = @(
        $resolvedWxsFiles
        "-out"
        "$outDir\\"
    ) + $extensionArgs + $buildArguments + @('-v')

    Write-Host "Candle.exe command: $($wixPaths.wixCandleExePath) $($candleArgs -join ' ')" -ForegroundColor Gray
    $candleOutput = & $wixPaths.wixCandleExePath @candleArgs 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Candle.exe output:" -ForegroundColor Red
        $candleOutput | ForEach-Object { Write-Host $_ -ForegroundColor Red }
        throw "candle.exe failed with exit code $LASTEXITCODE"
    }
    $candleOutput | ForEach-Object { Write-Host $_ -ForegroundColor Gray }

    # Link with light.exe
    Write-Host "Running WiX light (link)..." -ForegroundColor Cyan
    $lightArgs = @(
        '-sice:ICE61'  # Allow same version upgrades
        '-sice:ICE40'  # REINSTALLMODE is defined in Property table
        '-sice:ICE57'  # Shortcut not per-user
        '-out'
        $MsiLocationPath
    )

    if ($MsiPdbLocationPath) {
        $lightArgs += @('-pdbout', $MsiPdbLocationPath)
    }

    $lightArgs += $objectPaths + $extensionArgs

    Write-Host "Light.exe command: $($wixPaths.wixLightExePath) $($lightArgs -join ' ')" -ForegroundColor Gray
    $lightOutput = & $wixPaths.wixLightExePath @lightArgs 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Light.exe output:" -ForegroundColor Red
        $lightOutput | ForEach-Object { Write-Host $_ -ForegroundColor Red }
        throw "light.exe failed with exit code $LASTEXITCODE"
    }

    # Clean up object files
    foreach ($file in $objectPaths) {
        Remove-Item -ErrorAction SilentlyContinue $file -Force
    }

    Write-Host "MSI created successfully: $MsiLocationPath" -ForegroundColor Green
}

function New-MSIPackage {
    <#
    .SYNOPSIS
        Creates an MSI installer package for ObsidianQuickLaunch

    .DESCRIPTION
        Builds a WiX-based MSI installer that includes:
        - PowerShell scripts for vault registration
        - Windows Explorer context menu integration
        - Automatic registry configuration

    .PARAMETER ProductVersion
        Version number in format Major.Minor.Patch (e.g., "1.0.0")

    .PARAMETER ProductSourcePath
        Path to the source files to package (scripts, assets)

    .PARAMETER OutputPath
        Directory where the MSI will be created

    .PARAMETER Force
        Overwrite existing MSI file

    .EXAMPLE
        New-MSIPackage -ProductVersion "1.0.0" -ProductSourcePath ".\src" -OutputPath ".\dist"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^\d+\.\d+\.\d+$')]
        [string] $ProductVersion,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path $_ })]
        [string] $ProductSourcePath,

        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path $_ })]
        [string] $ProductWxsPath = "$script:RepoRoot\tools\packaging\wix\Product.wxs",

        [ValidateNotNullOrEmpty()]
        [string] $OutputPath = "$script:RepoRoot\dist",

        [Switch] $Force
    )

    Write-Host "`nObsidianQuickLaunch MSI Builder" -ForegroundColor Cyan
    Write-Host "===============================" -ForegroundColor Cyan
    Write-Host "Version: $ProductVersion" -ForegroundColor White
    Write-Host ""

    # Ensure output directory exists
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }

    $packageName = "ObsidianQuickLaunch-$ProductVersion"
    $msiLocationPath = Join-Path $OutputPath "$packageName.msi"
    $msiPdbLocationPath = Join-Path $OutputPath "$packageName.wixpdb"

    if (!$Force.IsPresent -and (Test-Path -Path $msiLocationPath)) {
        throw "Package already exists: $msiLocationPath (use -Force to overwrite)"
    }

    # Convert version to Major.Minor.Build.Revision format required by MSI
    $versionParts = $ProductVersion.Split('.')
    $msiVersion = "$($versionParts[0]).$($versionParts[1]).$($versionParts[2]).0"

    Write-Host "Building MSI package..." -ForegroundColor Cyan
    Write-Host "  Source: $ProductSourcePath" -ForegroundColor Gray
    Write-Host "  Output: $msiLocationPath" -ForegroundColor Gray
    Write-Host ""

    # Generate WiX Fragment using heat.exe for file harvesting
    $wixPaths = Get-WixPath
    $wixFragmentPath = Join-Path $env:Temp "Fragment.wxs"
    Remove-Item -ErrorAction SilentlyContinue $wixFragmentPath -Force

    $arguments = @{
        ProductSourcePath = $ProductSourcePath
        ProductVersion    = $msiVersion
    }

    $buildArguments = New-MsiArgsArray -Argument $arguments

    # Path to XSLT transform for Win64 components
    $win64XsltPath = Join-Path (Split-Path $ProductWxsPath) "Win64.xslt"

    Write-Host "Generating file manifest with heat.exe..." -ForegroundColor Cyan
    & $wixPaths.wixHeatExePath dir $ProductSourcePath `
        -dr INSTALLFOLDER `
        -cg ProductFiles `
        -ag `
        -sfrag `
        -srd `
        -scom `
        -sreg `
        -t $win64XsltPath `
        -out $wixFragmentPath `
        -var var.ProductSourcePath `
        $buildArguments `
        -v

    if ($LASTEXITCODE -ne 0) {
        throw "heat.exe failed with exit code $LASTEXITCODE"
    }

    # Build the MSI
    Start-MsiBuild `
        -WxsFile @($ProductWxsPath, $wixFragmentPath) `
        -Argument $arguments `
        -MsiLocationPath $msiLocationPath `
        -MsiPdbLocationPath $msiPdbLocationPath

    # Clean up temp files
    Remove-Item -ErrorAction SilentlyContinue $wixFragmentPath -Force

    if ((Test-Path $msiLocationPath)) {
        Write-Host "`nSUCCESS!" -ForegroundColor Green
        Write-Host "MSI Package: $msiLocationPath" -ForegroundColor White
        if (Test-Path $msiPdbLocationPath) {
            Write-Host "Debug Symbols: $msiPdbLocationPath" -ForegroundColor Gray
        }
        Write-Host ""

        return [PSCustomObject]@{
            MSI     = $msiLocationPath
            PDB     = $msiPdbLocationPath
            Version = $ProductVersion
        }
    }
    else {
        throw "Failed to create MSI package"
    }
}

Export-ModuleMember -Function @(
    'New-MSIPackage'
    'Get-WixPath'
    'New-MsiArgsArray'
    'Start-MsiBuild'
)
