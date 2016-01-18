# Created on October 17, 2015 by Brian Hartley
# Last modified on January 17, 2016 by Brian Hartley


# Send email (general use)
# Intended to be run on a scheduled task, such as when a certain event is recorded


# To use the email settings you must create a hashed text file containing your password
# Do not store your email password in the script in plain text!!!
# To create this file, use this command from an admin-level Powershell:
# read-host -assecurestring | convertfrom-securestring | out-file C:\scripts\emailPassword.txt
# Type in your password and hit enter

#----------------------------------------------------------------------------------------------------------


# Get current timestamp and local computer name
$now = ([DateTime]::Now).ToString()
$CompName = Get-Content Env:\COMPUTERNAME


# String to separate log entries for readability
$separator = @"

---------------------------------------------------------

"@


# Construct the email credentials
$username = "you@yourserver.com"
$pass = cat C:\scripts\adminEmailPass.txt | ConvertTo-SecureString
$Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $pass


# Build the email parameters as splatting hash table
$param = @{
    SmtpServer = "smtp.yourserver.com"
    Port = 587
    UseSsl = $true
    Credential = $Creds
    From = "you@yourserver.com"
    To = "someone@anotherserver.com"
    Subject = "Event recorded on $CompName at $now"
    Body = "Event recorded on $CompName at $now. Action is required."
}


# Clear the built-in error variable prior to sending admin email
$error.Clear()


# Send the email
# If message fails, creates a failedEmailLog.txt file to assist in troubleshooting
# Records whether it had problems connecting to the mail server, or with invoking the Send-MailMessage command
try {

    Send-MailMessage @param

    if (!$error -eq $false) {
        # Don't forget to change the next line so your log file goes to the proper place
        $failedEmailLog = "C:\scripts\this_scripts_directory\failedEmailLog.txt"
        If (-Not (Test-Path $failedEmailLog)) {Out-File $failedEmailLog -Encoding ascii}
        Add-Content $failedEmailLog "Script was successful, but failed to send email at $now. See error below. `r`n"
        Add-Content $failedEmailLog $error
        Add-Content $failedEmailLog $separator
        }
    }

catch {
    # Don't forget to change the next line so your log file goes to the proper place
    $failedEmailLog = "C:\scripts\azure_check\failedEmailLog.txt"
    If (-Not (Test-Path $failedEmailLog)) {Out-File $failedEmailLog -Encoding ascii}
    Add-Content $failedEmailLog "Script was successful, but failed to invoke Send-MailMessage command at $now. See error below. `r`n"
    Add-Content $failedEmailLog $error
    Add-Content $failedEmailLog $separator
    }

