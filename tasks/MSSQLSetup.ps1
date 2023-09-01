#-------------------------------Enable .Net 3.5 from Server Manager----------------------------
# DISM /Online /Enable-Feature /FeatureName:NetFx3 /All
# Install-WindowsFeature NET-Framework-Core

#-------------------------------Mount SQL server iso image-----------------------------------------------
Set-ExecutionPolicy Unrestricted
set-executionpolicy remotesigned

$drive = Mount-DiskImage -ImagePath "C:\SQL-SW\en_sql_server_2012_developer_edition_x86_x64_dvd_813280.iso" | Get-DiskImage | Get-Volume
$SQLsrcPath = $drive.DriveLetter
$configFilePath = "C:\SQL-SW\ConfigurationFile.ini"
$errorOutputFile = "C:\SQL-SW\Temp\ErrorOutput.txt"
$standardOutputFile = "C:\SQL-SW\Temp\StandardOutput.txt"

Write-Host "Starting the install of SQL Server"
Start-Process ${SQLsrcPath}:\setup.exe "/ConfigurationFile=$configFilePath" -Wait -RedirectStandardOutput $standardOutputFile -RedirectStandardError $errorOutputFile
#Start-Process $drive.DriveLetter:\setup.exe "/ConfigurationFile=C:\SQL-SW\ConfigurationFile.ini" -Wait -RedirectStandardOutput $standardOutputFile -RedirectStandardError $errorOutputFile
Write-Host "Installation is Finished"

#-----------------------------------------Install SQL SMS(Update needed)-------------------------------------
# vaidya commetned on 01-sep-2023 $sqlsms="C:\SQL-SW\SSMS-Setup-ENU.exe"
# vaidya commetned on 01-sep-2023 $destpath= "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18"

# vaidya commetned on 01-sep-2023 write-host "Beginning SSMS install..." -nonewline
# already commented. & $sqlsms SSMSInstallRoot="$destpath" /quiet /norestart /log C:\SQL-SW\Temp\log.txt /wait
# vaidya commetned on 01-sep-2023 write-host "It will take 10-12 mins to finish the installation depending on the CPU, RAM..."
