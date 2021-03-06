# ##################################################################################################
# Script name			: StatiCriteriaINEXSuspend.ps1
# Summary File Name		: StatiCriteriaINEXSuspend.ps1
# Author				: ATS Team
# Date					: 11/10/2016
# OS					: Win 7/8.1/10 32/64 US/JP
# Discription           : This Script performs Suspend/Resume operation for n trials. 
# Version Info		  	: v2.3
# Revision History	  	: 
#							Date       |       Version
#							___________|________________
#							03/03/2010 | 1.0   (Initial Release for Win7 32 OS)
#							04/16/2010 | 1.1   (Updated to detect the new devices arrival)
#							11/04/2010 | 2.0   (Updated to Powershell to support ATS v5.0 for all OS)
#                           04/19/2011 | 2.1   (Updated to handle more loop count and log file extension)
#                           04/14/2015 | 2.2   (Activate wake-up timer for Win 10 & Hid Errors)
#                           11/10/2016 | 2.3  (Overcome Monitor OFF issue after system wakeup)
# ##################################################################################################
#                          VARIABLE INITIALIZATION SECTION - Starts Here
# ################################################################################################## 
  $ErrorActionPreference  = 'SilentlyContinue'
  $Global:ScriptPath 	  =   $myInvocation.MyCommand.Path
  $Global:ScriptName      =   $myInvocation.MyCommand.Name
  $Global:LogFileName     =   $Global:ScriptName.Replace(".ps1","")
  $Global:LogFilePath     =   $Global:ScriptPath.Replace(".ps1","_DevLog.htm")
  $Global:CurDir          =   Split-Path -parent $Global:ScriptPath
  
  $callUtilities = Import-Module "$Global:CurDir\ATS Sys Files\bin\ATS.Scripts.Utilities.dll"
  $callWASP = Import-Module "$Global:CurDir\ATS Sys Files\bin\WASP.dll"
  $Global:logger = [Logger]::GetLogger($Global:ScriptPath.Replace(".ps1","_Log.htm"), $Global:ScriptName)

  $callVB = [System.reflection.assembly]::Loadwithpartialname("Microsoft.visualBasic")
  $VBInteraction = [microsoft.visualbasic.interaction]
  $Global:MsgBox        =  New-object -comobject wscript.shell
  $Global:FailCount = 0
  $Global:IterationFail = 0
  $Global:IterationFailCount = 0

  
# ##################################################################################################
#                          VARIABLE INITIALIZATION SECTION - Ends Here
# ################################################################################################## 

# ##################################################################################################
#                         USER DEFINED FUNCTIONS SECTION - Starts Here
# ##################################################################################################
# Function to turn on monitor after suspend
Function MonitorON
{
start-process MSPaint.exe
sleep 2
$callWASP = Reflection.Assembly]::LoadFile("$Global:CurDir\ATS Sys Files\bin\WASP.dll")
$ActivatePaint = Select-window mspaint* | Set-WindowActive
Select-Window mspaint* | Send-Keys "%( )n"
sleep 1
Select-Window mspaint* | Send-Keys "%( )x"
sleep 1
Select-Window mspaint* | Send-Keys "%( )c"
}
# ##################################################################################################
# Function to check if a value is a numeric value. This function is used in PMLongrunUI() function

Function isNumeric ($x)
{   $xsamp = 0
    $isNum = [System.Int32]::TryParse($x,[ref]$xsamp)
    return $isNum
}   

# ##################################################################################################
# Function to create the form for user inputs of testmode, loopcount, elapse time and resume time

Function PMLongrunUI()
{
    [reflection.assembly]::loadwithpartialname("System.Windows.Forms")
    [reflection.assembly]::loadwithpartialname("System.Drawing")
    $objForm = New-Object System.Windows.Forms.Form 
    $objForm.Text = "ATS Statistical Criteria INEX PM Script "
    $objForm.Size = New-Object System.Drawing.Size(350,380) 
    $objForm.StartPosition = "CenterScreen"

    $objForm.KeyPreview = $True
    $objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
        {[int]$Global:LoopCount=$objTextBox1.Text; [int]$Global:ElapseTime=$objTextBox3.Text; [int]$Global:ResumeTime=$objTextBox2.Text; $objForm.Close()}})
    $objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
        {$objForm.Close()}})

    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = New-Object System.Drawing.Size(120,300)
    $OKButton.Size = New-Object System.Drawing.Size(75,23)
    $OKButton.Text = "OK"
    $OKButton.Add_Click({[int]$Global:LoopCount=$objTextBox1.Text; [int]$Global:ElapseTime=$objTextBox3.Text;  [int]$Global:ResumeTime=$objTextBox2.Text;$objForm.Close()})
    $objForm.Controls.Add($OKButton)

    $TestMode = New-Object System.Windows.Forms.Label
    $TestMode.Location = New-Object System.Drawing.Size(10,25) 
    $TestMode.Size = New-Object System.Drawing.Size(120,20) 
    $TestMode.Text = "Select the test mode:"
    $objForm.Controls.Add($TestMode) 

    $RadioButton1 = New-Object System.Windows.Forms.radiobutton
    $RadioButton1.Location = New-Object System.Drawing.Size(150,20) 
    $RadioButton1.Size = New-Object System.Drawing.Size(100,20) 
    $RadioButton1.Text = "Interactive"
    $objForm.Controls.Add($RadioButton1) 

    $RadioButton2 = New-Object System.Windows.Forms.radiobutton
    $RadioButton2.Location = New-Object System.Drawing.Size(150,40) 
    $RadioButton2.Size = New-Object System.Drawing.Size(100,20) 
    $RadioButton2.Text = "Silent"
    $objForm.Controls.Add($RadioButton2) 

    $Loopcnt = New-Object System.Windows.Forms.Label
    $Loopcnt.Location = New-Object System.Drawing.Size(10,80) 
    $Loopcnt.Size = New-Object System.Drawing.Size(320,20) 
    $Loopcnt.Text = "Please enter the Loop count: (Example: 150) "
    $objForm.Controls.Add($Loopcnt) 

    $objTextBox1 = New-Object System.Windows.Forms.TextBox 
    $objTextBox1.Location = New-Object System.Drawing.Size(10,100) 
    $objTextBox1.Size = New-Object System.Drawing.Size(290,20) 
    $objForm.Controls.Add($objTextBox1) 

    $ResumeTime = New-Object System.Windows.Forms.Label
    $ResumeTime.Location = New-Object System.Drawing.Size(10,160) 
    $ResumeTime.Size = New-Object System.Drawing.Size(320,30) 
    $ResumeTime.Text = "Please enter the Resume time in seconds: (Minimum Time: 30)"
    $objForm.Controls.Add($ResumeTime) 

    $objTextBox2 = New-Object System.Windows.Forms.TextBox 
    $objTextBox2.Location = New-Object System.Drawing.Size(10,190) 
    $objTextBox2.Size = New-Object System.Drawing.Size(290,20) 
    $objForm.Controls.Add($objTextBox2) 

    $ElapseTime = New-Object System.Windows.Forms.Label
    $ElapseTime.Location = New-Object System.Drawing.Size(10,240) 
    $ElapseTime.Size = New-Object System.Drawing.Size(320,30) 
    $ElapseTime.Text = "Please enter the Elapse time in seconds: (Minimum Time: 30)"
    $objForm.Controls.Add($ElapseTime) 

    $objTextBox3 = New-Object System.Windows.Forms.TextBox 
    $objTextBox3.Location = New-Object System.Drawing.Size(10,270) 
    $objTextBox3.Size = New-Object System.Drawing.Size(290,20) 
    $objForm.Controls.Add($objTextBox3) 

    $objForm.Topmost = $True

    $objForm.Add_Shown({$objForm.Activate()})
    [void] $objForm.ShowDialog()
             
    while (!(isNumeric($Global:LoopCount)) -or !(isNumeric($Global:ResumeTime)) -or !(isNumeric($Global:ElapseTime)))
    {   $vbInteraction::MsgBox("Please insert only numeric values for Loop count, Resume time and Elapse time", 'OkOnly,information', "StatiCriteriaINEXSuspend")
        [void] $objForm.ShowDialog()
    }
    $Global:TestMode = ""
    If ($RadioButton1.Checked){$Global:TestMode = "Interactive"}
    If ($RadioButton2.Checked){$Global:TestMode = "Silent"}

    while (($Global:TestMode -ne "Interactive") -and ($Global:TestMode -ne "Silent" ))
    {   $vbInteraction::MsgBox("Please select the Test mode", 'OkOnly,information', "StatiCriteriaINEXSuspend")
        [void] $objForm.ShowDialog()
        If ($RadioButton1.Checked){$Global:TestMode = "Interactive"}
        If ($RadioButton2.Checked){$Global:TestMode = "Silent"}
    }
    
    Logger "User selected Test mode : $Global:TestMode" 1 
    Logger "User entered Loop count : $Global:LoopCount" 1 
    Logger "User entered Resume time : $Global:ResumeTime seconds" 1 
    Logger "User entered Elapse time : $Global:ElapseTime seconds" 1 
}

# ##################################################################################################

Function GetPowerScheme
{ If ($Global:OSName -eq "XP")
  {$RegPath = "HKCU:\Control Panel\PowerCfg"
  $RegProp = "CurrentPowerPolicy"
  $ActivePScheme = ReadRegistryValue $RegPath $RegProp
  $StrKeyPath = "HKCU:\Control Panel\PowerCfg\PowerPolicies\$ActivePScheme"
  $StrValueName = "Name"}
  Else
  {$RegPath = "HKLM:\System\CurrentControlSet\Control\Power\User\PowerSchemes"
  $RegProp = "ActivePowerScheme"
  $ActivePScheme = ReadRegistryValue $RegPath $RegProp
  $StrKeyPath = "HKLM:\System\CurrentControlSet\Control\Power\User\PowerSchemes\$ActivePScheme"
  $StrValueName = "FriendlyName"}
  $PowerScheme = ReadRegistryValue $StrKeyPath $StrValueName
  write-host "PowerScheme is $PowerScheme"
  If (($PowerScheme -eq "Energy Star") -Or ($PowerScheme -eq "ThinkPad Default") -Or ($PowerScheme -eq "Energy Saver"))  
     { write-host "Current Power plan is $PowerScheme which is the default Power plan" -foreground Blue
       Logger "Current Power plan is $PowerScheme which is the default Power plan" 1
       Write-host "Script will wait for 30 seconds to get the user response" -Foreground Blue      
       $UserResponse = $Global:MsgBox.popup("Current System Power plan is $PowerScheme which is the default Power plan. Do you want to change the current Power plan?",30,"SystemPowerplanverification",4+32)
     } 
  Else
	 { write-host "Current Power plan is " $PowerScheme " which is not the default Power plan" -Foreground Blue
       Logger "Current Power plan is $PowerScheme which is not the default Power plan" 1
       Write-host "Script will wait for 30 seconds to get the user response" -Foreground Blue      
       $UserResponse = $Global:MsgBox.popup("Current System Power plan is $PowerScheme which is not the default Power plan. Do you want to change the current Power plan?",30,"SystemPowerplanverification",4+32)
     }       

  If ( $UserResponse -eq 6 )	
	 {  Write-host "Script will wait for 1 minute for the user to change the power plan" -Foreground Blue
        Start-Sleep 60
        $ActivePScheme = ReadRegistryValue $RegPath $RegProp
        If ($Global:OSName -eq "XP")
	    {  $StrKeyPath = "HKCU:\Control Panel\PowerCfg\PowerPolicies\$ActivePScheme"
           $StrValueName = "Name"}
	    Else
	    {  $StrKeyPath = "HKLM:\System\CurrentControlSet\Control\Power\User\PowerSchemes\$ActivePScheme"
           $StrValueName = "FriendlyName"}
           $ChangedPowerScheme = ReadRegistryValue $StrKeyPath $StrValueName
           If (!( $ChangedPowerScheme -eq $PowerScheme ))
           {   write-host "User changed the System Power Plan to $ChangedPowerScheme"  -Foreground Blue
               Logger "User changed the System Power Plan to $ChangedPowerScheme" 1                 
           }
       If ($ChangedPowerScheme -eq $PowerScheme )
          {  Write-Host "System Power Plan is not changed" -Foreground Blue }
     }
}


# ##################################################################################################

Function CheckForNewDeviceArrival
{   $Global:logger.CreateNewScenario("Check if any new devices arrived")
    $devicecnt1 = 0
    $devicecnt2 = 0

    $PresentDevice = get-wmiobject -class "Win32_PnPEntity" -namespace "root\cimv2" -computername "."
    $devicecnt1 = $PresentDevice.count
    $devicecnt2 = $Global:InitialDevice.count
  
    For ($tempVar1 = 0 ; $tempVar1 -le $devicecnt1-1 ; $tempVar1++)
    { $Exist = 0
        
        For ($tempvar2 = 0; $tempVar2 -le $devicecnt2-1 ; $tempVar2++) 
        {                
            If ( $Global:InitialDevice[$tempVar2].name -contains $PresentDevice[$tempVar1].name )
            { $Exist = 1 }          
        }
        If ($Exist -eq 0)
        {    If (($PresentDevice[$tempVar1].name -ne "") -And ($PresentDevice[$tempVar1].name -ne $Null) -And ($PresentDevice[$tempVar1].status -ne "") -And (!($PresentDevice[$tempVar1].name -eq "Microsoft Kernel Wave Audio Mixer")) )  
             {   write-host "New device arrival : " $PresentDevice[$tempVar1].name ", Status : " $PresentDevice[$tempVar1].status -Foreground Red                    
                 $LogString = "New device detected : " + $PresentDevice[$tempVar1].name + ", Status : " + $PresentDevice[$tempVar1].status
                 Logger $LogString 3 "D"
                 $Global:logger.AddLog($LogString)
                 $Global:logger.CurrentScenarioFailed() 
                 $Global:FailCount = $Global:FailCount + 1
                 $Global:IterationFail = 1
                 $newdevicearrival = 1
                 If ($global:TestMode -eq "Interactive")
                 {   $verify = $VBInteraction::MsgBox($LogString+ ". Do you want to Stop the script?", 'YesNo,Exclamation', "StatiCriteriaINEXSuspend") 
                         If ($verify -eq "Yes")
                         {   $Global:logger.AddLog("Script stopping as per user request") 
                             Logger "Script stopping as per user request" 8 "D"
                             write-host "Script stopping as per user request" -Foreground Blue 
                             If ( $Global:IterationFail -eq 1)
	                             { $Global:IterationFailCount = $Global:IterationFailCount + 1 }        
			                 LogTestResultSummary
                             Exit}
                 }
             }
         }
               
     }  
     If ($newdevicearrival -ne 1)
     {$Global:logger.CurrentScenarioPassed()}
}

Function OldDeviceChange
{   $Global:logger.CreateNewScenario("Check if any devices are missing/ status changed")
    $PresentDevice = get-wmiobject -class "Win32_PnPEntity" -namespace "root\cimv2" -computername "."
    $devicecnt1 = $PresentDevice.count
    $devicecnt2 = $Global:InitialDevice.count
    
    $filename = "$Global:CurDir\deviceList.html"	
    #$devicecnt = (Get-Content $Filename| Measure-Object).Count	
    
    For ($tempVar2 = 0 ; $tempVar2 -le $devicecnt2-1 ; $tempVar2++)
    { $devExist = 0
      $statusChange = 1
    
        
        For ($tempvar1 = 0; $tempVar1 -le $devicecnt1-1 ; $tempVar1++) 
        {                
            If ( $PresentDevice[$tempVar1].name -contains $Global:InitialDevice[$tempVar2].name )
            {   $devExist = 1 
                If ( $PresentDevice[$tempVar1].status -contains $Global:InitialDevice[$tempVar2].status )
                { $statusChange = 0 
                }
                If ( $statusChange -eq 1)
                {    If (($Global:InitialDevice[$tempVar2].name -ne "") -And ($Global:InitialDevice[$tempVar2].name -ne $Null) -And ($Global:InitialDevice[$tempVar2].status -ne "") -And (!($Global:InitialDevice[$tempVar2].name -eq "Microsoft Kernel Wave Audio Mixer")) )  
                      {  write-host "Device " $Global:InitialDevice[$tempVar2].name " status changed from : " $Global:InitialDevice[$tempVar2].status " to " $PresentDevice[$tempVar1].status -Foreground Red 
                         $LogString = "Device " + $Global:InitialDevice[$tempVar2].name + " status changed from : " + $Global:InitialDevice[$tempVar2].status + " to " + $PresentDevice[$tempVar1].status
                         Logger $LogString 3 "D"     
                         $Global:logger.AddLog($LogString)
                         $Global:logger.CurrentScenarioFailed()      
                         
                         $Global:FailCount = $Global:FailCount + 1
				         $Global:IterationFail = 1
                         $oldDeviceChange = 1
                         If ($global:TestMode -eq "Interactive")
                         {$verify = $VBInteraction::MsgBox($LogString+ ". Do you want to Stop the script?", 'YesNo,Exclamation', "StatiCriteriaINEXSuspend") 
                             If ($verify -eq "Yes")
                             {$Global:logger.AddLog("Script stopping as per user request")
                             Logger "Script stopping as per user request" 8 "D"
                             write-host "Script stopping as per user request" -Foreground Blue 
                             If ( $Global:IterationFail -eq 1)
	                             { $Global:IterationFailCount = $Global:IterationFailCount + 1 } 
                              LogTestResultSummary
                             Exit}
                         }
                      }   
                 } 
             }          
         }
        
   
        If ($devExist -eq 0)
        {    If (($Global:InitialDevice[$tempVar2].name -ne "") -And ($Global:InitialDevice[$tempVar2].name -ne $Null) -And ($Global:InitialDevice[$tempVar2].status -ne "") -And (!($Global:InitialDevice[$tempVar2].name -eq "Microsoft Kernel Wave Audio Mixer")) )  
             {   write-host "Device not detected : " $Global:InitialDevice[$tempVar2].name -Foreground Red                   
                 $LogString = "Device not detected : " + $Global:InitialDevice[$tempVar2].name 
                 
                 Logger $LogString 3 "D"
                 $Global:logger.AddLog($LogString)
                 $Global:logger.CurrentScenarioFailed() 
                 
                 $Global:FailCount = $Global:FailCount + 1
				 $Global:IterationFail = 1
                 $oldDeviceChange = 1
                 If ($global:TestMode -eq "Interactive")
                 {   $verify = $VBInteraction::MsgBox($LogString+ ". Do you want to Stop the script?", 'YesNo,Exclamation', "StatiCriteriaINEXSuspend") 
                         If ($verify -eq "Yes")
                         {  $Global:logger.AddLog("Script stopping as per user request") 
                            Logger "Script stopping as per user request" 8 "D"
                            write-host "Script stopping as per user request" -Foreground Blue  
                            If ( $Global:IterationFail -eq 1)
	                             { $Global:IterationFailCount = $Global:IterationFailCount + 1 }
                            LogTestResultSummary
                            Exit}
                 }
             }
         } 
     } 
     If ($oldDeviceChange -ne 1)
     {$Global:logger.CurrentScenarioPassed()}
 }     


# ################################################################################################## 

# Function to list all the devices
Function logAllDevice  
{ $filename = "$Global:CurDir\DeviceList.html"  	
  $Global:InitialDevice = get-wmiobject -class "Win32_PnPEntity" -namespace "root\cimv2" -computername "." 
  $file = $Global:InitialDevice | select-object Name,status 
  $file | ConvertTo-HTML| out-file $filename
  $devicecnt = $Global:InitialDevice.count
  Logger "" 9
  Logger "Below table includes the list of all devices and their status as listed in the Device Manager:" 1
  Logger "" 5
  Logger "" 13
  Logger "Device" 17
  Logger "Status" 17
  Logger "" 15
  For ($i = 0 ; $i -le $devicecnt ; $i++)
      { Logger $Global:InitialDevice[$i].Name  14
        Logger $Global:InitialDevice[$i].status 14
        Logger "" 15
      }  
  Logger "" 7
  Logger "The Device list with status has been generated.Please refer $filename file" 1
  Write-host "The Device list with status has been generated.Please refer $filename file" -Foreground Blue
  Logger "" 9
}


# ##################################################################################################

# Function to create Log file
Function CreateLogFile
{ $Global:LogFilePath   =  $Global:ScriptPath.Replace(".ps1","_DevLog.htm")
  If (Test-Path $Global:LogFilePath)
     { Remove-Item $Global:LogFilePath }
  $a = New-Item -Type File $Global:LogFilePath   
  $Global:LogReportPath   =  $Global:ScriptPath.Replace(".ps1","_Log.htm")
  If (Test-Path $Global:LogReportPath)
     { Remove-Item $Global:LogReportPath }
  $a = New-Item -Type File $Global:LogReportPath   
    
}


# ##################################################################################################
# Function to Log the string in Log file
Function Logger 
  { Param ($logstr, [int]$Color,$DateStamp)
    $DateTime = Get-Date -uformat "%d-%m-20%y | %H:%M:%S |  "
    $LogStrNull = $logStr -eq $Null
    If ($LogStrNull -eq "True")
		{ 
          Add-Content $Global:LogFilePath "<HTML><BODY bgcolor=#fef8eb text=rgb(64,0,128)>"
		  Add-Content $Global:LogFilePath "<FONT face=Garamond size=3><br>"
        }
	Else
        { If ($DateStamp -eq "D")
             { $logstr = $DateTime + $logstr }
             
          Switch ($Color) 
		         {                    
                   1  { $logstr = "<FONT face=Garamond COLOR = BLUE>$logstr<BR>" }
		           2  { $logstr = "<B><FONT face=Garamond COLOR = GREEN size=3>$logstr</B><BR>" }
			       3  { $logstr = "<B><FONT face=Garamond COLOR = RED>$logstr<BR></B>" }
			       4  { $logstr = "<B><FONT face=Garamond color=rgb(250,130,0) size=3>$logstr<BR></B>" } # Orange
			       5  { $logstr = "<table border=1 cellspacing=1 bordercolor=green>" }
			       6  { $logstr = "<tr><td>$logstr</td></tr>" }
			       7  { $logstr = "</table><br>" }
			       8  { $logstr = "<b><FONT face=Garamond COLOR =#F6358A>$logstr</b><BR>" } # Pink
			       9  { $logstr = "<br>" }
			       10 { $logstr = "<b><FONT face=Garamond COLOR =rgb(0,270,145)>$logstr</b><BR>" }  
			       11 { $logstr = "<b><FONT face=Garamond COLOR =rgb(145,270,0)>$logstr</b><BR>" }  
			       12 { $logstr = "<tr><td><FONT face=Garamond COLOR =RED>$logstr</font></td></tr>" }    
			       13 { $logstr = "<tr BGCOLOR=FFFFCC>" }    
			       14 { $logstr = "<td><FONT face=Garamond COLOR =BLUE>$logstr</font></td>" }  
			       15 { $logstr = "</tr>" }    
			       16 { $logstr = "<td><FONT face=Garamond COLOR =RED>$logstr</font></td>" }    
			       17 { $logstr = "<th><FONT face=Garamond COLOR =BLUE>$logstr</font></th>" }    
			       18 { $logstr = "<tr>" }
			       19 { $logstr = "<tr BGCOLOR=C0C0C0>" } # silver
			       20 { $logstr = "<tr BGCOLOR=FFD700>" } # Gold
			       21 { $logstr = "<tr BGCOLOR=EE82EE>" } # Violet
			       22 { $logstr = "<tr BGCOLOR=F0E68C>" } # Khaki
			       23 { $logstr = "<tr BGCOLOR=00FFFF>" } # Aqua
			       24 { $logstr = "<tr BGCOLOR=FFFF00>" } # Yellow
			       25 { $logstr = "<td><FONT face=Garamond COLOR =GREEN>$logstr</font></td>" }  
			       26 { $logstr = "<td><FONT face=Garamond COLOR =RED>$logstr</font></td>" }                       	                       
	             }
          Add-Content $Global:LogFilePath $logstr
        }
  } 
  
# ##################################################################################################  
  
# Function to get OS Details(Name,Language,ProcessorBit)
Function GetOSDetails
{ 
 $OSDetails = Get-wmiobject win32_OperatingSystem | Select Caption,CountryCode
 $ProcessorDetails = Get-wmiobject win32_Processor | Select AddressWidth
 
 $Global:OSActualName = $OSDetails.Caption
 $Global:OSLanguage = $OSDetails.CountryCode
 $Global:SystemType = $ProcessorDetails.AddressWidth
 
 IF ($Global:OSActualName -match "7" -or $Global:OSActualName -match "8"-or $Global:OSActualName -match "10")
    { $Global:OSName = "Win7" }
 ElseIf ($Global:OSActualName -match "Vis")
    { $Global:OSName = "Vista" } 
 ElseIf ($Global:OSActualName -match "XP")
    { $Global:OSName = "XP" } 
 Else
    { $Global:OSName = "Not XP,Vista & Win7" }      
 
 # For US Country Code is 1 and for JP it is 81
 If ($Global:OSLanguage -eq "1")
    { $Global:OSLanguage = "US" }
 Else
    { $Global:OSLanguage = "JP" } 
   
 $Global:OSDetails =  "OS Details : " + "$Global:OSActualName" +"- "+ "$Global:SystemType" + "Bit" + "("+ "$Global:OSLanguage" +")"
 Logger $Global:OSDetails 8
 }
  
  
# ##################################################################################################

# Function to Read Registry value
Function ReadRegistryValue
{ Param ($RegPath,$RegProp)
  # To check if the registry value exist or not
  If (Test-Path $RegPath)
     {
      If ((Get-Item $RegPath).Property -notcontains $RegProp)
         { $RegValue = "0" }
      Else 
         { $RegValue = Get-ItemProperty -path $RegPath -name $RegProp 
           $RegValue = $RegValue.$RegProp
         }
     }
  Else
     { $RegValue = 0 }
  Return $RegValue
 
}
# ##################################################################################################

# Function to Write Registry value
# Need to pass the value of Property Type (after the hypen) to get the corresponding property type (before the hypen) in registry  
# REG_SZ - String, REG_EXPAND_SZ - ExpandString ,REG_BINARY - Binary,REG_DWORD - DWord,REG_MULTI_SZ - MultiString
Function WriteRegistryValue
{ Param ($RegPath,$RegProp,$RegValue,$RegPropType)  
  # To check if the registry value already exist it overwrites it or else it creates it
  If (!(Test-Path "HKCU:\Software\IbmAutoTest")) {New-Item "HKCU:\Software\IbmAutoTest" -itemType Directory }
  If (!(Test-Path "HKCU:\Software\IbmAutoTest\Scripts")) {New-Item "HKCU:\Software\IbmAutoTest\Scripts" -itemType Directory }
  If (!(Test-Path $RegPath))
    { New-Item $RegPath -itemType Directory | out-null }
  If ((Get-Item $RegPath).Property -notcontains $RegProp)
     { New-ItemProperty $RegPath -Name $RegProp -Value $RegValue -PropertyType $RegPropType}
  Else 
     { Set-ItemProperty -path $RegPath -name $RegProp -value $RegValue }
}

 
# ##################################################################################################

# Function to Delete Registry values
Function DeleteRegistryValue
{ Param ($RegPath,$RegProp)
  # To check if the registry value exist or not
  If (Test-Path $RegPath)
     { If ($RegProp -eq "ALL")
          { remove-item -path $RegPath }
       Else
          {
            If ((Get-Item $RegPath).Property -contains $RegProp)
               { Remove-Itemproperty -Path $RegPath -Name $RegProp }
          }
     } 
}
# ######################################################################################################

# StandBy Function
function Stand_By
{
    $Global:logger.CreateNewScenario("System Suspend-Resume operation")
    $Err = $Error.count
    Logger "System will go to standby mode for $global:resumeTime seconds" 1 "D"
    $a = get-date 
    Write-host "System will go to standby mode for $global:resumeTime seconds" -foreground blue
    [Reflection.Assembly]::LoadFile("$Global:CurDir\ATS Sys Files\bin\ATS.Scripts.Utilities.dll")
    [ATS.Scripts.Utilities.PowerManager]::SuspendSystem($global:resumeTime) #The call to actually suspend the system
    trap [Exception] 
    {   #write-host "
        Write-error $("Trapped: " + $_.Exception.Message)
        write-error $("Trapped: " + $_.Exception.GetType().FullName)
        #"
        #Logger $("Trapped: " + $_.Exception.GetType().FullName) 1
        Continue 
        }
    $b = get-date
    $c = $b - $a

    #If the system resume time is 40 seconds greater than expected, its logged as failure
    If (!($c.totalseconds -ge ($global:resumeTime + 40)))
    {   #If ($Err -lt $Error.count)
        #{   $Global:logger.AddLog("System Suspend-resume operation failed")
        #    $Global:logger.CurrentScenarioFailed()
        #    write-host "System Suspend-resume operation failed" -foreground red
        #    Logger "System Suspend-resume operation failed" 3 "D"
        #    [int]$Global:FailCount = ($Global:FailCount + 1)
        #    $Global:IterationFail = 1
        #}
        #Else
        #{
           $Global:logger.AddLog("System Suspend-resume operation successful")
            $Global:logger.CurrentScenarioPassed()
            write-host "System Suspend-resume operation successful" -foreground green
            Logger "System Suspend-resume operation successful" 2 "D"
        #}
    }
    Else
    {   [int]$Global:FailCount = ($Global:FailCount + 1)
        $Global:IterationFail = 1
        $Global:logger.AddLog("System Suspend-resume operation failed")
        $Global:logger.CurrentScenarioFailed()
        write-host "System Suspend-resume operation failed. System resumed after " $c.totalseconds" seconds" -foreground red
        Logger "System Suspend-resume operation failed.  " 3 "D" 
        }
}

# ########################################################################################################

function Sleepless_Wait
{
    [Reflection.Assembly]::LoadFile("$Global:CurDir\ATS Sys Files\bin\ATS.Scripts.Utilities.dll")
    [ATS.Scripts.Utilities.PowerManager]::SleeplessWait($global:elapseTime) #The call to actually suspend the system
}

# ##################################################################################################
# Function to create multiple log files if the file size crosses 0.5 MB. This is because if the html file size increases, it takes more time to open. 
# Also, Sometimes it will not respond if the system is slow.
Function LogFileSizeRestriction
{ $Filesize = (Get-childitem $Global:LogFilePath).Length
  If($Filesize -gt 500000)
  { $Global:ExtendedOnce = 1
    $NewLogFilePath = $Global:LogFilePath.Replace("_DevLog","_DevLog"+$Global:extend)
    # Loop to check how many log files has already been extended and get the new file name
    While(Test-Path $NewLogFilePath)
    { [int]$Global:extend = ([int]$Global:extend + 1)
      $NewLogFilePath = $Global:LogFilePath.Replace("_DevLog","_DevLog"+$Global:extend)
    }

    # Copy previous log file content to new log file.
    $CopyContent = Get-content $Global:LogFilePath | out-file $NewLogFilePath
    start-sleep 2
    Logger "Log file extended." 2 "D"
    write-host "Log file extended."
    # Clear the content of previous log file
    $ClearOldContent = Clear-Content $Global:LogFilePath
    start-sleep 1
  }
}
# Since if log file size is big then multiples log files get created so this function is to rename the file dev log file
# and lets say 4 files get created such as log1,log2,log3 and log. So this function rename log as log4.
Function ChangeFinalLogFileName
{ 
  # Need to change the name only if multiple file exists
  If ($Global:ExtendedOnce -eq 1)
  { # Copy previous log file content to new log file.
    # Loop to check how many log files has already been extended and get the new file name
    $NewLogFilePath = $Global:LogFilePath.Replace("_DevLog","_DevLog"+$Global:extend)
    While(Test-Path $NewLogFilePath)
    { [int]$Global:extend = ([int]$Global:extend + 1)
      $NewLogFilePath = $Global:LogFilePath.Replace("_DevLog","_DevLog"+$Global:extend)
    }
    
    $CopyContent = Get-content $Global:LogFilePath | out-file $NewLogFilePath
    # removing the log file
    $RemoveFile = Remove-Item $Global:LogFilePath  
  }
}

# ##################################################################################################
# Function to summarize the log report results
Function LogTestResultSummary
{	
	 Logger "===========================================================================================================" 1    

     write-host "Exit Loop...done." ($Global:CurrentLoopCount)
     write-host "Script Run completed with Loop count: " ($Global:CurrentLoopCount)

     Logger "" 9
     Logger "Logs Summary" 4
     Logger "===========================================================================================================" 10
     If ( $Global:IterationFail -eq 0 )
	    { Logger "All the devices and their status are same as at the beginning of the script." 2 }
    
     $LogString =  "   Total number of Iterations performed: "+ ($Global:CurrentLoopCount) 
     Logger $LogString 4
     If ($Global:IterationFailCount -gt 0) 
	    { $LogString  = "   Total number of Iterations Failed: "+ $Global:IterationFailCount
         Logger $LogString 3 }
     Else
	    { $LogString  = "   Total number of Iterations Failed: "+ $Global:IterationFailCount
         Logger $LogString 2 }

     If ( $Global:FailCount -gt 0 ) 
	    { $LogString  = "   Total number of Failures occured: " + $Global:FailCount
        Logger $LogString 3 }
     Else
	    { $LogString  = "   Total number of Failures occured: " + $Global:FailCount
         Logger $LogString 2 } 

     If ( $Global:IterationFailCount -gt 0 ) 
	    { Logger "" 3
	      Logger  "Script Result: FAIL" 3
        }  
     Else
	    { Logger "" 3
	      Logger  "Script Result: PASS" 2
        }  
     write-host   "Generating Log Report. Please wait..."
     $Global:logger.GenerateReport()   
     
     $VBInteraction::MsgBox("Test Completed!", 'OkOnly,information', "StaticCriteriaINEXSuspend") 
     Logger "" 9 
     Logger  "				Test Completed." 4
     Logger "===========================================================================================================" 10
     write-host   "Test completed!"

     ChangeFinalLogFileName
 }

# ########################################################################################################################################
# Function to Set Powershell console on top of other windows

    

 
# function Pause ($Message="press any key to continue")
# {
#    write-host -NoNewLine $Message
#    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
#    Write-Host ""
# }

# ##################################################################################################
#                               MAIN BODY SECTION - Starts Here
# ##################################################################################################

# Function to create Log file

  CreateLogFile

#########################################################################################################
  $signature = @"
	
	[DllImport("user32.dll")]  
	public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);  

	public static IntPtr FindWindow(string windowName){
		return FindWindow(null,windowName);
	}

	[DllImport("user32.dll")]
	public static extern bool SetWindowPos(IntPtr hWnd, 
	IntPtr hWndInsertAfter, int X,int Y, int cx, int cy, uint uFlags);

	[DllImport("user32.dll")]  
	public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow); 

	static readonly IntPtr HWND_TOPMOST = new IntPtr(-1);
	static readonly IntPtr HWND_NOTOPMOST = new IntPtr(-2);

	const UInt32 SWP_NOSIZE = 0x0001;
	const UInt32 SWP_NOMOVE = 0x0002;

	const UInt32 TOPMOST_FLAGS = SWP_NOMOVE | SWP_NOSIZE;

	public static void MakeTopMost (IntPtr fHandle)
	{
		SetWindowPos(fHandle, HWND_TOPMOST, 0, 0, 0, 0, TOPMOST_FLAGS);
	}

	public static void MakeNormal (IntPtr fHandle)
	{
		SetWindowPos(fHandle, HWND_NOTOPMOST, 0, 0, 0, 0, TOPMOST_FLAGS);
	}
"@


$app = Add-Type -MemberDefinition $signature -Name Win32Window -Namespace ScriptFanatic.WinAPI -ReferencedAssemblies System.Windows.Forms -Using System.Windows.Forms -PassThru

function Set-TopMost
{
	param(		
		[Parameter(
			Position=0,ValueFromPipelineByPropertyName=$true
		)][Alias('MainWindowHandle')]$hWnd=0,

		[Parameter()][switch]$Disable

	)

	
	if($hWnd -ne 0)
	{
		if($Disable)
		{
			Write-Verbose "Set process handle :$hWnd to NORMAL state"
			$null = $app::MakeNormal($hWnd)
			return
		}
		
		Write-Verbose "Set process handle :$hWnd to TOPMOST state"
		$null = $app::MakeTopMost($hWnd)
	}
	else
	{
		Write-Verbose "$hWnd is 0"
	}
}



function Get-WindowByTitle($WindowTitle="*")
{
	Write-Verbose "WindowTitle is: $WindowTitle"
	
	if($WindowTitle -eq "*")
	{
		Write-Verbose "WindowTitle is *, print all windows title"
		Get-Process | Where-Object {$_.MainWindowTitle} | Select-Object Id,Name,MainWindowHandle,MainWindowTitle
	}
	else
	{
		Write-Verbose "WindowTitle is $WindowTitle"
		Get-Process | Where-Object {$_.MainWindowTitle -like "*$WindowTitle*"} | Select-Object Id,Name,MainWindowHandle,MainWindowTitle
	}
}

#Examples:

# set powershell console on top of other windows 
#gps powershell | Set-TopMost
################################################################################################################################################

  $Global:extend = 1
  Logger "===========================================================================================================" 4
  Logger  "                                    $Global:LogFileName     " 4
  Logger "" 9   
  Logger  "Detailed script flow logging sequence" 4
  Logger "===========================================================================================================" 4
  Logger "" 9
  GetOSDetails
  If ($Global:OSName -eq "Win7")
  { Write-host "Enabling Wake-up Timer Option. Please Wait.."
  powercfg -setacvalueindex SCHEME_CURRENT SUB_SLEEP bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d 1
  Start-Sleep 3
  powercfg -setdcvalueindex SCHEME_CURRENT SUB_SLEEP bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d 1
  Start-Sleep 3
  Write-host "Wake-Timer Option enabled. Continuing Test..." -foreground blue
  } 
  Logger "" 9
  PMLongrunUI
  start-sleep 2
  #sleep time provided as intermittently the communication between form and variables is slow
 
  If ($Global:ResumeTime -lt 30) 
  {$Global:ResumeTime = 30
  write-host "Resume time changed to " $Global:ResumeTime " seconds"
  $LogString = "Resume time changed to "+ $Global:ResumeTime + " seconds" 
  Logger $LogString 1 }
  
  If ($Global:ElapseTime -lt 30) 
  {$Global:ElapseTime = 30
  write-host "Elapse time changed to " $Global:ElapseTime " seconds"
  $LogString = "Elapse time changed to "+ $Global:ElapseTime + " seconds" 
  Logger $LogString 1 } 
  
  Logger "" 9 
  write-host "This test will perform system Suspend/Resume operation for " $Global:LoopCount " trials with Resume time : " $Global:ResumeTime " seconds and Elapse time : " $Global:ElapseTime " seconds"
  $Logstring = "This test will perform system Suspend/Resume operation for "+$Global:LoopCount+" trials with Resume time : "+$Global:ResumeTime+" seconds and Elapse time : "+$Global:ElapseTime+" seconds"
  Logger $Logstring 8 
 
  GetPowerScheme
  write-host "This script will perform continuous System Standby..." 
  write-host "Generating list of all the Devices and their Status as listed in the Device Manager" -foreground blue
  logAllDevice
  For ($i = 1 ; $i -le $Global:LoopCount ; $i++) 
      {  $Global:logger.CreateNewIteration("System Stand-by with device check")
  	     LogFileSizeRestriction
         Logger "" 9
         Logger "Loop count $i/$Global:LoopCount" 4 "D"
	     Logger "System Standby : $i/$Global:LoopCount" 1 "D"
         write-host "System Standby : " $i / $Global:LoopCount
         $Global:CurrentLoopCount = $i
	     # Calling StandBy Function
         $Global:IterationFail = 0
        
         Stand_By

         MonitorON
         Logger "System resumed from suspend. Continuing Test... " 1 "D"
        
         # calling the Elapsed Time
         # start-sleep $global:elapseTime
         
         Sleepless_Wait
 	    
	     write-host "Comparing the status of the Devices after system Suspend operation" -foreground blue
	     Logger "Comparing the status of the Devices after system Suspend operation" 4 "D"
	     
         Write-host "Old device start changing" -foreground white
	     OldDeviceChange
         write-host "Old device change end" -foreground white
         
	     write-host "Check for new device arrival - started" -foreground gray
         CheckForNewDeviceArrival 
         write-host "check for new devices arrival - ended" -foreground gray
         If ( $Global:IterationFail -eq 0)
	     { Logger "All the devices and their status are same as at the beginning of the script." 2 "D"
           write-host "All the devices and their status are same as at the beginning of the script." -foreground green
         }
        ElseIf ( $Global:IterationFail -eq 1)
	    { $Global:IterationFailCount = $Global:IterationFailCount + 1 } 
     }
     LogTestResultSummary
     

 
# ##################################################################################################
#                                MAIN BODY SECTION - Ends Here
# ##################################################################################################  

