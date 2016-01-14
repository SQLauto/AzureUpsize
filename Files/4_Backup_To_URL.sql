-- Create SQL Cred
DROP CREDENTIAL AzureSQLStore;
CREATE CREDENTIAL AzureSQLStore WITH IDENTITY = 'myazurestorage',SECRET = 'myazurestoragekey';

--Backup
BACKUP DATABASE AdventureWorks2014
TO URL = 'https://myazuresqldbserver.blob.core.windows.net/mycontainer/AdventureWorks2014.bak' 
    WITH CREDENTIAL = 'AzureSQLStore' 
     ,COMPRESSION
	 ,FORMAT
	 ,INIT
     ,STATS = 5;
GO

BACKUP DATABASE AdventureWorksDW2014 
TO URL = 'https://myazuresqldbserver.blob.core.windows.net/mycontainer/AdventureWorksDW2014.bak' 
    WITH CREDENTIAL = 'AzureSQLStore' 
     ,COMPRESSION
	 ,FORMAT
	 ,INIT
     ,STATS = 5;
GO


