@{
    GUID              = "8f4b5c3d-2a1e-4d9f-b7c8-9e6f5d4c3b2a"
    Author            = "Scott Kirvan"
    CompanyName       = "Scott Kirvan"
    Copyright         = "Copyright (c) Scott Kirvan."
    ModuleVersion     = "1.0.0"
    PowerShellVersion = "5.1"
    CmdletsToExport   = @()
    FunctionsToExport = @(
        'New-MSIPackage'
        'Get-WixPath'
        'New-MsiArgsArray'
        'Start-MsiBuild'
    )
    RootModule        = "packaging.psm1"
    Description       = "ObsidianQuickLaunch packaging module for building WiX installers"
}
