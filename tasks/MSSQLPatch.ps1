#----------------------------------------Install SQL Patch-------------------------------------------------
$filepath="C:\SQL-SW\SQLServer2019-KB5011644-x64.exe"
$Parms = " /quiet /IAcceptSQLServerLicenseTerms /Action=Patch /AllInstances"
$Prms = $Parms.Split(" ")
& "$filepath" $Prms | Out-Null