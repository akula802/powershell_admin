<# 

.Synopsis
Returns a table of drive letters, volume names, and free space in GB.

.DESCRIPTION
For one or more given computers, this script evaluates drive space based on drive letter.
The results are tabulated for each computer, with each table listing the computer name, 
drive letter, free space (in GB), and total drive size (in GB).

.PARAMETER ComputerName
Specifies remote computers by name. Must be a string (or array of strings).

.EXAMPLE  
Get-FreeDiskSpace
This runs the script on the local computer only.


.EXAMPLE
Get-FreeDiskSpace -ComputerName pc1
This runs the script against a remote computer named 'pc1'

.EXAMPLE
Get-FreeDiskSpace -ComputerName pc1, pc2, pc3
This runs the script against three remote computers, named pc1, pc2, and pc3. You
can also specify several remote computers with a variable, such as $pcs = 'pc1', 
'pc2', 'pc3' or with a command such as Get-ADComputer.

.LINK
Link to private help file on organization's web server

#>

function Get-FreeDiskSpace {
    [CmdletBinding()]
    param(
        # Can change this later to prompt for ToAddress on script run (not for scheduled task)
        #[Parameter(Mandatory=$True)]
        #[string[]]$ToAddress,

        [Parameter(Mandatory=$False)]
        [string[]]$ComputerName
    )

    # Get drive / space info and format into a readable table
    # Spaces in hashtables are for table formatting, DO NOT CHANGE
    # IDS: may be easier to create a new PSObject
    $freespace = Get-WmiObject win32_logicaldisk | 
        Format-Table @{n='Computer     '; e={Get-Content Env:\COMPUTERNAME}}, `
        @{n='Drive  '; e={$_.DeviceID}}, `
        @{n='Volume  '; e={$_.VolumeName}}, `
        @{n='Free (GB)  ' ; e={$_.freespace / 1gb -as [int]}}, `
        @{n='Size (GB)  ' ; e={$_.size / 1gb -as [int]}} `
        -AutoSize

    # Variables for email to admin
    $ToAddress = "toAddress@some-server.com"
    $FromAddress = "you@your-server.com"
    $Subject = "FreeDiskSpace report for {Get-Content Env:\COMPUTERNAME}"
    $SMTPServer = "smtp.your-server.com"
    $username = "you@your-server.com"
    $pass = cat C:\Scripts\adminEmailPass.txt | ConvertTo-SecureString
    $Creds = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $pass

    # Create / overwrite log file, timestamp it
    $LogFile = New-Item C:\Scripts\freespace\freeSpaceResults.txt -ItemType File -Force
    $TimeStamp = Get-Date
    $TimeStamp | Out-File C:\Scripts\freespace\freeSpaceResults.txt -Append

    # For each computer name, run Get-FreeDiskSpace and append results to file
    $ComputerName | foreach{ $freespace} | Out-File C:\Scripts\freespace\freeSpaceResults.txt -Append

    # Read results file, convert to string to place in email body
    $resultsBody = (Get-Content $LogFile | Out-String)

    # Email results to admin
    Send-MailMessage -From $FromAddress -To $ToAddress -Subject $Subject -Body $resultsBody -SmtpServer $SMTPServer -UseSsl -Credential $Creds -Attachments $LogFile

}
