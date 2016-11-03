param
(
    [string]
    $ConfigurationDataPath,

    [string]
    $LocalCertificateThumbprint
)

if ([string]::IsNullOrEmpty($LocalCertificateThumbprint))
{
    try
    {
        $LocalCertificateThumbprint = (Get-DscLocalConfigurationManager -ErrorAction Stop).CertificateId
    }
    catch { }
}

if ($LocalCertificateThumbprint)
{
    $LocalCertificatePath = "cert:\LocalMachine\My\$LocalCertificateThumbprint"
}
else
{
    $LocalCertificatePath = ''
}

$ConfigurationData = @{AllNodes=@(); Credentials=@{}; Applications=@{}; Services=@{}; SiteData =@{}}

. $psscriptroot\Private\Get-Hashtable.ps1
. $psscriptroot\Private\Test-LocalCertificate.ps1

. $psscriptroot\Public\New-ConfigurationDataStore.ps1
. $psscriptroot\Public\New-DscNodeMetadata.ps1
. $psscriptroot\Public\Add-DscNodesToServiceMetadata.ps1

. $psscriptroot\Private\Get-AllNodesConfigurationData.ps1
. $psscriptroot\Public\Get-ConfigurationData.ps1
. $psscriptroot\Private\Get-CredentialConfigurationData.ps1
. $psscriptroot\Private\Get-ServiceConfigurationData.ps1
. $psscriptroot\Private\Get-SiteDataConfigurationData.ps1
. $psscriptroot\Public\Get-EncryptedPassword.ps1
. $psscriptroot\Public\Resolve-ConfigurationProperty.ps1
. $psscriptroot\Public\Test-ConfigurationPropertyExists.ps1

. $psscriptroot\Public\Add-EncryptedPassword.ps1
. $psscriptroot\Private\Import-DscCredentialFile.ps1
. $psscriptroot\Private\Export-DscCredentialFile.ps1
. $psscriptroot\Private\ConvertFrom-EncryptedFile.ps1
. $psscriptroot\Private\ConvertTo-CredentialLookup.ps1
. $psscriptroot\Public\New-Credential.ps1
. $psscriptroot\Private\Remove-PlainTextPassword.ps1

function Set-DscConfigurationDataPath {
    param (
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )

    $script:ConfigurationDataPath = (Resolve-path $Path).Path
}
Set-Alias -Name 'Set-ConfigurationDataPath' -Value 'Set-DscConfigurationDataPath'

function Get-DscConfigurationDataPath {

    $script:ConfigurationDataPath
}
Set-Alias -Name 'Get-ConfigurationDataPath' -Value 'Get-DscConfigurationDataPath'

function Resolve-DscConfigurationDataPath {
    [CmdletBinding()]
    param (
        [parameter()]
        [string]
        $Path
    )
    Write-Verbose "Resolving the DSC Configuration Data Path"
    if ( -not ($psboundparameters.containskey('Path')) -or [string]::IsNullOrEmpty($Path)) {
        Write-Verbose "No Path Specified"
        if ([string]::isnullorempty($script:ConfigurationDataPath)) {
            if ($env:ConfigurationDataPath -and (test-path $env:ConfigurationDataPath)) {
                $path = $env:ConfigurationDataPath
                Write-Verbose "Using Configuration Data Path from Environment Variable: $env:ConfigurationDataPath"
            }
            elseif (!$script:ConfigurationDataPath -and (Test-Path (Join-Path $Pwd.Path 'AllNodes'))) {
                $Path = $Pwd.Path
                Write-Verbose "Using ConfigurationData Path from current Directory $Path"
            }
            else {
                Throw "Configuration Data Path not found"
            }
        }
        else {
            $path = $script:ConfigurationDataPath
        }
    }

    if ( -not ([string]::isnullorempty($path)) ) {
        Set-DscConfigurationDataPath -path $path
        Write-Verbose "Dsc Configuration Data Path set to $Path"
    }
}
Set-Alias -Name 'Resolve-ConfigurationDataPath' -Value 'Resolve-DscConfigurationDataPath'

function Set-DscConfigurationCertificate {
    param (
        [parameter(Mandatory)]
        [string]
        $CertificateThumbprint
    )

    $path = "Cert:\LocalMachine\My\$CertificateThumbprint"

    if (Test-Path -Path $path)
    {
        $script:LocalCertificateThumbprint = $CertificateThumbprint
        $script:LocalCertificatePath = $path
    }
    else
    {
        throw "Certificate '$Thumbprint' does not exist in the Local Computer\Personal certificate store."
    }
}

function Get-DscConfigurationCertificate {
    $script:LocalCertificateThumbprint
}

function Get-TokenAreaInFile {
    Param(
        [Io.FileInfo]
        $file,

        [String]
        $TokenContent = 'Nodes'
    )

    $code = (Get-Content -Raw $file)
    $AST = [System.Management.Automation.PSParser]::Tokenize($code,[ref]$null)
    $NodeStart = $AST.where{$_.Content -eq $TokenContent -and $_.Type -eq 'Member'}

    $lastToken = $null
    Foreach ($Token in $AST) {
        if( $Token.Start -gt $NodeStart.Start -and
            (
                $Token.Type -eq 'StatementSeparator' -or
                    $Token.Type -eq 'NewLine' -and $lastToken.Type -ne 'Operator'
            )
        ) {
            $NodeEnd = $Token
            Break
        }
        $lastToken = $Token
    }
    #$AST | ? { $_.Start -gt $NodeStart.Start -and $_.Start -lt $NodeEnd.Start}
    return $NodeStart,$NodeEnd
}