function Import-NetScopeModules {
    param (
        [string]$ModulesPath
    )

    if (!(Test-Path $ModulesPath)) {
        throw "Modules folder not found: $ModulesPath"
    }

    $ModuleFiles = Get-ChildItem -Path $ModulesPath -Filter "*.ps1"

    foreach ($Module in $ModuleFiles) {
        . $Module.FullName
    }
}