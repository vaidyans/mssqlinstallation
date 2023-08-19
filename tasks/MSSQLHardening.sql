------------------|  UCMS Case : 32976 MSSQL Hardening  |------------------
------------------|  Owner : Sreerag Kunnapath  	|------------------
------------------|  Email : sreerag.kunnapath@dxc.com	|------------------


/* Note: MSSQL Hardening script will implement the below, which would impact the existing usage of these login accounts.  
	1. Disable and rename 'sa' login account,Ref: CIS 2.13 & 2.14
	2. Drop BUILTIN groups, Ref : CIS 3.9
	3. Drop Windows local groups that are SQL Logins (eg:computer$), Ref: CIS 3.10 
	4. Remove Public in MSDB from SQL Agent Proxies, Ref: CIS 3.11 
-- vaidya modified registry entry since it was creatinga wrong entry that too only for default instance. modified to update correct registry entry for default as well as named instance.
-- vaidya disabled - since it not necessary to be always enabled dbmail feature in all servers, and also certain domain does not allow email from db server. Can be enabled only when it is required in rare case.
-- Vaidya disabled ole automation need not be enabled to avoid unnecessary access.  
-- vaidya enabled Remote admin connection since it is required for emergency situation /DAC connection from other server is required if the instance is down/up but not accessible..
-- vaidya disabled - Enable Scan For Startup Procs'  since should not perform startup process in most of the customer 
-- vaidya disabled it since sql instance should not be able to access the OS drives for security reason.  This can be enables only when there is neccessaity
-- vaidya modified registry entry since the script was written only for default instance, and that too it was creating a wrong entry in registry. Modified to update the correct registry entry for default as well as named instance.
-- vaidya commented orphan account check since the scirpt is dropping the account instead of fixing the sid
-- vaidya corrected the caption according the requirement : 1 is for windows authentication, 2 is for mixed mode. The caption should be disbale 'only windows authentication mode'
-- vaidya disabled 'disabling sa script', and retained  'rename sa to sa_disable script'
-- vaidya corrected finding account with sa name the syntax to :   '%sa%'
-- vaidya changed to 45 from 15 error logs
-- Setting CLR Assembly Permission Sets to SAFE_ACCESS will prevent assemblies from accessing external system resources such as files, the network, environment variables, or the registry.so vaidya commented this test
---------------------------------------------------------------------------------------
-- Please run this script in sections, some require consideration and or editing first
---------------------------------------------------------------------------------------  */
USE [master]
GO

SET NOCOUNT ON
GO
EXECUTE sp_configure 'show advanced options', 1;
RECONFIGURE;

/* -- CIS 2.1 Check (Surface Area Reduction) - Disable Ad Hoc Distributed Queries Server Configuration Option
EXECUTE sp_configure 'Ad Hoc Distributed Queries', 0;
RECONFIGURE;  */

-- CIS 2.2 Check (Surface Area Reduction) - Disable CLR Enabled Server Configuration Option
EXECUTE sp_configure 'clr enabled', 0;
RECONFIGURE;

-- CIS 2.3 Check (Surface Area Reduction) - Disable Cross DB Ownership Chaining Server Configuration Option
EXECUTE sp_configure 'cross db ownership chaining', 0;
RECONFIGURE;

/* -- CIS 2.4 Check (Surface Area Reduction) - Enable Database Mail XPs Server Configuration Option
-- vaidya disabled - since it not necessary to be always enabled in all servers
EXECUTE sp_configure 'Database Mail XPs', 1;
RECONFIGURE;  */

-- Vaidya disabled need not be enabled unless it is required.
-- CIS 2.5 Check (Surface Area Reduction) - Enable Ole Automation Procedures Server Configuration Option
EXECUTE sp_configure 'Ole Automation Procedures', 1;
RECONFIGURE;

-- CIS 2.6 Check (Surface Area Reduction) - Enable Remote Access Server Configuration Option
EXECUTE sp_configure 'remote access', 1;
RECONFIGURE;

--vaidya enabled it since DAC connection from other server is required if the instance is down
-- CIS 2.7 Check (Surface Area Reduction) - Disable Remote Admin Connections Server Configuration Option
EXECUTE sp_configure 'remote admin connections', 1;
RECONFIGURE;

-- CIS 2.8 Check (Surface Area Reduction) - Enable Scan For Startup Procs Server Configuration Option
-- vaidya disabled it
EXECUTE sp_configure 'scan for startup procs', 0;
RECONFIGURE;

-- CIS 2.15 Check (Surface Area Reduction) - Enable xp_cmdshell Server Configuration Option
-- vaidya disabled it
EXECUTE sp_configure 'xp_cmdshell', 0;
RECONFIGURE;

-- CIS 5.2 Check (Auditing and Logging) - Set Default Trace Enabled
EXECUTE sp_configure 'default trace enabled', 1;
RECONFIGURE;
GO

EXECUTE sp_configure 'show advanced options', 0;
RECONFIGURE;

GO

-- CIS 2.9 Check (Surface Area Reduction) -  Disable Trustworthy Database Property
EXEC sp_MSforeachdb 'IF ''?'' NOT IN(''model'', ''tempdb'') 
					BEGIN USE [?] ALTER DATABASE [?] SET TRUSTWORTHY OFF; END' 
PRINT 'TRUSTWORTHY - OFF'
GO

--vaidya modified registry entry since it was creating a wrong entry that too only for default instance. modified to update correct registry entry for default as well as named instance.
-- CIS 2.12 Check (Surface Area Reduction) - Enable Hide Instance Option 
IF (SERVERPROPERTY('IsClustered') = 1 or SERVERPROPERTY ('IsHadrEnabled') =1 )
Begin
PRINT 'Cannot hide this sql instance since sql is clustered or HADR is enabled'
End

else

Begin
DECLARE @getValue INT
Declare @mypath nvarchar(120)
Declare @myfullpath nvarchar(600)
--select @mypath = 'MSSQL' + convert(varchar(2),SERVERPROPERTY('ProductMajorVersion')) + '.'+ convert(nvarchar, isnull(SERVERPROPERTY('InstanceName'),'MSSQLSERVER'))
select @mypath = 'MSSQL' + convert(varchar(2),SERVERPROPERTY('ProductVersion')) + '.'+ convert(nvarchar, isnull(SERVERPROPERTY('InstanceName'),'MSSQLSERVER'))
select @mypath= rtrim(@mypath)
select @mypath

set @myfullpath = 'SOFTWARE\Microsoft\Microsoft SQL Server\'+ @mypath + '\MSSQLServer\SuperSocketNetLib'
select @myfullpath

--EXEC master..xp_instance_regwrite
EXEC master..xp_regwrite
      @rootkey = N'HKEY_LOCAL_MACHINE',
      @key=@myfullpath,
      @value_name = N'HideInstance',
	  @type = N'REG_DWORD',
      @value = 1;
PRINT 'sql instance hide is enabled/updated'
end
GO


/* -- CIS 2.13 Check (Surface Area Reduction) - Disable SA Login Account
-- vaidya disabled it
USE [master]
GO
IF EXISTS (SELECT name FROM sys.sql_logins WHERE sid = 0x01 and name = 'sa')
BEGIN 
		DECLARE @tsql nvarchar(max)
		SET @tsql = 'ALTER LOGIN ' + SUSER_NAME(0x01) + ' DISABLE'
		EXEC (@tsql)
		PRINT 'Login [' + SUSER_NAME(0x01) + '] - Disabled'
END
GO
*/

-- CIS 2.14 Check (Surface Area Reduction) - Rename SA Login Account
IF EXISTS (SELECT name FROM sys.sql_logins WHERE sid = 0x01 and name = 'sa')
BEGIN
	ALTER LOGIN sa WITH NAME = [sa_Disabled]
	PRINT 'LOGIN [sa] - RENAMED'
END
GO

-- CIS 2.16 Check (Surface Area Reduction) - Disable AUTO_CLOSE on contained databases
EXECUTE sp_MSforeachdb ' IF (''?'' NOT IN (''master'', ''tempdb'', ''msdb'', ''model''))
					EXECUTE (''ALTER DATABASE [?] SET AUTO_CLOSE OFF WITH NO_WAIT'')'
PRINT 'AUTO CLOSE - OFF '
GO

-- CIS 2.17 Check (Surface Area Reduction) - No login exists with the name 'sa'
IF EXISTS( SELECT name FROM sys.sql_logins WHERE name = '%sa%')
	PRINT 'Another account called ''sa'' exists. '
ELSE
	PRINT 'No login exists with the name ''sa'' '
GO

-- CIS 3.1 Check (Authentication and Authorization) - Enable Windows Authentication Mode
-- vaidya caption is wrong : 1 is for windows authentication, 2 is for mixed mode To caption should be disbale 'only windows authentication mode'
USE [master]
GO
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', REG_DWORD, 2
PRINT 'Mixed Mode Authentication - ENABLED'
GO

-- CIS 3.2 Check (Authentication and Authorization) - Revoke Connect Permissions on Guest
EXEC sp_MSforeachdb 'IF ''?'' NOT IN(''master'', ''tempdb'',''msdb'') 
					BEGIN USE [?] REVOKE CONNECT FROM guest; END' 
PRINT 'CONNECT permission on Guest - REVOKED'
GO
/* vaidya commented this check since it is dropping the account
-- CIS 3.3 Check (Authentication and Authorization) - Drop Orphaned Users
--Check for orphaned users
Create proc sp_Remove_OrphanUsers
as
Begin
 set nocount on
 -- get orphaned users  
 Declare @user varchar(max) 
 Declare c_orphaned_user cursor for 
  select name from sys.database_principals where type in ('G','S','U') 
  and authentication_type <> 2 -- Using this filter as we have "contained databases"
  and [sid] not in ( select [sid] from sys.server_principals where type in ('G','S','U') ) 
  and name not in ('dbo','guest','INFORMATION_SCHEMA','sys','MS_DataCollectorInternalUser')  
 open c_orphaned_user 
 fetch next from c_orphaned_user into @user
	While(@@FETCH_STATUS=0)
	Begin
		-- alter schemas for user 
			Declare @schema_name varchar(max) 
			Declare c_schema cursor for 
			select name from  sys.schemas where USER_NAME(principal_id)=@user
			open c_schema 
			Fetch next from c_schema into @schema_name
			While (@@FETCH_STATUS=0)
			Begin
					Declare @sql_schema varchar(max)
					select @sql_schema='ALTER AUTHORIZATION ON SCHEMA::['+@schema_name+ '] TO [dbo]'
					Print @sql_schema
					Exec(@sql_schema)
			Fetch next from c_schema into @schema_name
			End
			Close c_schema
			Deallocate c_schema   
  
		-- alter roles for user 
		Declare @dp_name varchar(max) 
		Declare c_database_principal cursor for 
		select name from sys.database_principals 
											where type='R' and user_name(owning_principal_id)=@user
		Open c_database_principal
		Fetch next from c_database_principal into @dp_name
		While (@@FETCH_STATUS=0)
		Begin
					Declare @sql_database_principal  varchar(max)
					select @sql_database_principal ='ALTER AUTHORIZATION ON ROLE::['+@dp_name+ '] TO [dbo]'
					Print @sql_database_principal 
					Exec(@sql_database_principal )
		Fetch next from c_database_principal into @dp_name
		End
		Close c_database_principal
		Deallocate c_database_principal
    
		-- drop roles for user 
		Declare @role_name varchar(max) 
		Declare c_role cursor for 
		select dp.name --,USER_NAME(member_principal_id) 
														from sys.database_role_members drm 
				inner join sys.database_principals dp on dp.principal_id= drm.role_principal_id
							where USER_NAME(member_principal_id)=@user 
		Open c_role 
		Fetch next from c_role into @role_name
		While (@@FETCH_STATUS=0)
		Begin
				Declare @sql_role varchar(max)
				select @sql_role='EXEC sp_droprolemember N'''+@role_name+''', N'''+@user+''''
				Print @sql_role
				Exec (@sql_role)
				Fetch next from c_role into @role_name
		End
		Close c_role
		Deallocate c_role   
      
		-- drop user
		Declare @sql_user varchar(max)
		set @sql_user='DROP USER ['+@user +']'
		Print @sql_user
		Exec (@sql_user)
 Fetch next from c_orphaned_user into @user
 End
 Close c_orphaned_user
 Deallocate c_orphaned_user
 Set nocount off
End
go
exec sys.sp_MS_marksystemobject sp_Remove_OrphanUsers
IF EXISTS ( SELECT * FROM  SysObjects 
							WHERE  id = object_id(N'[dbo].[sp_Remove_OrphanUsers]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN
    EXEC sp_msforeachdb 'USE [?]; EXEC dbo.sp_Remove_OrphanUsers' 
END
Else 
	PRINT 'Procedure [sp_Remove_OrphanUsers] does not exist.'
GO
*/


-- CIS 3.9 Check (Authentication and Authorization) - Drop BUILTIN groups
USE [master];
GO
Declare @Login_Name Varchar(500)
Declare @tsql1 Varchar(max)
SELECT @Login_Name = ISNULL(pr.[name],'') FROM sys.server_principals pr JOIN sys.server_permissions pe 
								ON pr.principal_id = pe.grantee_principal_id WHERE UPPER(pr.name) like 'BUILTIN%';
IF ISNULL(LTRIM(RTRIM(@Login_Name)),'') <> ''
Begin
	SET @tsql1 = 'DROP LOGIN [' + @Login_Name +']' 
	EXEC (@tsql1)
	PRINT 'BUILTIN Account ['+ @Login_Name +'] - REMOVED'
End
GO

-- CIS 3.10 Check (Authentication and Authorization) -  Drop Windows local groups that are SQL Logins (eg:computer$)
USE [master];
GO
Declare @Login_Name Varchar(500)
Declare @tsql1 Varchar(max)
SELECT @Login_Name = pr.[name] FROM sys.server_principals pr JOIN sys.server_permissions pe
					ON pr.[principal_id] = pe.[grantee_principal_id] WHERE pr.[type_desc] = 'WINDOWS_GROUP'
					AND pr.[name] like CAST(SERVERPROPERTY('MachineName') AS nvarchar) + '%';
IF ISNULL(LTRIM(RTRIM(@Login_Name)),'') <> ''
Begin
	SET @tsql1 = 'DROP LOGIN [' + @Login_Name +']'
	EXEC (@tsql1)
	PRINT 'Windows Local Account [' + @Login_Name + '] - REMOVED'
End
GO


-- CIS 3.11 Check (Authentication and Authorization) - Remove Public in MSDB from SQL Agent Proxies
USE [msdb]
GO
Declare @Login_Name Varchar(900)
SELECT @Login_Name = sp.name FROM dbo.sysproxylogin spl JOIN sys.database_principals dp ON dp.sid = spl.sid
					JOIN sysproxies sp ON sp.proxy_id = spl.proxy_id WHERE principal_id = USER_ID('public');
IF ISNULL(LTRIM(RTRIM(@Login_Name)),'') <> ''
Begin
	EXEC dbo.sp_revoke_login_from_proxy @name = N'public', @proxy_name = @Login_Name;	
	PRINT 'SQL Agent Proxy Account ['+ @Login_Name +'] on PUBLIC - REVOKED'
End
GO

-- CIS 5.1 Check (Auditing and Logging) - Set Maximum number of error log files
-- vaidya changed to 45 from 15
USE [master]
GO
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'NumErrorLogs', REG_DWORD, 45
PRINT 'Set Maximum number of errorlog files - 45'
GO

-- CIS 5.3 Check (Auditing and Logging) - Enable Login Auditing for failed logins
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'AuditLevel', REG_DWORD, 3
PRINT 'Login Audit for failed logins - ENABLED'
GO

-- CIS 5.4 Check (Auditing and Logging) - Set SQL Server Audit to capture failed and successful logins
IF NOT EXISTS (SELECT * FROM sys.server_audits WHERE name = N'TrackLogins')
BEGIN
	CREATE SERVER AUDIT TrackLogins TO APPLICATION_LOG;

	CREATE SERVER AUDIT SPECIFICATION TrackAllLogins FOR SERVER AUDIT TrackLogins
		ADD (FAILED_LOGIN_GROUP), ADD (SUCCESSFUL_LOGIN_GROUP), ADD (AUDIT_CHANGE_GROUP)   WITH (STATE = ON);
	
	ALTER SERVER AUDIT TrackLogins WITH (STATE = ON);
	
	PRINT 'Audit to capture failed and successful logins - ENABLED'
END

/* 
Setting CLR Assembly Permission Sets to SAFE_ACCESS will prevent assemblies from accessing external system resources such as files, the network, environment variables, or the registry.
so vaidya commented this test
-- CIS 6.2 Check (Application Development) - Set CLR Assembly Permission to SAFE_ACCESS
USE [master];
GO
Declare @Assmbly_Name Varchar(1000)
Declare @tsql1 Varchar(max)
SELECT @Assmbly_Name = ISNULL(name,'') FROM sys.assemblies WHERE is_user_defined = 1;
IF ISNULL(LTRIM(RTRIM(@Assmbly_Name)),'') <> ''
Begin
	SET @tsql1 = 'ALTER ASSEMBLY [' + @Assmbly_Name + '] WITH PERMISSION_SET = SAFE'
	EXEC (@tsql1)
	PRINT 'Altered permission of Assembly ['+ @Assmbly_Name +']  - SAFE'
End
GO
*/

---------------------------------------------------------Instance Level Configuration

--COMMENTED BECAUSE THIS REQUIRES EDITING FIST

/*
		--Not a Shared Environment
		exec sp_configure 'show advanced options', 1;  
		RECONFIGURE;
		GO
		sp_configure 'max server memory', 0;
		GO
		RECONFIGURE;
		GO
		sp_configure 'show advanced options', 0;  
		GO
		RECONFIGURE;
		GO
*/

/*
		--Shared Environment
		exec sp_configure 'show advanced options', 1;  
		GO
		RECONFIGURE;
		GO
		sp_configure 'max server memory', 0;
		GO
		sp_configure 'min server memory', 0;
		GO
		RECONFIGURE;
		GO
		sp_configure 'show advanced options', 0;  
		GO
		RECONFIGURE;
		GO
*/
/* 
--- Set maxdop before running. If cpu count >= 8 then set to 8 else set equal to cpu count.
	--MAXDOP
	PRINT 'Setting MAXDOP'
	EXEC sp_configure 'show advanced options', 1;  
	GO  
	RECONFIGURE WITH OVERRIDE;  
	GO  
	EXEC sp_configure 'max degree of parallelism', 8;  
	GO
	RECONFIGURE WITH OVERRIDE; 
	GO
	--Cost Threshold for Parallelism
	PRINT 'Setting Cost Threshold for Parallelism'
	EXEC sp_configure 'show advanced options', 1 ;  
	GO  
	RECONFIGURE  
	GO  
	EXEC sp_configure 'cost threshold for parallelism', 50;  
	GO  
	RECONFIGURE  
	GO
	EXEC sp_configure 'show advanced options', 0;  
	GO
	RECONFIGURE;
	GO
*/
	--Optmise for Adhoc Workloads
	PRINT 'Enabling Ad Hoc Distributed Queries'
	EXEC sp_configure 'show advanced options', 1;
	RECONFIGURE;
	GO
	EXEC sp_configure 'optimize for ad hoc workloads', 1;
	RECONFIGURE;
	GO
	EXEC sp_configure 'show advanced options', 0;  
	GO
	RECONFIGURE;
	GO
/* vaidya commented this as it has to be default value
	--Global Fill Factor
	PRINT 'Setting Global Fill Factor to 90%'
	EXEC sp_configure 'show advanced options', 1;  
	GO  
	RECONFIGURE;  
	GO  
	EXEC sp_configure 'fill factor', 90;  
	GO
	RECONFIGURE;
	GO
*/


--------------------------------------------------------- Model Configration

	--Auto update stastics ON - ASYNC
	PRINT 'MODEL: Configuring Update Stats ASYNC'
	ALTER DATABASE model
	SET AUTO_UPDATE_STATISTICS ON
	ALTER DATABASE model
	SET AUTO_UPDATE_STATISTICS_ASYNC ON
	GO
/* vaidya disabled it
	--Disable Forced Parameterization
	PRINT 'MODEL: Disabling Forced Parameterization'
	USE [master]
	GO
	ALTER DATABASE [model] SET PARAMETERIZATION FORCED WITH NO_WAIT
	GO
	--Standard Growth Settings
	PRINT 'MODEL: Setting standard file autogrowth'
	USE [master]
	GO
	ALTER DATABASE [model] MODIFY FILE ( NAME = N'modeldev', FILEGROWTH = 524288KB )
	GO
	ALTER DATABASE [model] MODIFY FILE ( NAME = N'modellog', FILEGROWTH = 262144KB )
	GO
	*/
---------------------------------------------------------SQLAgent Configuration

USE [msdb]
GO
EXEC msdb.dbo.sp_set_sqlagent_properties @jobhistory_max_rows=100000, 
		@jobhistory_max_rows_per_job=500
GO
SET NOCOUNT OFF