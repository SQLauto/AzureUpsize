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

$SourceFile1 = "C:\Bacpacs\AW2014.bacpac"
$SourceFile2 = "C:\Bacpacs\AW2014DW.bacpac"
$AzureDBServer = "myazuresqldbserver.database.windows.net"
$TargetSQLAdmin="mysqladmin"
$TargetSQLPassword="mysqladminpwd"
$TargetDatabaseName1="AdventureWorks2014-SQLPackage"
$TargetDatabaseName2="AdventureWorksDW2014-SQLPackage"

# Get Compatibility Report -OR use the Upsizing Wizard, or SSMS, or SSDT
#sqlpackage.exe /Action:Export /ssn:localhost /sdn:AdventureWorks2014 /tf:$SourceFile1 /p:TableData=Person.Person
#sqlpackage.exe /Action:Export /ssn:localhost /sdn:AdventureWorksDW2014 /tf:$SourceFile2 /p:TableData=dbo.DimDate

# Create Azure SQL Databases 
sqlpackage.exe /Action:Import /tsn:$AzureDBServer /tdn:$TargetDatabaseName1 /tu:$TargetSQLAdmin /tp:$TargetSQLPassword /sf:$SourceFile1
sqlpackage.exe /Action:Import /tsn:$AzureDBServer /tdn:$TargetDatabaseName2 /tu:$TargetSQLAdmin /tp:$TargetSQLPassword /sf:$SourceFile2

