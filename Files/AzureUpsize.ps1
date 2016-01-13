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
