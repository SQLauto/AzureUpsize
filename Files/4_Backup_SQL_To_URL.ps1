<#
.SYNOPSIS
   On-Prem Migrate to Azure SQL using Powershell
	
.DESCRIPTION
   On-Prem Migrate to Azure SQL using Powershell
      
.EXAMPLE
    3_Create_Azure_DB_from_Bacpac.ps1
	
.Inputs
    

.Outputs

	
.NOTES    
	George Walkey
	Richmond, VA USA

.LINK
	https://github.com/gwalkey
	
#>

# --------------------------------
# SQL On-Premises Backup To URL
# --------------------------------
# https://msdn.microsoft.com/en-us/library/dn435916(v=sql.120).aspx
# https://msdn.microsoft.com/en-us/library/dn435916(v=sql.130).aspx

Login-AzureRmAccount 

# Prerequisites
# Create/Use Storage Account
# Create/Use Blob Container
# Grab Storage Container Keys and Create a local SQL Credential

# Create SQL Credential using TSQL from PS
$SQLCreateCommand=
"DROP CREDENTIAL AzureSQLStore; CREATE CREDENTIAL AzureSQLStore WITH IDENTITY = 'myazuresqldbserver',SECRET = 'myazurestorageaccountkey' "


# Connect to SQL using .NET DataAdapter Method - NOT invoke-sqlcmd
$SQLInstance = "localhost"
$DataSet = New-Object System.Data.DataSet
$SQLConnectionString = "Data Source=$SQLInstance;Integrated Security=SSPI;"
$Connection = New-Object System.Data.SqlClient.SqlConnection
$Connection.ConnectionString = $SQLConnectionString
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = $strSQL
$SqlCmd.Connection = $Connection
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd

# Execute SQL
try
{
    $SqlAdapter.Fill($DataSet) | Out-Null

    if ($Dataset.Tables.Count -gt 0)
    {
        $results = $DataSet.Tables[0].Rows[0]
        Write-Output ($results.Column1)
    }
    else
    {
        Write-Output "Command Completed"
    }

}
catch
{
    Write-Output "Error Running SQL Command"
}
finally
{
    $Connection.Close()
}


# Backup the Database to URL using TSQL
[string]$strSQL=`
"BACKUP DATABASE AdventureWorks2014 
TO URL = 'https://myazuresqldbserver.blob.core.windows.net/mycontainer/AdventureWorks2014.bak' 
      WITH CREDENTIAL = 'AzureSQLStore' 
     ,COMPRESSION
     ,FORMAT
     ,INIT
     ,STATS = 5
"

# Connect to SQL using .NET DataAdapter Method - NOT invoke-sqlcmd
$SQLInstance = "localhost"
$DataSet = New-Object System.Data.DataSet
$SQLConnectionString = "Data Source=$SQLInstance;Integrated Security=SSPI;"
$Connection = New-Object System.Data.SqlClient.SqlConnection
$Connection.ConnectionString = $SQLConnectionString
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = $strSQL
$SqlCmd.Connection = $Connection
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd

# Execute SQL
try
{
    $SqlAdapter.Fill($DataSet) | Out-Null

    if ($Dataset.Tables.Count -gt 0)
    {
        $results = $DataSet.Tables[0].Rows[0]
        Write-Output ($results.Column1)
    }
    else
    {
        Write-Output "Command Completed"
    }

}
catch
{
    Write-Output "Error Running SQL Command"
}
finally
{
    $Connection.Close()
}


# Or Backup the Databases using this Azure Powershell Cmdlet
# https://azure.microsoft.com/en-us/documentation/articles/sql-database-import-powershell/

$StorageName = "myazurestor01"
$ContainerName = "mycontainer"

$credentialName = "AzureSQLStore"
$targetbackupFile = "AdventureWorks2014-PShell.bak"
Backup-SqlDatabase `
    -ServerInstance "localhost" `
    -Database "AdventureWorks2014" `
    -backupFile $targetbackupFile `
    -SqlCredential $credentialName `
    -CompressionOption On `
    -BackupContainer "https://$StorageName.blob.core.windows.net/$ContainerName/" `
    -BackupAction Database `
    -CopyOnly `
    -MediaDescription "Daily Backup (Get-Date).ToString('yyyy-MM-dd')" `
    -Checksum


$targetbackupFile = "AdventureWorksDW2014-PShell.bak"
Backup-SqlDatabase `
    -ServerInstance "localhost" `
    -Database "AdventureWorkDW2014" `
    -backupFile $targetbackupFile `
    -SqlCredential $credentialName `
    -CompressionOption On `
    -BackupContainer "https://$StorageName.blob.core.windows.net/$ContainerName/" `
    -BackupAction Database `
    -CopyOnly `
    -MediaDescription "Daily Backup (Get-Date).ToString('yyyy-MM-dd')" `
    -Checksum
