[CmdletBinding(DefaultParameterSetName='Command')]
param (
	[Parameter(Mandatory = $true, ParameterSetName = 'LastCommand')]
	[switch]$LastCommand,

	[Parameter(Mandatory = $true, ValueFromRemainingArguments = $true, ParameterSetName = 'Command')]
	[string[]]$Command
)

$powershellExe = Get-Process -Id $pid | Select-Object -ExpandProperty Path
$payloadPrefix = '79683b41-b20a-4cf9-a9f7-3f39b04730f7'
$commandPrefix = if ($Host.Version.Major -gt 5) {
    '-Command'
} else {
	''
}

function isAdmin {
	[System.Security.Principal.WindowsIdentity]::GetCurrent().UserClaims `
	| Where-Object { $_.Value -eq 'S-1-5-32-544'}
}

function runCommand($parentPid, $workingDirectory, $command) {
	$kernel = Add-Type -PassThru '
		using System.Runtime.InteropServices;
		public class Kernel {
			[DllImport("kernel32.dll", SetLastError = true)]
			public static extern bool AttachConsole(uint dwProcessId);

			[DllImport("kernel32.dll", SetLastError = true, ExactSpelling = true)]
			public static extern bool FreeConsole();
		}'

	$kernel::FreeConsole()
	$kernel::AttachConsole($parentPid)

	$encodedCommand = "$command`nexit `$LASTEXITCODE" | encode

	$process = New-Object System.Diagnostics.Process
	$start = $process.StartInfo
	$start.FileName = $powershellExe
	$start.Arguments = "-NoProfile -EncodedCommand $encodedCommand"
	$start.UseShellExecute = $false
	$start.WorkingDirectory = $workingDirectory
	$process.Start()
	$process.WaitForExit()
	return $process.ExitCode
}

function encode {
	process {
		[Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($_))
	}
}

function decode {
	process {
		[System.Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($_))
	}
}

if($Command -like "$payloadPrefix*") {
	$payload = $Command.Substring($payloadPrefix.Length) | decode | ConvertFrom-Json
	exit runCommand `
		$payload.ParentPid `
		$payload.WorkingDirectory `
		$payload.Command
}

if(!(isAdmin)) {
	throw "You must be an administrator."
}

$payload = $payloadPrefix + ([PSCustomObject]@{
	ParentPid = $PID
	WorkingDirectory = Convert-Path $PWD # convert-path in case pwd is a PSDrive
	Command = if ($LastCommand) {
		Get-History -Count 1 | Select-Object -ExpandProperty CommandLine
	} else {
		[string]$Command
	}
} | ConvertTo-Json | encode)

$savetitle = $Host.UI.RawUI.WindowTitle
$process = New-Object System.Diagnostics.Process
$start = $process.StartInfo
$start.FileName = "$powershellExe"
$start.Arguments = "-NoProfile $commandPrefix & '$PSCommandPath' -Command $payload`nexit `$LASTEXITCODE"
$start.Verb = 'runas'
$start.UseShellExecute = $true
$start.WindowStyle = 'hidden'

try {
	$process.Start() | Out-Null
}
catch {
	throw 'Consent rejected.'
}

$process.WaitForExit()
$Host.UI.RawUI.WindowTitle = $savetitle

exit $process.ExitCode
