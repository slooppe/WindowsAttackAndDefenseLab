﻿configuration DomainConfig 
{ 
  param 
  ( 
  [Parameter(Mandatory)]
  [String]$DomainName,

  [Parameter(Mandatory)]
  [System.Management.Automation.PSCredential]$Admincreds,
  
  [Parameter(Mandatory)]
  [System.Management.Automation.PSCredential]$StudentCreds,
    
  [Parameter(Mandatory)]
  [System.Management.Automation.PSCredential]$BackupUserCreds,

  [Parameter(Mandatory)]
  [System.Management.Automation.PSCredential]$HelpDeskUserCreds,

  [Parameter(Mandatory)]
  [System.Management.Automation.PSCredential]$AccountingUserCreds,

  [Parameter(Mandatory)]
  [System.Management.Automation.PSCredential]$ServerAdminCreds,

  [Parameter(Mandatory)]
  [System.Management.Automation.PSCredential]$HelperAccountCreds,

  [Parameter(Mandatory)]
  [string]$classUrl,

  [Parameter(Mandatory)]
  [string]$linuxNicIpAddress,

  [Int]$RetryCount=20,
  [Int]$RetryIntervalSec=30
  ) 

  Import-DscResource -ModuleName xActiveDirectory, xDisk, xNetworking, cDisk,xDnsServer, PSDesiredStateConfiguration, xTimeZone
  [System.Management.Automation.PSCredential]$DomainAdminCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
  [System.Management.Automation.PSCredential]$DomainStudentCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($StudentCreds.UserName)", $StudentCreds.Password)
  [System.Management.Automation.PSCredential]$DomainBackupUserCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($BackupUserCreds.UserName)", $BackupUserCreds.Password)
  [System.Management.Automation.PSCredential]$DomainHelpDeskUserCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($HelpDeskUserCreds.UserName)", $HelpDeskUserCreds.Password)
  [System.Management.Automation.PSCredential]$DomainAccountingUserCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($AccountingUserCreds.UserName)", $AccountingUserCreds.Password)
  [System.Management.Automation.PSCredential]$DomainServerAdminCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($ServerAdminCreds.UserName)", $ServerAdminCreds.Password)
  [System.Management.Automation.PSCredential]$DomainHelperAccountCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($HelperAccountCreds.UserName)", $HelperAccountCreds.Password)

  $AdminUserName = $Admincreds.UserName
  $BackupUserUsername = $BackupUserCreds.UserName
  $HelpDeskUserUsername = $HelpDeskUserCreds.UserName
  $AccountingUserUsername = $AccountingUserCreds.UserName
  $ServerAdminUsername = $ServerAdminCreds.UserName
  $HelperAccountUsername = $HelperAccountCreds.UserName
  
  $Interface=Get-NetAdapter | Where-Object Name -Like "Ethernet*" | Select-Object -First 1
  $InterfaceAlias=$($Interface.Name)

  Node localhost
  {
    Script DownloadClassFiles
    {
        SetScript =  { 
            $file = $using:classUrl + 'DC.zip'
            Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[DownloadClassFiles] Downloading $file"
            Invoke-WebRequest -Uri $file -OutFile C:\Windows\Temp\Class.zip
        }
        GetScript =  { @{} }
        TestScript = { 
            Test-Path C:\Windows\Temp\Class.zip
         }
    }
    Archive UnzipClassFiles
    {
        Ensure = "Present"
        Destination = "C:\Class"
        Path = "C:\Windows\Temp\Class.zip"
        Force = $true
        DependsOn = "[Script]DownloadClassFiles"
    }
    
    Script DownloadWAADFiles
    {
        SetScript =  { 
            $file = $using:classUrl + 'WAAD.zip'
            Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[DownloadWAADFiles] Downloading $file"
            Invoke-WebRequest -Uri $file -OutFile C:\Windows\Temp\WAAD.zip
        }
        GetScript =  { @{} }
        TestScript = { 
            Test-Path C:\Windows\Temp\WAAD.zip
         }
    }
    Archive UnzipWAADFiles
    {
        Ensure = "Present"
        Destination = "C:\WAAD"
        Path = "C:\Windows\Temp\WAAD.zip"
        Force = $true
        DependsOn = "[Script]DownloadWAADFiles"
    }    
    Script ImportGPOs
    {
        SetScript =  {
          Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[ImportGPOs] Running.." 
          Try {
            New-GPO -Name "WAAD Default"
            New-GPO -Name "Student Computers"
            New-GPO -Name "Audit Policy"
            New-GPO -Name "Command Line Logging"
            New-GPO -Name "PowerShell Logging"
            New-GPO -Name "Windows Event Forwarding"
            New-GPO -Name "Restrict Network Logons"
            New-GPO -Name "Disable Firewall"
            New-GPO -Name "Shared Folder"
            Import-GPO -Path "C:\WAAD\GPOs" -BackupId '{FF68FA65-A8D6-448D-87E5-6140373380CF}' -TargetName "Disable Firewall"
            Import-GPO -Path "C:\WAAD\GPOs" -BackupId '{BD3497A3-0BBC-4F59-8B26-F54C6CA6FD07}' -TargetName "Shared Folder"
            Import-GPO -Path "C:\WAAD\GPOs" -BackupId '{AC5D004D-2C93-46AB-A1F8-2D6A64CF491F}' -TargetName "WAAD Default"
            Import-GPO -Path "C:\WAAD\GPOs" -BackupId '{D8BF6BAB-A17B-4673-8F2C-9EAFDDC5A236}'-TargetName "Student Computers"
            Import-GPO -Path "C:\WAAD\GPOs" -BackupId '{4C6EB35D-10D8-468D-B02A-6CB9660F7D74}' -TargetName "Audit Policy"
            Import-GPO -Path "C:\WAAD\GPOs" -BackupId '{D85D37F5-37DA-4FED-87E9-F91580F8D980}' -TargetName "Command Line Logging"
            Import-GPO -Path "C:\WAAD\GPOs" -BackupId '{18073D21-902D-4FA0-A696-21AEDAD66244}' -TargetName "Windows Event Forwarding"
            Import-GPO -Path "C:\WAAD\GPOs" -BackupId '{B4F0C06E-B982-4679-A46F-A625759B669B}' -TargetName "Restrict Network Logons"
            Import-GPO -Path "C:\WAAD\GPOs" -BackupId '{772B1393-475F-47BC-938F-6BDBDABAB3F0}' -TargetName "PowerShell Logging"
            New-GPLink -Name "Disable Firewall" -Target "OU=Domain Controllers,DC=ad,DC=waad,DC=training"
            New-GPLink -Name "Disable Firewall" -Target "OU=Production,DC=AD,DC=WAAD,DC=TRAINING"
            New-GPLink -Name "Shared Folder" -Target "OU=Production,DC=AD,DC=WAAD,DC=TRAINING"
            New-GPLink -Name "WAAD Default" -Target "DC=AD,DC=WAAD,DC=TRAINING"
            New-GPLink -Name "Audit Policy" -Target "DC=AD,DC=WAAD,DC=TRAINING"
            New-GPLink -Name "Command Line Logging" -Target "DC=AD,DC=WAAD,DC=TRAINING"
            New-GPLink -Name "PowerShell Logging" -Target "DC=AD,DC=WAAD,DC=TRAINING"
            New-GPLink -Name "Windows Event Forwarding"-Target "DC=AD,DC=WAAD,DC=TRAINING"
            New-GPLink -Name "Restrict Network Logons"-Target "OU=Production,DC=AD,DC=WAAD,DC=TRAINING"
            New-GPLink -Name "Student Computers" -Target "OU=Computers,OU=Class,DC=AD,DC=WAAD,DC=TRAINING"
          }
          Catch {
            Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[ImportGPOs] Failed.."
            $exception = $error[0].Exception
            Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[ImportGPOs] Error: $exception"
          }
        }
        GetScript =  { @{} }
        TestScript = { try {Get-GPO -Name "WAAD Default2" -ErrorAction Stop | Out-null; return $true} catch { $false } }
        DependsOn = "[Archive]UnzipClassFiles","[xADOrganizationalUnit]ProductionServersOU","[xADOrganizationalUnit]ClassComputersOU"
    }    
    Script SetupWEC
    {
        SetScript =  {
          Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[ImportGPOs] Running.." 
          Try {
            wecutil qc /q
            wecutil cs C:\Class\Subscriptions\PowerShell.xml
            wecutil cs C:\Class\Subscriptions\Processes.xml
            wecutil cs C:\Class\Subscriptions\WindowsDefender.xml
            wecutil cs C:\Class\Subscriptions\SecurityLogCleared.xml
          }
          Catch {
            Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[SetupWEC] Failed.."
            $exception = $error[0].Exception
            Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[SetupWEC] Error: $exception"
          }
        }
        GetScript =  { @{} }
        TestScript = { $false }
        DependsOn = "[Script]ImportGPOs"
    }
    WindowsFeature DNS 
    { 
      Ensure = "Present" 
      Name = "DNS"		
    }
    xDnsRecord Pwnbox
    {
        Name = "pwnbox"
        Target = $LinuxNicIpAddress
        Zone = $DomainName
        Type = "ARecord"
        Ensure = "Present"
        DependsOn="[WindowsFeature]DNS"
    }

    Script DnsDiagnosticsScript
    {
      SetScript =  { 
        Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[DnsDiagnosticsScript] Enabling DNS Diagnostics"
        Set-DnsServerDiagnostics -All $true
        Write-Verbose -Verbose "Enabling DNS client diagnostics" 
      }
      GetScript =  { @{} }
      TestScript = { $false }
      DependsOn = "[WindowsFeature]DNS"
    }

    WindowsFeature DnsTools
    {
      Ensure = "Present"
      Name = "RSAT-DNS-Server"
    }

    xDnsServerAddress DnsServerAddress 
    { 
      Address        = '127.0.0.1' 
      InterfaceAlias = $InterfaceAlias
      AddressFamily  = 'IPv4'
      DependsOn = "[WindowsFeature]DNS"
    }

    xWaitforDisk Disk2
    {
      DiskNumber = 2
      RetryIntervalSec =$RetryIntervalSec
      RetryCount = $RetryCount
    }

    cDiskNoRestart ADDataDisk
    {
      DiskNumber = 2
      DriveLetter = "F"
    }

    WindowsFeature ADDSInstall 
    { 
      Ensure = "Present" 
      Name = "AD-Domain-Services"
      DependsOn="[cDiskNoRestart]ADDataDisk"
    } 
    WindowsFeature DotNetCore 
    {
      Ensure = "Present" 
      Name   = "Net-Framework-Core"
    }
    xADDomain FirstDS 
    {
      DomainName = $DomainName
      DomainAdministratorCredential = $DomainAdminCreds
      SafemodeAdministratorPassword = $DomainAdminCreds
      DependsOn = "[WindowsFeature]ADDSInstall"
    } 
    xWaitForADDomain DscForestWait
    {
        DomainName = $DomainName
        DomainUserCredential = $DomainAdminCreds
        RetryCount = $RetryCount
        RetryIntervalSec = $RetryIntervalSec
        DependsOn = "[xADDomain]FirstDS"
    }
    xADOrganizationalUnit ProductionOU
    {
      Name = "Production"
      Path = "DC=ad,DC=waad,DC=training"
      Ensure = 'Present'
      DependsOn = "[xWaitForADDomain]DscForestWait"
    }
    xADOrganizationalUnit ProductionStaffOU
    {
      Name = "Staff"
      Path = "OU=Production,DC=ad,DC=waad,DC=training"
      Ensure = 'Present'
      DependsOn = "[xADOrganizationalUnit]ProductionOU"
    }
    xADOrganizationalUnit ProductionComputersOU
    {
      Name = "Computers"
      Path = "OU=Production,DC=ad,DC=waad,DC=training"
      Ensure = 'Present'
      DependsOn = "[xADOrganizationalUnit]ProductionOU"
    }
    xADOrganizationalUnit ProductionServersOU
    {
      Name = "Servers"
      Path = "OU=Production,DC=ad,DC=waad,DC=training"
      Ensure = 'Present'
      DependsOn = "[xADOrganizationalUnit]ProductionOU"
    }
    xADOrganizationalUnit ProductionGroupsOU
    {
      Name = "Groups"
      Path = "OU=Production,DC=ad,DC=waad,DC=training"
      Ensure = 'Present'
      DependsOn = "[xADOrganizationalUnit]ProductionOU"
    }
    xADOrganizationalUnit ProductionServiceAccountsOU
    {
      Name = "Service Accounts"
      Path = "OU=Production,DC=ad,DC=waad,DC=training"
      Ensure = 'Present'
      DependsOn = "[xADOrganizationalUnit]ProductionOU"
    }
    xADOrganizationalUnit ClassOU
    {
      Name = "Class"
      Path = "DC=ad,DC=waad,DC=training"
      Ensure = 'Present'
      DependsOn = "[xWaitForADDomain]DscForestWait"
    }
    xADOrganizationalUnit ClassUsersOU
    {
      Name = "Users"
      Path = "OU=Class,DC=ad,DC=waad,DC=training"
      Ensure = 'Present'
      DependsOn = "[xADOrganizationalUnit]ClassOU"
    }
    xADOrganizationalUnit ClassComputersOU
    {
      Name = "Computers"
      Path = "OU=Class,DC=ad,DC=waad,DC=training"
      Ensure = 'Present'
      DependsOn = "[xADOrganizationalUnit]ClassOU"
    }
    xADOrganizationalUnit ClassGroupsOU
    {
      Name = "Groups"
      Path = "OU=Class,DC=ad,DC=waad,DC=training"
      Ensure = 'Present'
      DependsOn = "[xADOrganizationalUnit]ClassOU"
    }
    xADUser StudentAdmin
    {
        DomainName = $DomainName
        DomainAdministratorCredential = $DomainAdminCreds
        UserName = "StudentAdmin"
        Password = $DomainStudentCreds
        Ensure = "Present"
        Path = "OU=Users,OU=Class,DC=ad,DC=waad,DC=training"
        DependsOn = "[xADOrganizationalUnit]ClassUsersOU"
    }
    xADUser HelpdeskUser
    {
        DomainName = $DomainName
        DomainAdministratorCredential = $DomainAdminCreds
        UserName = $HelpDeskUserUsername
        Password = $DomainHelpDeskUserCreds
        Ensure = "Present"
        Path = "OU=Staff,OU=Production,DC=ad,DC=waad,DC=training"
        DependsOn = "[xADOrganizationalUnit]ProductionStaffOU"
    }
    xADUser AccountingUser
    {
        DomainName = $DomainName
        DomainAdministratorCredential = $DomainAdminCreds
        UserName = $AccountingUserUsername
        Password = $DomainAccountingUserCreds
        Ensure = "Present"
        Path = "OU=Staff,OU=Production,DC=ad,DC=waad,DC=training"
        DependsOn = "[xADOrganizationalUnit]ProductionStaffOU"
    }
    xADUser ServerAdmin
    {
        DomainName = $DomainName
        DomainAdministratorCredential = $DomainAdminCreds
        UserName = $ServerAdminUsername
        Password = $DomainServerAdminCreds
        Ensure = "Present"
        Path = "OU=Staff,OU=Production,DC=ad,DC=waad,DC=training"
        DependsOn = "[xADOrganizationalUnit]ProductionStaffOU"
    }  
    xADUser BackupUser
    {
        DomainName = $DomainName
        DomainAdministratorCredential = $DomainAdminCreds
        UserName = $BackupUserUsername
        Password = $DomainBackupUserCreds
        Ensure = "Present"
        Path = "OU=Service Accounts,OU=Production,DC=ad,DC=waad,DC=training"
        DependsOn = "[xADOrganizationalUnit]ProductionServiceAccountsOU"
    }
    xADUser HelperAccount
    {
        DomainName = $DomainName
        DomainAdministratorCredential = $DomainAdminCreds
        UserName = $HelperAccountUsername
        Password = $DomainHelperAccountCreds
        Ensure = "Present"
        Path = "OU=Service Accounts,OU=Production,DC=ad,DC=waad,DC=training"
        DependsOn = "[xADOrganizationalUnit]ProductionServiceAccountsOU"
    }
    xADGroup DomainAdmins
    {
      GroupName = "Domain Admins"
      Ensure = 'Present'
      MembersToInclude =  $ServerAdminUsername, "StudentAdmin"
      DependsOn = "[xADUser]ServerAdmin", "[xADUser]StudentAdmin"
    }
    xADGroup AccountingUsers
    {
      GroupName = "Accounting Users"
      GroupScope = "Global"
      Category = "Security"
      Description = "Conjurers of Arithmetic and Paperwork"
      Ensure = 'Present'
      MembersToInclude = $AccountingUserUsername
      Path = "OU=Groups,OU=Production,DC=ad,DC=waad,DC=training"
      DependsOn = "[xADOrganizationalUnit]ProductionGroupsOU", "[xADUser]AccountingUser"
    }
    xADGroup HelpdeskUsers
    {
      GroupName = "HelpdeskUsers"
      GroupScope = "Global"
      Category = "Security"
      Description = "The valiant frontline of IT Support"
      Ensure = 'Present'
      MembersToInclude = $HelpDeskUserUsername, $HelperAccountUsername
      Path = "OU=Groups,OU=Production,DC=ad,DC=waad,DC=training"
      DependsOn = "[xADOrganizationalUnit]ProductionGroupsOU", "[xADUser]HelpdeskUser"
    }
    xADGroup ServiceAccounts
    {
      GroupName = "ServiceAccounts"
      GroupScope = "Global"
      Category = "Security"
      Description = "Robots that do our bidding"
      Ensure = 'Present'
      MembersToInclude = $BackupUserUsername
      Path = "OU=Groups,OU=Class,DC=ad,DC=waad,DC=training"
      DependsOn = "[xADOrganizationalUnit]ClassGroupsOU", "[xADUser]BackupUser"
    }
    xTimeZone SetTimezone
    {
        IsSingleInstance = 'Yes'
        TimeZone         = 'Pacific Standard Time'
    }
    LocalConfigurationManager 
    {
      ConfigurationMode = 'ApplyOnly'
      RebootNodeIfNeeded = $true
    }
  }
} 