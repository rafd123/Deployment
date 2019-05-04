param (
    [Parameter(Mandatory=$true)]
    [PSCredential]$Credential
)

$userName = $Credential.userName
$password = $Credential.GetNetworkCredential().Password

@{
    Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($userName):$($password)"))
}
