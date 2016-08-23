# Purpose: Encode Powershell scripts/functions into Base64. Useful when copying scripts to clipboard to paste in RDP sessions.
# Author: Sam Granger
# Version: 2016.08.23

# ToRun Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force

##############
##	 INIT 	##
##############

Param(	[string]$scriptPath,
		[string]$outputPath,
		[int]$splitBy
)

Set-StrictMode -version 2

$date 		= Get-Date -format yyyy-MM-dd-HHmmss
$thisscriptname = $MyInvocation.MyCommand.Name
$username   = $env:username
$VERSION	= "2016.08.23"


##################
##	 Static 	##
##################

$firstLine = "`$base64 = `"`""
$lastLine1 = "[string]`$UTF8 = `$([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(`"`$base64`")) -split(`"``n`") | foreach {[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(`"`$_`"))}) -join(`"``n`")"
$lastLine2 = "Invoke-Expression `$UTF8"


##################
##	 FUNCTIONS 	##
##################

function usage { 
	Write-Host -foregroundcolor "yellow" "Usage  : $thisscriptname"
	Write-Host -foregroundcolor "yellow" "           -scriptPath 'path-to-script-to-convert'"
	Write-Host -foregroundcolor "yellow" "           [-outputPath 'path-to-output-encoded-script (default: scriptPath)]'"
	Write-Host -foregroundcolor "yellow" "           [-splitBy 'no.-of-lines-to-split-base64-by' (default: 5)]"
	Write-Host 
	Write-Host
	Write-Host -foregroundcolor "yellow" "Example: .\$thisscriptname -scriptPath "".\myscript.ps1"" ";
}

###################
## 		MAIN	 ##
###################

#Check if parameters are supplied
if  (!($scriptPath)) {
	usage;
	exit 1
}

if (!($outputPath)) {
	$outputPath = Split-Path $scriptPath;
	}


#Default to '5' if no splitby Lenght specified
if (!($splitBy)) {
	$splitBy = 5}
	
#Create outputFile name
$scriptName = (Get-Item $scriptPath).Basename
$outputFile = "$outputPath\$($scriptName)_base64.ps1"

Write-Host "[*] Base64 encoding '$scriptPath' to '$outputFile"

#Import Script
Write-host "[*] Importing script"
$importScript = Get-Content $scriptPath -encoding UTF8

#Convert each line to base64
$base64Script = @()
foreach ($line in $importScript) {
	$base64Script += [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($line))
	}

#Convert entire script to base64
Write-Host "[*]  Converting to Base64"
$base64ScriptToString = $base64Script -join("`n") #Convert varible to string
$base64Long = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($base64ScriptToString))

#Get length of base64 encoding
$lenTotal = $base64Long.Length
$lenSplit = [math]::round($lenTotal/$splitBy) + 1
Write-Host "[!] Base64 Length: $lenTotal `t Split No.: $splitBy `t Split Size: $lenSplit"

#Write first line of file
Write-Host "[*] Preparing output file"
$firstLine | Out-File $outputFile

Write-Host "[*] Splitting file out to '$outputFile'"
$endLength = -1
foreach($i in 1..$splitBy) {
	$splitMulti = $splitBy - $i
	$startLength = $endLength + 1
	$endLength = $lenTotal - $($lenSplit*$splitMulti)
	Write-Host "Start Length: $startLength `t End Length: $endLength `t i:$i"
	$splitText = $base64Long[$startLength..$endLength] -join("")
	"`$base64 += `"$splitText`"" | Out-File -append $outputFile
	$i++
	}

Write-Host "[*] Finalizing output file"
$lastLine1 | Out-File -append $outputFile
$lastLine2 | Out-File -append $outputFile

#Done
Write-Host "[**] Done"
