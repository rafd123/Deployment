Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

#region Public Functions

<#

.SYNOPSIS

Initializes and/or updates a database given a series of migration scripts.

.DESCRIPTION

Initializes and/or updates a database given a series of migration scripts.

If the specified database does not exist, it will create it.

The command will then look in the directory specified by the -MigrationScriptDirectory
(or the current directory if not specified) for files that match the following
naming convention:

<integer>.sql

The integer portion of the SQL file designates the schema version that the file represents.
Consequently, the command will apply the scripts in ascending integer-order.

Once the scripts have been applied, the greates schema version will be stored as a
database property. Unless the -Reset switch is specified, subsequent invocations of the
command will only apply scripts with a schema version greater than the version stored in
the database.

If the -Reset switch is specified, the database will be dropped if it exists before it is
recreated. To suppress the confirmation prompt that appears before the database is dropped, 
pass -Force as a parameter to the command.

In order to specify a SQL script that always runs after all of the versioned scripts have
been applied, pass the -AlwaysRunScriptPath parameter with the path to the script.

.PARAMETER Database

The name of the database.

.PARAMETER ServerInstance

The instance name of the Database Engine.

.PARAMETER VersionTableSchema

Specifies the name of the schema used to store the version history.

The default value is 'migration'

.PARAMETER VersionTableName

Specifies the name of the table used to store the version history.

The default value is 'SchemaHistory'

.PARAMETER Reset

Specifies that if the specified database exists, it should be dropped and recreated.

To suppress the confirmation prompt that appears before the database is dropped, 
pass -Force as a parameter to the command.

.PARAMETER MigrationScriptDirectory

Specifies the path to use to scan for migration scripts.

The default value is the current directory.

.PARAMETER RunScriptAfterMigration

Specifies the path to a SQL script that should always be run after running all of 
the versioned SQL scripts.

.EXAMPLE

Invoke-DBMigration MySuperCoolDB

Initializes a database called MySuperCoolDB. If the database does not exist, it will
be created. Any SQL scripts in the current directory that have the <integer>.sql
pattern are applied if necessary.

.EXAMPLE 

Invoke-DBMigration MySuperCoolDB -Reset -Force

Resets the database called MySuperCoolDB. If the database exists, it will
be dropped before it is recreated; the -Force parameter suppresses
the ensuing prompt. Any SQL scripts in the current directory that have the
<integer>.sql are then applied.

.EXAMPLE

Invoke-DBMigration MySuperCoolDB -RunScriptAfterMigration .\develop.sql

Initializes a database called MySuperCoolDB. If the database does not exist, it will
be created. Any SQL scripts in the current directory that have the <integer>.sql
pattern are applied if necessary. After running any required versioned SQL scripts,
runs a SQL script called develop.sql

#>
function Invoke-DBMigration
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Database,

        [Parameter()]
        [string]$ServerInstance = 'localhost',

        [Parameter()]
        [string]$VersionTableSchema = 'migration',

        [Parameter()]
        [string]$VersionTableName = 'SchemaVersion',

        [Parameter()]
        [switch]$Reset,

        [Parameter()]
        [string]$MigrationScriptDirectory = '.',

        [Parameter()]
        [string[]]$RunScriptAfterMigration,

        [Parameter()]
        [switch]
        $Force
    )
    
    #region Constants and such

    # The separator used to indicate a SQL script file while
    # running the migration
    $scriptFileSeparatorFormat = @"

-------------------------------------------------------
Running script: {0}
-------------------------------------------------------
"@

    $commonSqlCmdParams = @{
        ServerInstance = $ServerInstance
    }

    #endregion Constants and such    
    
    #region Supporting functions

    function ResetDatabaseIfNecessary
    {
        if($Reset)
        {
            if(-not $Force -and -not $PSCmdlet.ShouldContinue("Are you sure you want to drop the $Database database.","Confirm?"))
            {
                exit
            }

            InvokeSqlCmd @commonSqlCmdParams -Database master @"
IF EXISTS (SELECT name FROM master.sys.databases WHERE name = N'$Database')
BEGIN
    PRINT N'Dropping database: $Database'
    ALTER DATABASE [$Database] SET single_user WITH ROLLBACK IMMEDIATE -- This should sever existing connections
    DROP DATABASE [$Database]
END
"@
        }
    }

    function EnsureDatabaseExists
    {
        InvokeSqlCmd @commonSqlCmdParams -Database master @"
IF NOT EXISTS (SELECT name FROM master.sys.databases WHERE name = N'$Database')
BEGIN
    PRINT N'Creating database: $Database'
    CREATE DATABASE $Database
END
"@
    }

    function PerformMigration
    {
        $currentSchemaVersionProperty = GetCurrentSchemaVersionProperty

        if(-not $currentSchemaVersionProperty.IsValid)
        {
            Write-Host 'No schema version has previously been applied.'
        }
        else
        {
            Write-Host "Database is at schema version $($currentSchemaVersionProperty.Value)."
        }

        $scriptFilesToApply = `
            GetScriptFilesToApply -CurrentSchemaVersionValue $currentSchemaVersionProperty.Value

        if(-not $scriptFilesToApply)
        {
            Write-Host 'Database is already up to date. No scripts to apply.'
            return
        }

        Write-Host 'The following scripts will be applied:'
        $scriptFilesToApply | ForEach-Object {
            Write-Host "`t$($_.Name)"
        }

        Start-Transaction
        GenerateQueryObjects -ScriptFilesToApply $scriptFilesToApply |
            InvokeSqlCmd @commonSqlCmdParams -Database $Database -UseTransaction | Out-Null
        Complete-Transaction
        
        Write-Host ''
        Write-Host 'Done!'        

        $currentSchemaVersionProperty = GetCurrentSchemaVersionProperty
        Write-Host "Database is now at schema version $($currentSchemaVersionProperty.Value)."
    }

    function GetCurrentSchemaVersionProperty
    {
        $currentSchemaVersionProperty = InvokeSqlCmd @commonSqlCmdParams -Database $Database @"
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = '$VersionTableSchema' AND  TABLE_NAME = '$VersionTableName')
BEGIN
    SELECT TOP 1 Version as Value FROM $VersionTableSchema.$VersionTableName
    ORDER BY Version DESC
END
"@

        $isValid = $true
        if(-not $currentSchemaVersionProperty -or
           -not ($currentSchemaVersionProperty.Value -as [int] -is [int]))
        {
            $isValid = $false
            $currentSchemaVersionProperty = @{
                Value = [int]::MinValue
            }
        }

        return $currentSchemaVersionProperty |
            Add-Member -MemberType NoteProperty -Name IsValid -Value $isValid -PassThru
    }

    function GetScriptFilesToApply
    {
        [CmdletBinding()]
        param
        (
            [Parameter(Mandatory=$true)]
            [int]
            $CurrentSchemaVersionValue
        )

        Write-Host "Looking in $(Resolve-Path $MigrationScriptDirectory) for versioned script files..."

        $versionedScriptFiles = @(dir $MigrationScriptDirectory *.sql |
            Where-Object { $_.BaseName -as [int] -is [int] } |
            ForEach-Object {
                Write-Host "`tFound versioned script file: $($_.Name)"
                return $_
            })

        if(-not $versionedScriptFiles)
        {
            Write-Warning 'No versioned script files were found!'
        }     
                    
        $scriptFilesToApply = @($versionedScriptFiles | Where-Object { [int]($_.BaseName) -gt $CurrentSchemaVersionValue } |
            ForEach-Object {
                Add-Member `
                    -InputObject $_ `
                    -MemberType NoteProperty `
                    -Name SchemaVersion `
                    -Value ([int]$_.BaseName) `
                    -PassThru
            } |
            Sort-Object SchemaVersion)

        if($RunScriptAfterMigration)
        {
            $scriptFilesToApplyAfterMigration = @($RunScriptAfterMigration |
                dir |
                Add-Member -MemberType NoteProperty -Name SchemaVersion -Value $null -PassThru)

            Write-Host 'The following script files will be applied after the migration:'
            $scriptFilesToApplyAfterMigration | ForEach-Object {
                Write-Host "`t$($_.Name)"
            }
                
            $scriptFilesToApply += $scriptFilesToApplyAfterMigration
        }

        return $scriptFilesToApply
    }

    function GenerateQueryObjects
    {
        [CmdletBinding()]
        param
        (
            [Parameter(Mandatory=$true)]
            [System.IO.FileInfo[]]
            $ScriptFilesToApply
        )
        
       
        # Emit the SQL that creates the version history schema and table if necessary
@"
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = '$VersionTableSchema')
BEGIN
    EXEC('
    CREATE SCHEMA [$VersionTableSchema]
    ')
END

GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = '$VersionTableSchema' AND  TABLE_NAME = '$VersionTableName')
BEGIN
    CREATE TABLE $VersionTableSchema.$VersionTableName
    (
        Version int IDENTITY (1, 1) NOT NULL,
        AppliedOnDateTime datetime2(7) NOT NULL
        CONSTRAINT [PK_SchemaVersion] PRIMARY KEY CLUSTERED 
    )  ON [PRIMARY]
END
"@        

        # Emit the SQL in each of the script files to apply
        $ScriptFilesToApply | ForEach-Object {
            $scriptFileToApply = $_
            Write-Host ($scriptFileSeparatorFormat -f $scriptFileToApply.Name)
            
            $scriptFileToApply
            
            # Insert the schema version into the version history table
            if($scriptFileToApply.SchemaVersion)
            {
@"
SET IDENTITY_INSERT $VersionTableSchema.$VersionTableName ON
INSERT INTO $VersionTableSchema.$VersionTableName (Version,AppliedOnDateTime)
VALUES ($($scriptFileToApply.SchemaVersion),SYSDATETIME())
SET IDENTITY_INSERT $VersionTableSchema.$VersionTableName OFF
"@
                }
            }
    }

    #endregion Supporting functions    
    
    #region Let's do this thing

    ResetDatabaseIfNecessary
    EnsureDatabaseExists
    PerformMigration

    #endregion Let's do this thing
}

#endregion Public Functions

#region Private Functions

# Prefer using ADO.NET over SQLPS' Invoke-SqlCmd
# in order to
# - Minimize client dependencies and
# - Implement transaction support
# - Report accurate line number information in the face of GO statements
function InvokeSqlCmd
{
    [CmdletBinding(SupportsTransactions=$true)]
    param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Database,

        [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true)]
        [PSObject[]]$Query,

        [Parameter()]
        [string]$ServerInstance = 'localhost',
        
        [Parameter()]
        [System.Management.Automation.PSCredential]$Credential       
    )
    
    begin
    {
        function UnwrapQueryObjects
        {
            [CmdletBinding()]
            param
            (
                [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
                [PSObject]$InputObject            
            )
            
            process
            {                
                if($InputObject -is [System.IO.FileInfo])
                {
                    return (Get-Content $InputObject.FullName) -join "`n" |
                        Add-Member -MemberType NoteProperty -Name File -Value $InputObject.FullName -PassThru
                }
                
                if($InputObject -is [scriptblock])
                {
                    return & $InputObject | UnwrapQueryObjects |
                        Add-Member -MemberType NoteProperty -Name File -Value $null -PassThru
                }
                
                return $InputObject |
                    Add-Member -MemberType NoteProperty -Name File -Value $null -PassThru
            }
        }
    
        function SplitGoStatements
        {
            [CmdletBinding()]
            param
            (
                [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)]
                [PSObject]$Script
            )
            
            begin
            {
                # Ensure that statements that precede a GO statement
                # are in their own batch since the GO statement isn't valid
                # Transact-SQL: http://technet.microsoft.com/en-us/library/ms188037.aspx
                $goStatementLineRegex = "^\s*?"     + # A GO line starts with possibly 0 or more spaces
                                        "GO"        + # followed by the word "GO"
                                        "\s*?"      + # followed by possibly 0 or more spaces
                                        "(--.*?)?$"   # possibly ending with a comment            
            }
            
            process
            {                                
                $normalizedLineEndings = $Script -replace "`r`n","`n"
                $commandBatches = $normalizedLineEndings -split $goStatementLineRegex,0,"multiline"
                
                # Go through each of the command batches and enrich each with line number offset
                # information so that if an error occurs, we can accurately report the line number
                # as it appeared in the overall script that it appeared in (i.e. when ADO.NET reports
                # line numbers, it's going to be relative to the begining of the batch)
                $lineOffset = 0
                foreach($commandBatch in $commandBatches)
                {
                    # Ok...so since ADO.NET reports line numbers based on the first non-empty line
                    # we need to account for how many empty lines lead up to the first non-empty line
                    # to come up with the correct offset that ADO.NET will be basing its line numbers
                    # off of
                    $match = [regex]::Match($commandBatch,'[^\s]')
                    if($match.Success)
                    {
                        $emptyLineCount = ($commandBatch.Substring(0, $match.Index) | Measure-Object -Line).Lines
                        $lineOffset += $emptyLineCount
                        
                        # Trim off all the whitespace that ADO.NET is going to ignore anyway
                        $commandBatch = $commandBatch.Substring($match.Index)                
                    }
               
                    if(-not [string]::IsNullOrWhiteSpace($commandBatch))
                    {
                        # Add the line offset to the string so that the caller can calculate the line number
                        # in the event of an error
                        $commandBatch | 
                            Add-Member -MemberType NoteProperty -Name LineOffset -Value $lineOffset -PassThru |
                            Add-Member -MemberType NoteProperty -Name File -Value $Script.File -PassThru
                    }
                    
                    $lineOffset += ($commandBatch | Measure-Object -Line).Lines
                }
            }
        }
        
        $connectionStringParts = @(
            "server=$ServerInstance"
            "database=$Database"
            "Integrated Security=true"
        )

        if($Credential)
        {
            $marshal = [System.Runtime.InteropServices.Marshal]
            $ptr = $marshal::SecureStringToBSTR($Credential.Password)
            try
            {
                $password = $marshal::PtrToStringBSTR($ptr)        
                $connectionStringParts += "User Id=$($Credential.UserName)"
                $connectionStringParts += "Password=$($Credential.password)"
            }
            finally
            {
                $marshal::ZeroFreeBSTR($ptr)
            }
        }
        else
        {
            $connectionStringParts += "Integrated Security=true"
        }    
        
        $connectionString = $connectionStringParts -join ';'
    }
    
    process
    {
        $commandBatches = $Query | UnwrapQueryObjects | SplitGoStatements
        
        $psTransaction = $null
        if($PSCmdlet.TransactionAvailable())
        {
            $psTransaction = $PSCmdlet.CurrentPSTransaction
        }
        
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionString
        $connection.add_InfoMessage({ Write-Host $args[1].Message })
        $connection.Open()
        
        try
        {
            $commandBatches | ForEach-Object {
                $commandText = $_
                
                Write-Verbose @"
Invoking SQL Query at line offset $($commandText.LineOffset):
$commandText
"@              
                $command = New-Object System.Data.SqlClient.SqlCommand $commandText, $connection

                try
                {                    
                    $reader = $command.ExecuteReader()
                    try
                    {
                        while($reader.HasRows)
                        {
                            while($reader.Read())
                            {
                                $properties = @{}
                                for($i = 0; $i -lt $reader.FieldCount; ++$i)
                                {                
                                    $properties.Add($reader.GetName($i), $reader.GetValue($i))
                                }

                                New-Object –TypeName PSObject -Property $properties
                            } 

                            $reader.NextResult() | Out-Null
                        }
                    }
                    finally
                    {
                        $reader.Dispose()
                    }
                }
                finally
                {
                    $command.Dispose()
                }            
            }
        }
        catch
        {
            # For usability, unwrap and throw the SQL exception
            if($_.Exception -and $_.Exception.InnerException -is [System.Data.SqlClient.SqlException])
            {
                $sqlException = $_.Exception.InnerException
                $file = $commandText.File
                $lineNumber = $sqlException.LineNumber + $commandText.LineOffset

                Write-Error `
                    -Message "$file($lineNumber) : $($sqlException.Message)" `
                    -Exception $sqlException `
                    -TargetObject $commandText
            }
            else
            {
                throw
            }
        }
        finally
        {
            $connection.Dispose()
            
            if($psTransaction)
            {
                $psTransaction.Dispose()
            }            
        }
    }
}

#endregion Private Functions

#region Exports

Export-ModuleMember -Function @(
    'Invoke-DBMigration'
)

#endregion Exports