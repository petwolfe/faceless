


#################################################################################################
#
# system-metrics-gen.ps1
#
#################################################################################################
<#
.SYNOPSIS
    Pulls information from HP OpenView through curl-like interface
    
.DESCRIPTION  
	Collects system names, duration for testing and end time of testing through an excel file.
    
    
.REQUIREMENTS

    	Authentication is hard-coded. This must be taken care of.
    	The URL should remain unchanged.
	#NOTDONE -The systems should have agents installed and collected data should be made available. This can be checked by the web-interface.

	Optional charting scripts must be present in the same directory.
 
.PARAMETER ConfigFile
    [Optional] Path to test definitions.  


.EXAMPLE
    Drop the systemnames and run the script.
    This is not yet implemented->
    .\crawler.ps1 -ConfigFile C:\PerfTest\caaanfig.xml  

.NOTES
    Date      	Who     Changes
    
	
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



$GraphList = @( #Copy Strings as they appear on the PerfManager interface, add '+' for spaces.
"CPU+Summary",
"Memory+Summary",
"Disk+Summary",
"Network+Summary"
)

#Adjust chart height and width here.
[int]$ChartWidth = 700
[int]$ChartHeight = 200



#tread carefully further
$PerfEndPath = $PSScriptRoot + "\"
$ocmconfig = "Settings.xlsx"
$ConfigFile = $PerfEndPath + $ocmconfig
if ((Test-Path $ConfigFile) -ne $TRUE)
{
    throw "Cannot find $ConfigFile"
}
Write-Host "`r`nThis takes a while. Please wait.`r`n"
$xcl2 = New-Object -ComObject Excel.Application
$xcl2.Visible = $false
$wb3 = $xcl2.Workbooks.Open($ConfigFile)
$WS2 = $wb3.sheets.item("Sheet1")
$PerfEndDate = $WS2.Range("B1").Text
$PerfEndTime = $WS2.Range("B2").Text
$PerfDuration = $WS2.Range("B3").Text
$SystemList = @(
$WS2.Range("B4").Text,
$WS2.Range("B5").Text,
$WS2.Range("B6").Text,
$WS2.Range("B7").Text,
$WS2.Range("B8").Text,
$WS2.Range("B9").Text,
$WS2.Range("B10").Text,
$WS2.Range("B11").Text,
$WS2.Range("B12").Text,
$WS2.Range("B13").Text
)
$SystemList = $SystemList |  ? { $_ }
$xcl2.Quit()

#Workaround for Handling columns
Function NumToRow{
	param($Value)
	Switch ($Value) {
		1 {$value = "A"}
		2 {$value = "B"}
		3 {$value = "C"}
		4 {$value = "D"}
		5 {$value = "E"}
		6 {$value = "F"}
		7 {$value = "G"}
		8 {$value = "H"}
		9 {$value = "I"}
		10 {$value = "J"}
		11 {$value = "K"}
		12 {$value = "L"}
		13 {$value = "M"}
		14 {$value = "N"}
		15 {$value = "O"}
		16 {$value = "P"}
		17 {$value = "Q"}
		18 {$value = "R"}
		19 {$value = "s"}
		20 {$value = "T"}
		21 {$value = "U"}
		22 {$value = "V"}
		23 {$value = "W"}
		24 {$value = "X"}
		25 {$value = "Y"}
		26 {$value = "Z"}
	}
	#Write-Host "$value"
	return $value
}

[int]$global:NAR = 1
[int]$global:NAP = 20
$xcl = new-object -ComObject Excel.Application
$wb = $xcl.workbooks.add(1)
$dst = $wb.activesheet
$dst.Name = "Data"
$gst = $wb.WorkSheets.Add()
$gst.Name = "Graphs"

#Write-Host "`r`nThis takes a while. Please wait.`r`n"
#Write-Host "This takes a while. Please wait.`r`n"

foreach ($PerfSystem in $SystemList){
Write-Host "Begin building Data for $PerfSystem.`r`n"

	foreach ($PerfGraph in $GraphList){
		$OH = (New-Object System.Net.WebClient).DownloadString("http://senna:8081/OVPM/?CUSTOMER=ovpmuser&PASSWORD=&SYSTEMNAME=$PerfSystem&GRAPHTEMPLATE=Agents&GRAPH=%22$PerfGraph%22&GRAPHTYPE=csv&DATERANGE=$PerfDuration&ENDDATE=%22$PerfEndDate%20$PerfEndTime%22")
		#$OH > "$PerfEndPath$PerfSystem-$PerfGraph-$($PerfEndDate.replace("/","-") )-$($PerfEndTime.replace(":","-"))-Graph.html"				
		$Heading = $OH | % { [regex]::matches( $_ , '(?<=<h1>)(.*?)(?=</h1>)' ) } | select -expa value
		$Subhead = $OH | % { [regex]::matches( $_ , '(?<=<h2>)(.*?)(?=</h2>)' ) } | select -expa value
		$a = $OH.indexof("</pre>")
		$b = $OH.indexof("<pre>") + 5		
		$d = $a - $b
		[array]$Ctt = $OH.substring($b,$d) -split "\n"
		$Columns = $Ctt[0].split(",").GetUpperBound(0) + 1;		
		#Selections
		$Scn = NumToRow 1 
		$Ecn = NumToRow $Columns
		#row Manipulations
		[int]$Srw = $global:NAR 
		[int]$Erw = $global:NAR + $Ctt.count - 2	
		for($i=0; $i -lt ($Ctt.count -1); $i++) { 
			[array]$RowSplits = $Ctt[$i].split(",")	
			[int]$m = $i+$global:NAR			
			for ($k=0; $k -lt $Columns; $k++) {
				[int]$n = 1+$k				
				$dst.cells.item($m,$n) = 	$RowSplits[$k]				
			}		
		}		
		$global:NAR = $Erw + 1	
		#Write-Host $Scn $Srw $Ecn $Erw $Ctt.count
		$chart=$gst.Shapes.AddChart().Chart
		$chart.chartType = 73
		$chartdata=$dst.Range("$Scn${Srw}:$Scn${Erw}", "$Ecn${Srw}:$Ecn${Erw}")
		$chart.SetSourceData($chartdata)
		#$chart.seriesCollection(1).Select() | Out-Null
		#$chart.SeriesCollection(1).ApplyDataLabels() | out-Null 
		$chart.HasTitle = $True
		$chart.ChartTitle.Text = $Heading		
		$cobj = $chart.Parent
		$cobj.top=$global:NAP
		$cobj.Left=10
		$cobj.Height=$ChartHeight
		$cobj.Width=$ChartWidth
		$global:NAP = 	20 + $ChartHeight + $global:NAP
	}
Write-Host "Finished working on $PerfSystem.`r`n"	
}
Write-Host "Done.`r`nRemember to save the Excel file.`r`n"
$xcl.Visible = $true
#END


	
