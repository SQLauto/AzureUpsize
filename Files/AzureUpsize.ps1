<#
.SYNOPSIS
   Creates an Azure Resource Group, Database Server, Storage Account, Firewall Rules and one Database

.DESCRIPTION
   Creates an Azure Resource Group, Database Server, Storage Account, Firewall Rules and one Database
      
.EXAMPLE
    AzureUpsize.ps1
	

.Inputs
    

.Outputs

	
.NOTES    
	
	George Walkey
	Richmond, VA USA

.LINK
	https://github.com/gwalkey
	
#>

# Get Powershell Here
# https://azure.microsoft.com/en-us/documentation/articles/powershell-install-configure/

if ((Get-Module -ListAvailable Azure) -eq $null) 
{ 
    throw "Windows Azure Powershell not found! Please install from https://azure.microsoft.com/en-us/documentation/articles/powershell-install-configure/" 
} 
Import-Module Azure

Get-Module -ListAvailable Azure


# ------------------------------------------
# Create PS Cred in a file - One Time Thing
read-host -assecurestring | convertfrom-securestring | out-file "securestring.txt"

$username = "saadmin"
$password = cat "securestring.txt" | convertto-securestring
$sqlcred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password


# ---------------------------------------------
# 1) Migrate a local SQL DB to Azure
# ---------------------------------------------
# https://azure.microsoft.com/en-us/documentation/articles/sql-database-cloud-migrate/

# 1) SSMS
# 2) SQLPackage.exe
# 3) SSDT
# 4) DBScripts 21_Dac_Packages.ps1

Login-AzureRmAccount

#Add-AzureAccount

Select-AzureSubscription -SubscriptionId e36321e3-9ebe-4f65-a1ce-5c8570957719

# ----------------------------------
# Export BacPac using DACfx
# ----------------------------------
# "Database source is not a supported version of SQL Server"

# Load SMO Assemblies
Import-Module ".\LoadSQLSmo.psm1"
LoadSQLSMO

Add-Type -Path "${env:ProgramFiles(x86)}\Microsoft SQL Server\130\DAC\bin\Microsoft.SqlServer.Dac.dll" 

# Requirements:
# Microsoft SQL Server 2014 Data-tier Application Framework and others
# https://www.microsoft.com/en-us/download/details.aspx?id=46898
# https://msdn.microsoft.com/en-us/library/microsoft.sqlserver.dac.dacservices_methods(v=sql.120).aspx
# http://social.technet.microsoft.com/wiki/contents/articles/2639.how-to-use-data-tier-application-import-and-export-with-a-windows-azure-sql-database.aspx
# 
# Prep SMO Object
$smoServer = New-Object "Microsoft.SqlServer.Management.SMO.Server" "localhost"

# Export DacPacs from local server
$dbname = "AdventureWorksDW2014"

## Specify the DAC metadata.
$applicationname = "AdventureWorksDW2014"
$version = "1.0.0.0"
$description = "Verison 1.0.0.0"

## Specify the location and name for the extracted DAC package.
$dacpacPath = "C:\Bacpacs\AW2014DW.dacpac"

# Extract the DAC.
# https://msdn.microsoft.com/en-us/library/microsoft.sqlserver.dac.dacservices.exportbacpac(v=sql.120).aspx
$bacpac = new-object Microsoft.SqlServer.Dac.DacServices "server=localhost"
$bacpac.
$bacpac.register("AdventureWorksDW2014","AdventureWorksDW2014","1.0.0.0","AW2014DW")
$bacpac.exportbacpac("C:\bacpacs\AW2014DW.dacpac", "AdventureWorksDW2014")


# ---------------------------------
# Upload bacpacs to Azure Storage

# Prep Storage Upload Creds
$ServerName = "insyncvadb01"
$StorageName = "insyncvastor01"
$ContainerName = "backup102"
$BlobName = "AW2014DW.bacpac"
$StorageKey = "wsZoP1BvwTuJLvogZGCVOdojXY/Zx5KBT4n4qNFCKd2dl7nNCKKqsf/H2ko2ZhHdyl9zCUzdOQBL4d29w1PcAw=="

# Get Storage Context - Uses https Port 443
$StorageCtx = New-AzureStorageContext -StorageAccountName $StorageName -StorageAccountKey $StorageKey
$ContainerName = Get-AzureStorageContainer -Name $ContainerName -Context $StorageCtx

# Get SQL Auth Context - Uses Port 1433
$SqlCtx = New-AzureSqlDatabaseServerContext -ServerName $ServerName -Credential $sqlcred

# Upload the bacpac files
$BlobName1 = "AW2014DW.bacpac" 
$localFile1 = "c:\bacpacs\AW2014DW.bacpac"
Set-AzureStorageBlobContent -File $localFile1 -Container "backup102" -Blob $BlobName1 -Context $storageCtx -Force

$BlobName2 = "ContosoRetailDW.bacpac" 
$localFile2 = "c:\bacpacs\ContosoRetailDW.bacpac"
Set-AzureStorageBlobContent -File $localFile2 -Container "backup102" -Blob $BlobName2 -Context $storageCtx -force

$BlobName3 = "tpcc.bacpac" 
$localFile3 = "c:\bacpacs\tpcc.bacpac"
Set-AzureStorageBlobContent -File $localFile3 -Container "backup102" -Blob $BlobName3 -Context $storageCtx -force

$BlobName4 = "tpch.bacpac" 
$localFile4 = "c:\bacpacs\tpch.bacpac"
Set-AzureStorageBlobContent -File $localFile4 -Container "backup102" -Blob $BlobName4 -Context $storageCtx -force


Login-AzureRmAccount

# Create SQL Databases from the Bacpacs stored in your Azure Storage Account Blob Container
$BlobName1 = "AW2014DW.bacpac" 
$DatabaseName1 = "AdventureWorksDW2014-PShell"
$importRequest1 = Start-AzureSqlDatabaseImport -SqlConnectionContext $SqlCtx -StorageContainer $ContainerName -DatabaseName $DatabaseName1 -BlobName "AW2014DW.bacpac" -Edition Basic -DatabaseMaxSize 2

$DatabaseName2 = "ContosoRetailDW"
$importRequest2 = Start-AzureSqlDatabaseImport -SqlConnectionContext $SqlCtx -StorageContainer $ContainerName -DatabaseName $DatabaseName2 -BlobName $BlobName2 -Edition Basic -DatabaseMaxSize 2

$DatabaseName3 = "tpcc"
$importRequest3 = Start-AzureSqlDatabaseImport -SqlConnectionContext $SqlCtx -StorageContainer $ContainerName -DatabaseName $DatabaseName3 -BlobName $BlobName3 -Edition Basic -DatabaseMaxSize 2

$DatabaseName4 = "tpch"
$importRequest4 = Start-AzureSqlDatabaseImport -SqlConnectionContext $SqlCtx -StorageContainer $ContainerName -DatabaseName $DatabaseName4 -BlobName $BlobName4 -Edition Basic -DatabaseMaxSize 2

# Get Creation Status
Get-AzureSqlDatabaseImportExportStatus -RequestId $ImportRequest1.RequestGuid -ServerName $ServerName -Username $sqlcred.UserName 
Get-AzureSqlDatabaseImportExportStatus -RequestId $ImportRequest2.RequestGuid -ServerName $ServerName -Username $sqlcred.UserName 
Get-AzureSqlDatabaseImportExportStatus -RequestId $ImportRequest3.RequestGuid -ServerName $ServerName -Username $sqlcred.UserName 
Get-AzureSqlDatabaseImportExportStatus -RequestId $ImportRequest4.RequestGuid -ServerName $ServerName -Username $sqlcred.UserName 

# Set Firewall Rule
New-AzureSqlDatabaseServerFirewallRule -ServerName "insyncvadb01" -RuleName AllOpen -StartIPAddress 0.0.0.0 -EndIPAddress 255.255.255.255

# Show the New AZ Databases
$AZDatabases = Get-AzureSqlDatabase -ServerName insyncvadb01 
$AZDatabases | select name, Edition, MaxSizeGB, ServiceObjectiveName, CreationDate | sort name |out-gridview


# --------------------------------
# 2) SQL On-Premises Backup To URL
# --------------------------------
# https://msdn.microsoft.com/en-us/library/dn435916(v=sql.120).aspx
# https://msdn.microsoft.com/en-us/library/dn435916(v=sql.130).aspx

Add-AzureAccount

Select-AzureSubscription -SubscriptionId e36321e3-9ebe-4f65-a1ce-5c8570957719

# Create/Use Storage Account
# Create/Use Blob Container
# Grab Storage Container Keys and Create a local SQL Credential

# Create SQL Credential using TSQL in PS
[string]$strSQL= "DROP CREDENTIAL AzureSQLStore; CREATE CREDENTIAL AzureSQLStore WITH IDENTITY = 'insyncvastor01',SECRET = 'wsZoP1BvwTuJLvogZGCVOdojXY/Zx5KBT4n4qNFCKd2dl7nNCKKqsf/H2ko2ZhHdyl9zCUzdOQBL4d29w1PcAw==' "

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
TO URL = 'https://INSYNCVASTOR01.blob.core.windows.net/backup101/AdventureWorks2014.bak' 
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


# Powershell Version
# https://azure.microsoft.com/en-us/documentation/articles/sql-database-import-powershell/
$credentialName = "AzureSQLStore"
$targetbackupFile = "AdventureWorks2014-PShell.bak"
Backup-SqlDatabase -ServerInstance "localhost" -Database "AdventureWorks2014" -backupFile $targetbackupFile -SqlCredential $credentialName -CompressionOption On `
    -BackupContainer "https://insyncvastor01.blob.core.windows.net/backup102/" -BackupAction Database -CopyOnly -MediaDescription "Daily Backup (Get-Date).ToString('yyyy-MM-dd')" -Checksum


$targetbackupFile = "AdventureWorksDW2014-PShell.bak"
Backup-SqlDatabase -ServerInstance "localhost" -Database "AdventureWorksDW2014" -backupFile $targetbackupFile -SqlCredential $credentialName -CompressionOption On `
    -BackupContainer "https://insyncvastor01.blob.core.windows.net/backup102/" -BackupAction Database -CopyOnly -MediaDescription "Daily Backup (Get-Date).ToString('yyyy-MM-dd')" -Checksum



# -----------------------------------------
# 3) Stretch Database to Azure - 2016 only
# -----------------------------------------
# EXEC sp_configure 'remote data archive' , '1';
# RECONFIGURE;
# 
# SMSS - Right Click on Database - Tasks - Enable DB for Stretch
# Prompts for Azure Login
# Creates a local SQL Linked Server
# Creates a NEW S0-tierd Database in your Azure Subscription

# USE [StretchDatabase];
# ALTER TABLE [StretchTable] ENABLE REMOTE_DATA_ARCHIVE WITH ( MIGRATION_STATE = ON );

# INSERT INTO dbo.StretchTable (FirstName,CreatedDate) VALUES ('TEST',GETDATE());
# GO 100

# SELECT * FROM sys.dm_db_rda_migration_status;

# backup and restore as usual
# Need to Reauthorize/Connect the local engine to access the tables stored in Azure
# EXEC sys.sp_reauthorize_remote_data_archive @azure_username = N'YOUR USERNAME', @azure_password = N'YOUR PASSWORD';


# --------------------
# Database Operations
# --------------------

# Show SQL Servers
Get-AzureSqlDatabaseServer

Get-AzureSqlDatabase -ServerName insyncvadb01

$AZDatabase = Get-AzureSqlDatabase -ServerName insyncvadb01 
$AZDatabase | select name, Edition, MaxSizeGB, ServiceObjectiveName, CreationDate | sort name |out-gridview

$ServerName = "servername"
$DatabaseName = "databasename"

# Context Object
$sqlcred=Get-Credential
$sqlctx=New-AzureSqlDatabaseServerContext -ServerName "insyncvadb01" -Credential $sqlcred

# Show Databases
Get-AzureSqlDatabase -ConnectionContext $ctx
 
# Get all firewall rules in all servers in subscription 
Get-AzureSqlDatabaseServer | Get-AzureSqlDatabaseServerFirewallRule 

# Add a new firewall rule: This rule opens all IPs to the server and is just an example - not recommended!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
New-AzureSqlDatabaseServerFirewallRule -RuleName AllOpen -StartIPAddress 0.0.0.0 -EndIPAddress 255.255.255.255 
 
# Show all firewall rules
Get-AzureSqlDatabaseServerFirewallRule -ServerName insyncvadb01

# Remove FW Rule
Remove-AzureSqlDatabaseServerFirewallRule -ServerName "insyncvadb01" -RuleName "AllOpen"

# Create a NEW database using the ServerName Method
$db = New-AzureSqlDatabase -ServerName "insyncvadb01"  -DatabaseName "Demo" -Edition Basic -MaxSizeGB 2

# Delete DB
Remove-AzureSqlDatabase -ServerName "insyncvadb01" –DatabaseName “Demo”
 

# ---------------------------
# Storage Account Operations
# ---------------------------

# Connect
Add-AzureAccount

Select-AzureSubscription -SubscriptionId e36321e3-9ebe-4f65-a1ce-5c8570957719

# New Storage Account
# New-AzureStorageAccount -StorageAccountName "managedbackupstorage" -Location "EAST US"

# New Blob Container
# $context = New-AzureStorageContext -StorageAccountName managedbackupstorage -StorageAccountKey (Get-AzureStorageKey -StorageAccountName managedbackupstorage).Primary
# New-AzureStorageContainer -Name backupcontainer -Context $context

# View
Get-AzureStorageAccount 

Get-AzureLocation

# List all of the blobs in all of your containers in all of your accounts
Login-AzureRmAccount
Get-AzureRmStorageAccount | Get-AzureStorageContainer | Get-AzureStorageBlob

Get-AzureStorageAccount | Format-Table -Property StorageAccountName, Location, AccountType, StorageAccountStatus

# List all Files (blobs) in All Account Containers
$StorageAccount = "insyncvastor01"
$StorageAccountKey = "kXJO2rn1GtR3sMt8Q96naudbxhSDAFs9yMyN5pm3oP8CDXTKWU8KLZHaM5v5qbX4R5c2sAIoxp/QmKT00R4duQ=="

# Context
$storagectx = New-AzureStorageContext -StorageAccountName $StorageAccount -StorageAccountKey $StorageAccountKey

# Container
$ContainerName = “backup101”

# List all the files in the container
Get-AzureStorageBlob -Container $ContainerName -Context $storagectx | Select Name, Length, LastModified

# --------------------------------------
# List Containers
Get-AzureStorageContainer -Context $storagectx

# List Queues
Get-AzureStorageQueue -Context $storagectx

# List Tables
Get-AzureStorageTable -Context $storagectx

# List Files
Get-AzureStorageFile -Context $storagectx -ShareName

$localTargetDirectory = "c:\bacpacs\"

# Upload DACPAC Files to the Blob Container
$BlobName = "AW2016DWCTP3.bacpac" 
$localFile = "c:\bacpacs\AW2016DWCTP3.bacpac"
Set-AzureStorageBlobContent -File $localFile -Container $ContainerName -Blob $BlobName -Context $storagectx

$BlobName = "AW2016CTP3.bacpac" 
$localFile = "c:\bacpacs\AW2016CTP3.bacpac"
Set-AzureStorageBlobContent -File $localFile -Container $ContainerName -Blob $BlobName -Context $storagectx

$BlobName = "ContosoRetailDW.bacpac" 
$localFile = "c:\bacpacs\ContosoRetailDW.bacpac"
Set-AzureStorageBlobContent -File $localFile -Container $ContainerName -Blob $BlobName -Context $storagectx

$BlobName = "AzureGBW.ps1"
$localFile = "c:\psscripts\AzureGBW.ps1"
Set-AzureStorageBlobContent -File $localFile -Container $ContainerName -Blob $BlobName -Context $storagectx -Force

# Download Files
$BlobName = "ContosoRetailDW.bacpac" 
Get-AzureStorageBlobContent -Blob $BlobName -Container $ContainerName -Destination $localTargetDirectory -Context $storagectx


