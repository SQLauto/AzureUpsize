<#
.SYNOPSIS
   On-Prem Migrate to Azure SQL using Powershell
	
.DESCRIPTION
   On-Prem Migrate to Azure SQL using Powershell
      
.EXAMPLE
    2_Export_Local_DB_to_Bacpac.ps1
	
.Inputs
    

.Outputs

	
.NOTES    
	George Walkey
	Richmond, VA USA

.LINK
	https://github.com/gwalkey
	
#>

# Very basic - no powershell parameters here

$TargetFile1 = "C:\Bacpacs\AW2014.bacpac"
$TargetFile2 = "C:\Bacpacs\AW2014DW.bacpac"
$SourceServer="localhost"
$SourceDatabase1="AdventureWorks2014"
$SourceDatabase2="AdventureWorksDW2014"


# Export Local DB to Bacpac
sqlpackage.exe /Action:Export /ssn:$SourceServer /sdn:$SourceDatabase1 /tf:$TargetFile1

sqlpackage.exe /Action:Export /ssn:$SourceServer /sdn:$SourceDatabase2 /tf:$TargetFile2



