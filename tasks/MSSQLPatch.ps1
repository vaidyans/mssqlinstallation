#----------------------------------------Install SQL Patch-------------------------------------------------
$filepath="C:\SQL-SW\SQLServer2012-KB4025925-x64.exe"
$Parms = " /quiet /IAcceptSQLServerLicenseTerms /Action=Patch /AllInstances"
$Prms = $Parms.Split(" ")
& "$filepath" $Prms | Out-Null
