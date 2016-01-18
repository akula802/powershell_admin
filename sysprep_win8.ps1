# SYSPREP SCRIPT FOR WINDOWS 8/8.1/10

# This script first changes a registry value that tells sysprep NOT to remove device drivers during the 'generalize' pass
# Then it removes Windows apps that cause sysprep to fail in Windows 8/8.1 (and 10)

#----------------------------------------------------------------------------------------------------------------------------------------------

# This checks to see if the current Session is admin, if not propmpts for admin level with UAC
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))

    {   
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
    }

# Sets script execution policy to Unrestricted for this session only
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

# Change the registry key
Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\Sysprep\Settings\sppnp -Name PersistAllDeviceInstalls -Value 1

#----------------------------------------------------------------------------------------------------------------------------------------------

# Begin removing apps that screw with sysprep in Windows 8/8.1
Get-AppxPackage | Remove-AppxPackage
cls

# Xbox music is difficult to script uninstall, user may have to do this
Write-Warning "Click on Start, search for Music, right-click and Uninstall. Press Enter when done."
Pause

# Once more for good measure
Get-AppxPackage | Remove-AppxPackage
cls

#----------------------------------------------------------------------------------------------------------------------------------------------

# System is ready for sysprep - remind user of the setting required (can't pass args to sysprep)
Write-Warning "Press enter to start sysprep. Select oobe / generalize / shutdown."

C:\Windows\System32\Sysprep\sysprep.exe

Pause
