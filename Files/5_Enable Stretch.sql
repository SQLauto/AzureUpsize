
-- Enable Stretch on local Server
use master
go 
sp_configure 'remote data archive',1
reconfigure with override 
go

-- Enable Stretch On local Database
ALTER DATABASE [AdventureworksDW2016CTP3]
 SET REMOTE_DATA_ARCHIVE = ON (SERVER = N'myazuresqlserver.database.windows.net');
GO

-- Check is Enabled?
use master
go
select is_remote_data_archive_enabled,name from sys.databases where is_remote_data_archive_enabled=1
go

--- Enable Stretch on Table
USE [Adventureworks2016CTP3]
GO
-- Until this command is fixed, it doesnt work, use the wizard
ALTER TABLE [Adventureworks2016CTP3].[Sales].[OrderTracking] ENABLE REMOTE_DATA_ARCHIVE WITH ( MIGRATION_STATE = ON )
GO



--- Watch Migration
select * from sys.remote_data_archive_databases
select * from sys.sysservers
select object_name(object_id),* from sys.remote_data_archive_tables
select * from sys.dm_db_rda_migration_status
select object_name(table_id) TableName,* from sys.dm_db_rda_migration_status

EXEC sp_spaceused 'Sales.OrderTracking', 'true', 'LOCAL_ONLY';
EXEC sp_spaceused 'Sales.OrderTracking', 'true', 'REMOTE_ONLY';
EXEC sp_spaceused 'Sales.OrderTracking', 'true', 'ALL';
GO

-- Dont FORGET: By default the SSMS Wizard creates an S3 250GB Server to stretch this to ($150 per month)
