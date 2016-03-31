


#################################################################################################
#
# system-metrics-gen.ps1
#
#################################################################################################
<#
.SYNOPSIS
    Pulls information from HP OpenView through curl-like interface
    
.DESCRIPTION  
	
    
    
.REQUIREMENTS

    Authentication is hard-coded. This must be taken care of.
	The systems should have agents installed and collected data should be made available. This can be checked by the web-interface.
	The URL should remain unchanged.
	Optional charting scripts must be present in the same directory.
 
.PARAMETER ConfigFile
    [Optional] Path to test definitions.  


.EXAMPLE
    Drop the systemnames and run the script.
    This is not yet implemented->
    .\crawler.ps1 -ConfigFile C:\PerfTest\caaanfig.xml  

.NOTES
    Date      	Who     Changes
    03/30/2016  INYDNN	Initial drop
	
param(   
	[Parameter(Position=0)]    [string] $ConfigFile = "C:\Projects\EIM-AWB\Scripts\Bin\AlteryxPerfTestConfig.xml"
)
	
# Config File Checks
if ($ConfigFile -ne $null)
{
    $ConfigFile = $ConfigFile.Trim()
}

if ((Test-Path $ConfigFile) -ne $TRUE)
{
    throw "Configuration data or file is missing. Please provide path to the file as a parameter to the script."
}

[String] $FileData = Import-CSV $ConfigFile

#>

$SystemList = @(
"Node1",
"Node2"
)

$GraphList = @(
"CPU+Summary",
"Memory+Summary",
"Disk+Summary",
"Network+Summary"
)

$PerfEndDate = "03/29/2016"
$PerfEndTime = "20:00"
$PerfDuration = "480"
#$PerfEndPath = "C:\Projects\Play-Ep2\"
$PerfEndPath = (Get-Location).Path

#-----------------------------------------
# -- THE CSV IMPORT PART
#-----------------------------------------


foreach ($PerfSystem in $SystemList){

	foreach ($PerfGraph in $GraphList){

		$Container = (New-Object System.Net.WebClient).DownloadString("http://ovpmserver:8081/OVPM/?CUSTOMER=ovpmuser&PASSWORDovpmpassword=&SYSTEMNAME=$PerfSystem.cguser.capgroup.com&GRAPHTEMPLATE=Agents&GRAPH=%22$PerfGraph%22&GRAPHTYPE=csv&DATERANGE=$PerfDuration&ENDDATE=%22$PerfEndDate%20$PerfEndTime%22")
		$Container > "$PerfEndPath$PerfSystem-$PerfGraph-$($PerfEndDate.replace("/","-") )-$($PerfEndTime.replace(":","-"))-Graph.csv"

	}

} 

	
	
