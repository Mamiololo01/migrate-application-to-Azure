#Variables
$psUri='https://github.com/PowerShell/PowerShell/releases/download/v7.2.7/PowerShell-7.2.7-win-x64.msi'
$psFile='PowerShell-7.2.7-win-x64.msi'
$dPath='C:\Users\cloud_user\Downloads\'
$mySQLUri='https://downloads.mysql.com/archives/get/p/25/file/mysql-installer-community-5.7.39.0.msi'
$mySQLFile='mysql-installer-community-5.7.39.0.msi'

# Alternate Links
# $mySQLZIP=https://downloads.mysql.com/archives/get/p/23/file/mysql-5.7.39-winx64.zip

# Install PowerShell (Core)
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri $psUri -UseBasicParsing -OutFile $dPath\$psFile
msiexec.exe /package "$dPath\$psFile" /quiet ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ADD_FILE_CONTEXT_MENU_RUNPOWERSHELL=1 ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1 USE_MU=1 ENABLE_MU=1 ADD_PATH=1
[System.Environment]::SetEnvironmentVariable('C:\Program Files\PowerShell\7',[System.EnvironmentVariableTarget]::Machine)

# Install & Enable OpenSSH
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Set-Service sshd -StartupType Automatic
Set-Service ssh-agent -StartupType Automatic
Start-Service sshd
Start-Service ssh-agent

# Install mySQL
Invoke-WebRequest -Uri $mySQLUri -UseBasicParsing -OutFile $dPath\$mySQLFile

msiexec.exe /package "$dPath\$mySQLFile" /quiet