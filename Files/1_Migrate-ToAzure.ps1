<#
.SYNOPSIS
   On-Prem Migrate to Azure SQL using Powershell
	
.DESCRIPTION
   On-Prem Migrate to Azure SQL using Powershell
      
.EXAMPLE
    Migrate-ToAzure.ps1
	
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

# Show Loaded Modules
if ((Get-Module -ListAvailable Azure) -eq $null) 
{ 
    throw "Windows Azure Powershell not found! Please install from https://azure.microsoft.com/en-us/documentation/articles/powershell-install-configure/" 
} 
Import-Module Azure

Get-Module -ListAvailable Azure

# ---------------------------------------------
# Migrate a local SQL DB to Azure
# ---------------------------------------------
# https://azure.microsoft.com/en-us/documentation/articles/sql-database-cloud-migrate/

# automate the saving of this cred - Thanks Sidney Andrews
Login-AzureRmAccount 


# ----------------------------------
# 1) Export BacPac using SQLPackage - OR SSMS Wizard, OR SSDataTools
# ----------------------------------
& .\2_Export_Local_DB_to_Bacpac.ps1

# ------------------------------------
# 2) Upload bacpacs to Azure Storage
# ------------------------------------
# Prep Storage Upload Creds
$ServerName = "myazurelsqldbserver"
$StorageName = "myazurestoragecontainer"
$ContainerName = "mycontainer"
$StorageKey = "myazureblobstoragekey"

# Get Storage Context - Uses https Port 443
$StorageCtx = New-AzureStorageContext -StorageAccountName $StorageName -StorageAccountKey $StorageKey
$AzureContainer = Get-AzureStorageContainer -Name $ContainerName -Context $StorageCtx

# Create PS SQL Cred from an encrypted file - Remove Comment and run one time
#read-host -assecurestring | convertfrom-securestring | out-file "securestring.txt"
$username = "mysqladmin"
$password = cat "securestring.txt" | convertto-securestring
$sqlcred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password

# Get SQL Auth Context - Uses Port 1433 - check your outgoing firewall
$SqlCtx = New-AzureSqlDatabaseServerContext -ServerName $ServerName -Credential $sqlcred

# -----------------------------
# 3) Upload the Bacpac files
# -----------------------------
# Upload the bacpac files
$BlobName1 = "AW2014.bacpac" 
$localFile1 = "c:\bacpacs\AW2014.bacpac"
Set-AzureStorageBlobContent -File $localFile1 -Container $AzureContainer -Blob $BlobName1 -Context $storageCtx -Force

$BlobName2 = "AW2014DW.bacpac" 
$localFile2= "c:\bacpacs\AW2014DW.bacpac"
Set-AzureStorageBlobContent -File $localFile2 -Container $AzureContainer -Blob $BlobName2 -Context $storageCtx -Force

# -----------------------------------
# 4) Create the Azure SQL Databases
# -----------------------------------
# Create SQL Databases from the Bacpacs we just uploaded into your Azure Storage Account Blob Container
$DatabaseName1 = "AdventureWorks2014-PShell"
$importRequest1 = Start-AzureSqlDatabaseImport -SqlConnectionContext $SqlCtx -StorageContainer $AzureContainer -DatabaseName $DatabaseName1 -BlobName $BlobName1 -Edition Basic -DatabaseMaxSize 2

$DatabaseName2 = "AdventureWorksDW2014-PShell"
$importRequest2 = Start-AzureSqlDatabaseImport -SqlConnectionContext $SqlCtx -StorageContainer $AzureContainer -DatabaseName $DatabaseName2 -BlobName $BlobName2 -Edition Basic -DatabaseMaxSize 2

# Get Creation Status
#Get-AzureSqlDatabaseImportExportStatus -RequestId $ImportRequest1.RequestGuid -ServerName $ServerName -Username $sqlcred.UserName 
#Get-AzureSqlDatabaseImportExportStatus -RequestId $ImportRequest2.RequestGuid -ServerName $ServerName -Username $sqlcred.UserName 

# Set Azure Database Server Firewall Access Rule
New-AzureSqlDatabaseServerFirewallRule -ServerName $ServerName -RuleName "HackersParadise" -StartIPAddress 0.0.0.0 -EndIPAddress 255.255.255.255

# ---------------------------------------------------
# Give Azure a few minutes to spin-up your databases
# ---------------------------------------------------

# Show our new Azure Databases
$AZDatabases = Get-AzureSqlDatabase -ServerName $ServerName
$AZDatabases | select name, Edition, MaxSizeGB, ServiceObjectiveName, CreationDate | sort name |out-gridview

