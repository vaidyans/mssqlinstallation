#----------------------------------------Install SQL Patch-------------------------------------------------
Install-Module -Name powershell-yaml -Force -Scope CurrentUser

# Import the powershell-yaml module
Import-Module powershell-yaml

# Specify the path to your YAML file
$yamlFile = "https://github.com/vaidyans/mssqlinstallation/blob/master/vars/basevars.yml"

# Parse the YAML file
$yamlData = ConvertFrom-Yaml -Path $yamlFile

# Access the values from the YAML data

#----- $filepath="C:\SQL-SW\SQLServer2012-KB4025925-x64.exe"
$filepath = $yamlData.mssql_patch_file_name

$Parms = " /quiet /IAcceptSQLServerLicenseTerms /Action=Patch /AllInstances"
$Prms = $Parms.Split(" ")
& "$filepath" $Prms | Out-Null
