. $psscriptroot\Private\Assert-DestinationDirectory.ps1
. $psscriptroot\Private\Clear-CachedDscResource.ps1
. $psscriptroot\Private\Compress-DscResourceModule.ps1
. $psscriptroot\Private\Copy-CurrentDscResource.ps1
. $psscriptroot\Public\DscResourceWmiClass.ps1
. $psscriptroot\Private\Find-ModulesToPublish.ps1
. $psscriptroot\Private\Get-DscResourceVersion.ps1
. $psscriptroot\Public\Invoke-DscBuild.ps1
. $psscriptroot\Private\Invoke-DscConfiguration.ps1
. $psscriptroot\Private\Invoke-DscResourceUnitTest.ps1
. $psscriptroot\Private\New-DscChecksumFile.ps1
. $psscriptroot\Private\New-DscZipFile.ps1
. $psscriptroot\Private\Publish-DscConfiguration.ps1
. $psscriptroot\Private\Publish-DscResourceModule.ps1
. $psscriptroot\Private\Publish-DscToolModule.ps1
. $psscriptroot\Private\Test-DscResourceIsValid.ps1
. $psscriptroot\Private\Update-ModuleMetadataVersion.ps1


$DscBuildParameters = $null

function Add-DscBuildParameter {
    <#
        .Synopsis
            Adds a parameter to the module scoped DscBuildParameters object.
        .Description
            Adds a parameter to the module scoped DscBuildParameters object.  This object is available to all functions in a build and is built from the parameters to Invoke-DscBuild.
        .Example
            Add-DscBuildParameter -Name ProgramFilesModuleDirectory -value (join-path $env:ProgramFiles 'WindowsPowerShell\Modules')
    #>
    [cmdletbinding(SupportsShouldProcess=$true)]
    param (
        #Name of the property to add
        [string]
        $Name,
        #Value of the property to add
        [object]
        $Value
    )

    if ($psboundparameters.containskey('WhatIf')) {
        $psboundparameters.Remove('WhatIf') | out-null
    }

    Write-Verbose ''
    Write-Verbose "Adding DscBuildParameter: $Name"
    Write-Verbose "`tWith Value: $Value"
    $script:DscBuildParameters |
            add-member -membertype Noteproperty -force @psboundparameters
    Write-Verbose ''
}

function Test-BuildResource {
    <#
        .Synopsis
            Checks to see if a build started with Invoke-DscBuild will be processing new or existing resources.
        .Description
            Checks to see if a build started with Invoke-DscBuild will be processing new or existing resources.  This is used by functions in the module to determine whether a particular block needs to execute.
        .Example
            if (Test-BuildResource) { do something...}
    #>
    [cmdletbinding()]
    param ()
    $IsBuild = ( $script:DscBuildParameters.Resource -or
                (-not ($script:DscBuildParameters.Tools -or $script:DscBuildParameters.Configuration) ) )
    Write-Verbose ''
    Write-Verbose "Is a Resource Build - $IsBuild"
    Write-Verbose ''
    return $IsBuild
}

function Test-BuildConfiguration {
     <#
        .Synopsis
            Checks to see if a build started with Invoke-DscBuild will be processing new or existing configurations.
        .Description
            Checks to see if a build started with Invoke-DscBuild will be processing new or existing configurations.  This is used by functions in the module to determine whether a particular block needs to execute.
        .Example
            if (Test-BuildConfiguration) { do something...}
    #>
    [cmdletbinding()]
    param ()
    $IsBuild = ( $script:DscBuildParameters.Configuration -or
                (-not ($script:DscBuildParameters.Tools -or $script:DscBuildParameters.Resource) ) )
    Write-Verbose ''
    Write-Verbose "Is a Configuration Build - $IsBuild"
    Write-Verbose ''
    return $IsBuild
}

function Test-BuildTools {
     <#
        .Synopsis
            Checks to see if a build started with Invoke-DscBuild will be processing new or existing tools.
        .Description
            Checks to see if a build started with Invoke-DscBuild will be processing new or existing tools.  This is used by functions in the module to determine whether a particular block needs to execute.
        .Example
            if (Test-BuildTools) { do something...}
    #>
    [cmdletbinding()]
    param ()
    $IsBuild = ( $script:DscBuildParameters.Tools -or
                (-not ($script:DscBuildParameters.Configuration -or $script:DscBuildParameters.Resource) ) )
    Write-Verbose ''
    Write-Verbose "Is a Tools Build - $IsBuild"
    Write-Verbose ''
    return $IsBuild
}

