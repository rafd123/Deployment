$authorizationDataFilePathBase = Join-Path -Path $env:APPDATA -ChildPath 'WindowsLiveAuthorizationData'
$authenticationCallbackUrl = 'https://login.live.com/oauth20_desktop.srf'
$tokenRequestUrl = 'https://login.live.com/oauth20_token.srf'
$tokenRequestBodyMimeType = 'application/x-www-form-urlencoded'

$liveApiUrl = 'https://apis.live.net/v5.0'

$LiveDefaultScope = @(
    'wl.signin',
    'wl.offline_access',
    'wl.basic',
    'Office.onenote_create',                     
    'wl.emails',
    'wl.calendars_update',
    'wl.contacts_create',
    'wl.skydrive_update'
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Web

function Invoke-LiveRestMethod
{
    [CmdletBinding(HelpUri='http://go.microsoft.com/fwlink/?LinkID=217034')]
    param(
        [Microsoft.PowerShell.Commands.WebRequestMethod]
        ${Method},

        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Resource},

        [Parameter(Mandatory=$true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${AccessToken},

        [Microsoft.PowerShell.Commands.WebRequestSession]
        ${WebSession},

        [Alias('SV')]
        [string]
        ${SessionVariable},

        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},

        [switch]
        ${UseDefaultCredentials},

        [ValidateNotNullOrEmpty()]
        [string]
        ${CertificateThumbprint},

        [ValidateNotNull()]
        [System.Security.Cryptography.X509Certificates.X509Certificate]
        ${Certificate},

        [string]
        ${UserAgent},

        [switch]
        ${DisableKeepAlive},

        [int]
        ${TimeoutSec},

        [System.Collections.IDictionary]
        ${Headers},

        [ValidateRange(0, 2147483647)]
        [int]
        ${MaximumRedirection},

        [uri]
        ${Proxy},

        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${ProxyCredential},

        [switch]
        ${ProxyUseDefaultCredentials},

        [Parameter(ValueFromPipeline=$true)]
        [System.Object]
        ${Body},

        [string]
        ${ContentType},

        [ValidateSet('chunked','compress','deflate','gzip','identity')]
        [string]
        ${TransferEncoding},

        [string]
        ${InFile},

        [string]
        ${OutFile},

        [switch]
        ${PassThru})

    begin
    {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }

        $url = Get-LiveApiUrl -Resource $Resource -AccessToken $AccessToken
        $PSBoundParameters.Remove('Resource') | Out-Null
        $PSBoundParameters.Remove('AccessToken') | Out-Null
        $PSBoundParameters['Uri'] = $url

        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Invoke-RestMethod', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }
        $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
        $steppablePipeline.Begin($PSCmdlet)
    }

    process
    {
        $steppablePipeline.Process($_)
    }

    end
    {
        $steppablePipeline.End()
    }
    <#

    .ForwardHelpTargetName Invoke-RestMethod
    .ForwardHelpCategory Cmdlet

    #>
}

function Get-LiveApiUrl
{
    [CmdletBinding()]
    [OutputType([System.Uri])]
    param
    (
        [Parameter(Position = 0)]
        [ValidateScript({ $true })]
        [string]$Resource,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$AccessToken
    )

    $uriBuilder = New-Object System.UriBuilder "$liveApiUrl/$Resource"
    if($uriBuilder.Query)
    {
        $uriBuilder.Query = "$($uriBuilder.Query.TrimStart('?'))&access_token=$AccessToken"
    }
    else
    {
        $uriBuilder.Query = "access_token=$AccessToken"
    }

    return $uriBuilder.Uri
}

function Get-LiveAccessToken
{
<#
.Synopsis
   Authenticates and authorizes an account with Windows Live and returns the access token.
.DESCRIPTION
   This command will ask Windows Live for an access token given the requested scope by prompting the user for authorization.

   Once an access token is obtained it is cached. So long as the same scope is requested, the user will not be prompted again for authorization. When the access token expires, this command will request an access token refresh.

   Visit https://account.live.com/developers/applications/index to get a ClientId and Secret

.PARAMETER ClientId
  Specifies the client ID.

  Visit https://account.live.com/developers/applications/index to get a ClientId and Secret.

.PARAMETER Secret
  Specifies the client secret.

  Visit https://account.live.com/developers/applications/index to get a ClientId and Secret.

.PARAMETER ProfileName
  Specifies a name to be used to identify the cached authorization data for the account.

.PARAMETER Scope
  Specifies the requested scope.

  See http://msdn.microsoft.com/en-us/library/live/hh243646.aspx for more information about scopes.

.PARAMETER Force
  Forces an authorization prompt even if the current access token is still valid.
#>
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$ClientId,
         
        [Parameter(Mandatory = $true)]
        [string]$Secret,

        [Parameter(Mandatory = $true)]
        [string]$ProfileName,

        [ValidateSet('wl.offline_access',   'wl.signin',             'wl.basic',            'wl.emails', 'wl.imap',
                     'wl.contacts_create',  'wl.skydrive_update',    'wl.skydrive',         'wl.contacts_skydrive', 
                     'wl.calendars',        'wl.events_create',      'wl.calendars_update', 'wl.contacts_calendars',
                     'wl.contacts_photos',  'wl.photos',             'wl.birthday',         'wl.contacts_birthday',
                     'wl.postal_addresses', 'wl.work_profile',       'wl.phone_numbers',    'Office.onenote_create'  )]
        [string[]]$Scope = $null,
        
        [switch]$Force
    )

    if ($PSBoundParameters.ContainsKey('Verbose'))
    {
        $VerbosePreference = 'Continue'
    }
    else
    {
        $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
    }

    $authorizationData = $null
    $authorizationDataFilePath = "$($authorizationDataFilePathBase)_$ProfileName"    
    $tokenRequestBody = "client_id=$ClientId&redirect_uri=$authenticationCallbackUrl&client_secret=$Secret"

    if (-not $Force -and (Test-Path $authorizationDataFilePath))
    {
        Write-Verbose "Reading authorization data from $authorizationDataFilePath"
        $authorizationData = Import-Clixml $authorizationDataFilePath
    }

    if ($authorizationData -and $Scope)
    {
        Write-Verbose "Authorized scope = $($authorizationData.Scope)"
        Write-Verbose "Requested scope = $Scope"

        foreach($scopeItem in $Scope)
        {
            if ($authorizationData.Scope -notcontains $scopeItem)
            {
                Write-Verbose 'A greater scope was requested. Invalidating access token.'
                $authorizationData = $null
                break
            }
        }
    }

    if(-not $authorizationData)
    {
        if(-not $Scope)
        {
            $Scope = $LiveDefaultScope
        }

        Write-Verbose 'Prompting for authorization'
        # Prompt the user before showing the dialog; this is useful to ensure that if PowerShell is launched in non-interactive mode
        # that it'll error out instead of hanging
        if(-not $PSCmdlet.ShouldContinue('You must sign in to your Microsoft Account in order to authorize this script. Continue?', 'Authorization Required'))
        {
            Write-Verbose 'Authorization prompt canceled'
            return
        }

        $signedOut = $false
        $signOutUrl = "https://login.live.com/oauth20_logout.srf?client_id=$ClientId&redirect_uri=https://login.live.com/oauth20_desktop.srf"
        $authenticationUrl = "https://login.live.com/oauth20_authorize.srf?client_id=$ClientId&scope=$($Scope -join "%20")&response_type=code&redirect_uri=$authenticationCallbackUrl"
        $authorizationCode = $null
        $errorReason = $null
       
        $dialog = New-Object System.Windows.Forms.Form -Property @{
            Width = 440
            Height = 700
            StartPosition = 'CenterScreen'
        }

        $browser = New-Object System.Windows.Forms.WebBrowser -Property @{
            Dock = 'Fill'
            Url = $signOutUrl
        }

        $browser.Add_DocumentCompleted({
            if(-not $signedOut)
            {
                Set-Variable -Name signedOut -Value $true -Scope 1
                $browser.Url = $authenticationUrl
                return
            }

            if ($browser.Url.AbsoluteUri -match "error=([^&]*)")
            {
                Set-Variable -Name errorReason -Value $Matches[1] -Scope 1
                $dialog.DialogResult = 'OK'
                $dialog.Close()                
                return
            }

            if ($browser.Url.AbsoluteUri -match "code=([^&]*)")
            {
                Set-Variable -Name authorizationCode -Value $Matches[1] -Scope 1
                $dialog.DialogResult = 'OK'
                $dialog.Close()
                return
            }  
        })

        $dialog.Controls.Add($browser)

        if ($dialog.ShowDialog() -eq 'Cancel')
        {
            Write-Verbose 'Authorization prompt canceled'
            return
        }

        if ($errorReason)
        {
            throw "Authorization failed: $errorReason"
        }

        Write-Verbose 'Obtaining access token'

        $utcNow = [datetime]::UtcNow
        $authorizationResponse = Invoke-RestMethod `
            -Method Post `
            -Uri $tokenRequestUrl `
            -ContentType $tokenRequestBodyMimeType `
            -Body "$tokenRequestBody&code=$authorizationCode&grant_type=authorization_code"
            
        $authorizationData = New-Object psobject -Property @{
            AccessToken = $authorizationResponse.access_token
            Scope = $authorizationResponse.scope -split '\s+'
            RefreshToken = $authorizationResponse.refresh_token
            ExpirationTimestamp = $utcNow.AddSeconds($authorizationResponse.expires_in).AddSeconds(-5)
        }
    }
    elseif ([datetime]::UtcNow -ge $authorizationData.ExpirationTimestamp)
    {
        Write-Verbose "Expiration timestamp exceeded. Refreshing access token." 

        $utcNow = [datetime]::UtcNow
        $authorizationResponse = Invoke-RestMethod `
            -Method Post `
            -Uri $tokenRequestUrl `
            -ContentType $tokenRequestBodyMimeType `
            -Body "$tokenRequestBody&refresh_token=$($authorizationData.RefreshToken)&grant_type=refresh_token"

        $authorizationData = New-Object psobject -Property @{
            AccessToken = $authorizationResponse.access_token
            Scope = $authorizationResponse.scope -split '\s+'
            RefreshToken = $authorizationResponse.refresh_token
            ExpirationTimestamp = $utcNow.AddSeconds($authorizationResponse.expires_in).AddSeconds(-10)
        }
    }
    else
    {
        Write-Verbose "Access token is up to date." 
    }

    $authorizationData | Export-Clixml -Path $authorizationDataFilePath

    return $authorizationData.AccessToken
}

Export-ModuleMember -Function Get-LiveAccessToken
Export-ModuleMember -Function Get-LiveApiUrl
Export-ModuleMember -Function Invoke-LiveRestMethod
Export-ModuleMember -Variable LiveDefaultScope