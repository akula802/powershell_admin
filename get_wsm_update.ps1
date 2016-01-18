# Script to automatically check for and download Watchguard System Manager updates
# Run this script as a scheduled task as often as you think is necessary


# Created on September 20, 2015 by Brian Hartley
# Last edited on January 17, 2016 by Brian Hartley


# To use, create a C:\scripts\wsm directory and run the script once
# It will create a text file with a timestamp and the URL of the current .exe installer
# It will also download the .exe installer
# The next time it runs, it will scrape the WG website for newer versions of WSM
# If a newer version is found, it will download it, update the text file, and send you an email


# To use the email settings you must create a hashed text file containing your password
# Do not store your email password in this script in plain text
# To create this file, use this command from an admin-level Powershell:
# read-host -assecurestring | convertfrom-securestring | out-file C:\scripts\emailPassword.txt
# Type in your password and hit enter


#--------------------------------------------------------------------------------------------------------


# Define some variables
$download_page = "https://watchguardsupport.secure.force.com/software/SoftwareDownloads?current=true&familyId=a2RF00000009GmGMAU"
$linkFile = "C:\scripts\wsm\wsm.txt"


#--------------------------------------------------------------------------------------------------------


# Retrieve the new WSM version descriptor and the link to .exe installer
$new_wsm_version_text = ((Invoke-WebRequest -Uri $download_page).links | where innerHTML -like "*Watchguard System Manager*").innerText
$new_wsm_version_value = $new_wsm_version_text -replace '\D+'
$new_wsm_link = ((Invoke-WebRequest -Uri $download_page).links | where innerHTML -like "*Watchguard System Manager*").href


# Read existing WSM version from existing text file
$exising_wsm_version = (gc $linkFile)[0]
$exising_wsm_version_value = $exising_wsm_version -replace '\D+'


#--------------------------------------------------------------------------------------------------------


# Define the email variables
$ToAddress = "your@email"
$FromAddress = "yourOther@email"
$Subject = "Watchguard System Manager $new_wsm_version_value has been released"
$SMTPServer = "Mail server address"
$username = "@username"
$pass = cat C:\scripts\emailPassword.txt | ConvertTo-SecureString
$Creds = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $pass


# String to separate log entries for readability
$separator = @"

---------------------------------------------------------

"@


#--------------------------------------------------------------------------------------------------------


# Compare the new WSM version with the existing WSM version and update the text file if newer
# Also download the .exe installer and email the admin
if ($new_wsm_version_value -gt $exising_wsm_version_value)
    {

        Write-Host "A new version of WSM is available. Downloading..."

        # Overwrite the text file
        Clear-Content $linkFile
        $now = ([DateTime]::Now).ToString()
        Add-Content $linkFile $new_wsm_version_text
        Add-Content $linkFile $new_wsm_link
        Add-Content $linkFile $now


        # Download the new WSM installer
        $download_path = ("C:\scripts\wsm\WSM_" + "$new_wsm_version_value" + ".exe")
        $client = New-Object System.Net.WebClient
        $client.DownloadFile($new_wsm_link, $download_path)


        # Sleep the script for 10 seconds to make sure download completes
        Start-Sleep -Seconds 10

    
        # Check to see if the download was successful and update email body accordingly
        if (Test-Path ("C:\scripts\wsm\WSM_" + $new_wsm_version_value + ".exe"))
            {
                $emailBody = "$new_wsm_version_text was successfully downloaded."
                Write-Host "Download successful"
            }
        else {
                $emailBody = "$new_wsm_version_text is available but the automatic download failed. Manually download it from $download_page."
                Write-Host "Download failed."
            }

    
        # First, clear the built-in $error variable
        $error.Clear()


        # Send the email to admin
        try {
            Send-MailMessage -From $FromAddress -To $ToAddress -Subject $Subject -Body $emailBody -SmtpServer $SMTPServer -UseSsl -Credential $Creds

            if (!$error -eq $false) {
                $failedEmailLog = "C:\scripts\repl1\failedEmailLog.txt"
                If (-Not (Test-Path $failedEmailLog)) {Out-File $failedEmailLog}
                Add-Content $failedEmailLog "Script was successful, but failed to send email at $now. See error below. `r`n"
                Add-Content $failedEmailLog $error
                Add-Content $separator
            } # end if block

        } # end try block


        catch {
            $failedEmailLog = "C:\scripts\wsm\failedEmailLog.txt"
            $failedEmailMsg = "Script was successful, but failed to invoke Send-MailMessage command at $now. See error below. `r`n"
            If (-Not (Test-Path $failedEmailLog)) {Out-File $failedEmailLog}
            Add-Content $failedEmailLog $failedEmailMsg
            Add-Content $failedEmailLog $error
            Add-Content $separator
        } # end catch block


} #end if block (main)


else {

    # Cleanly exit the script if no action is necessary
    Write-Host "Current version of WSM is already installed."
    exit

} # end else (main)
