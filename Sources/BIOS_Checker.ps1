#========================================================================
#
# Author 	: systanddeploy (Damien VAN ROBAEYS)
# Date 		: 01/22/2019
# Website	: http://www.systanddeploy.com/
#
#========================================================================

[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | out-null
[System.Reflection.Assembly]::LoadFrom('assembly\MahApps.Metro.dll')      | out-null
[System.Reflection.Assembly]::LoadFrom('assembly\System.Windows.Interactivity.dll') | out-null
[System.Reflection.Assembly]::LoadFrom('assembly\MahApps.Metro.IconPacks.dll')      | out-null
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[System.Windows.Forms.Application]::EnableVisualStyles()
$Script:Current_Path = Split-Path $script:MyInvocation.MyCommand.Path

#########################################################################
#                        Load Main Panel                                #
#########################################################################

$Script:pathPanel= split-path -parent $MyInvocation.MyCommand.Definition

function LoadXaml ($filename){
    $XamlLoader=(New-Object System.Xml.XmlDocument)
    $XamlLoader.Load($filename)
    return $XamlLoader
}


$XamlMainWindow=LoadXaml($pathPanel+"\BIOS_Checker.xaml")
# $XamlMainWindow=LoadXaml($pathPanel+"\BIOS_Checker_Dark.xaml")
$reader = (New-Object System.Xml.XmlNodeReader $XamlMainWindow)
$Form = [Windows.Markup.XamlReader]::Load($reader)



# Controls in the main GUI
$Tab_Control = $Form.FindName("Tab_Control")
$Export_BIOS_Tab = $Form.FindName("Export_BIOS_Tab")
$Compare_BIOS_Tab = $Form.FindName("Compare_BIOS_Tab")
$Flyout_Right = $Form.FindName("Flyout_Right") 
$Open_Creds_Part = $Form.FindName("Open_Creds_Part")
$Flyout_Right = $Form.FindName("Flyout_Right") 
$Open_Creds_Part = $Form.FindName("Open_Creds_Part")
$Tab_Control = $Form.FindName("Tab_Control") 
$Export_BIOS_Tab = $Form.FindName("Export_BIOS_Tab")
$Compare_BIOS_Tab = $Form.FindName("Compare_BIOS_Tab")
$About_Tab = $Form.FindName("About_Tab")
$Manage_BIOS = $Form.FindName("Manage_BIOS")
$Open_Report_Folder = $Form.FindName("Open_Report_Folder")

# Flyout part
$User_Name_TextBox = $Form.FindName("User_Name_TextBox")
$User_Name_PWD = $Form.FindName("User_Name_PWD")

# Controls in the Export BIOS Tab
# $Choose_Manufacturer = $Form.FindName("Choose_Manufacturer") 
$BIOS_HP = $Form.FindName("BIOS_HP")
$BIOS_Dell = $Form.FindName("BIOS_Dell")
$BIOS_Lenovo = $Form.FindName("BIOS_Lenovo")
$Computer_Type = $Form.FindName("Computer_Type")
$Export_Type = $Form.FindName("Export_Type")
$Remote_Comp_Block = $Form.FindName("Remote_Comp_Block")
$One_Comp_Block = $Form.FindName("One_Comp_Block")
$Multiple_Comp_Block = $Form.FindName("Multiple_Comp_Block")
$Computer_Name = $Form.FindName("Computer_Name")
$Computers = $Form.FindName("Computers")
$Export_CSV = $Form.FindName("Export_CSV")
$Export_HTML = $Form.FindName("Export_HTML")
$Browse_Export_Path = $Form.FindName("Browse_Export_Path")
$Export_Path_TXT = $Form.FindName("Export_Path_TXT")
$Load_Computers_List = $Form.FindName("Load_Computers_List")
$Load_Computers_List_Help = $Form.FindName("Load_Computers_List_Help")

# Controls in the Compare BIOS Tab
$Compare_type = $Form.FindName("Compare_type")
$Compare_CSV_Block = $Form.FindName("Compare_CSV_Block")
$Compare_Remote_Block = $Form.FindName("Compare_Remote_Block")
$CSV1_TextBox_Path = $Form.FindName("CSV1_TextBox_Path")
$CSV2_TextBox_Path = $Form.FindName("CSV2_TextBox_Path")
$Load_CSV1 = $Form.FindName("Load_CSV1")
$Load_CSV2 = $Form.FindName("Load_CSV2")
$Browse_Compare_Path = $Form.FindName("Browse_Compare_Path")
$Compare_Path_TXT = $Form.FindName("Compare_Path_TXT")
$Compare_Export_HTML = $Form.FindName("Compare_Export_HTML")
$Compare_Export_CSV = $Form.FindName("Compare_Export_CSV")
$Comparison_Result_Block = $Form.FindName("Comparison_Result_Block")
$Same_Same = $Form.FindName("Same_Same")
$Diff_Values = $Form.FindName("Diff_Values")
$NewInFile1 = $Form.FindName("NewInFile1")
$NewInFile2 = $Form.FindName("NewInFile2")

# Bloc visibility initialization
$Remote_Comp_Block.Visibility = "Collapsed"
$One_Comp_Block.Visibility = "Visible"
$Multiple_Comp_Block.Visibility = "Collapsed"
$Compare_CSV_Block.Visibility = "Visible"
$Compare_Remote_Block.Visibility = "Collapsed"
$Comparison_Result_Block.Visibility = "Visible"
$Open_Report_Folder.Visibility = "Collapsed"

$Compare_Export_CSV.IsSelected = $True
$object = New-Object -comObject Shell.Application 

$BIOS_HP.IsSelected = $True
$Script:Date = get-date -format "dd-MM-yy_HHmm"


# Force culture to en_us for csv operations
[System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo] "en-US"

$Tab_Control.Add_SelectionChanged({
	If($Export_BIOS_Tab.IsSelected -eq $True)
		{
			$Manage_BIOS.Content = "Export BIOS"
			$Manage_BIOS.IsEnabled = $True
		}
	ElseIf($Compare_BIOS_Tab.IsSelected -eq $True)
		{
			$Manage_BIOS.Content = "Compare BIOS"
			$Manage_BIOS.IsEnabled = $True
		}
	ElseIf($About_Tab.IsSelected -eq $True)
		{
			$Manage_BIOS.Content = "Manage BIOS"
			$Manage_BIOS.IsEnabled = $False
		}
})







########################################################################################################################################################################################################	
#*******************************************************************************************************************************************************************************************************
#																						 PROGRESSBAR DESIGN
#*******************************************************************************************************************************************************************************************************
########################################################################################################################################################################################################

$syncProgress = [hashtable]::Synchronized(@{})
$childRunspace = [runspacefactory]::CreateRunspace()
$childRunspace.ApartmentState = "STA"
$childRunspace.ThreadOptions = "ReuseThread"         
$childRunspace.Open()
$childRunspace.SessionStateProxy.SetVariable("syncProgress",$syncProgress)          
$PsChildCmd = [PowerShell]::Create().AddScript({   
    [xml]$xaml = @"
    <Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
		xmlns:i="http://schemas.microsoft.com/expression/2010/interactivity"				
		xmlns:Controls="clr-namespace:MahApps.Metro.Controls;assembly=MahApps.Metro"			
        WindowStyle="None" 
		WindowState="Normal" 
		WindowStartupLocation = "CenterScreen"  
		AllowsTransparency="True" 
		Height="150"
		Width="400"
		BorderBrush="Blue"
		BorderThickness="1"
		>
		
        <Window.Background>
            <SolidColorBrush Opacity="1" Color="white"/>
        </Window.Background> 
		
		
	<Window.Resources>
		<ResourceDictionary>
			<ResourceDictionary.MergedDictionaries>
				<ResourceDictionary Source="pack://application:,,,/MahApps.Metro;component/Styles/Controls.xaml" />
				<ResourceDictionary Source="pack://application:,,,/MahApps.Metro;component/Styles/Fonts.xaml" />
				<ResourceDictionary Source="pack://application:,,,/MahApps.Metro;component/Styles/Colors.xaml" />
				<ResourceDictionary Source="pack://application:,,,/MahApps.Metro;component/Styles/Accents/Cobalt.xaml" />
				<ResourceDictionary Source="pack://application:,,,/MahApps.Metro;component/Styles/Accents/BaseLight.xaml" />
			</ResourceDictionary.MergedDictionaries>
		</ResourceDictionary>
	</Window.Resources>				

		<!--	<Grid Visibility="Visible" HorizontalAlignment="Stretch" VerticalAlignment="Center" Width="350" Height="100">	-->
		<!--	<Grid Width="350" Height="500"> -->
			<Grid>
			
		<!--		<Border BorderBrush="white" BorderThickness="1"> -->

           <StackPanel Orientation="Vertical" Background="white" VerticalAlignment="Center">
		   
				<Label FontWeight="Bold" FontSize="18" Content="Processing..." Margin="0,0,0,0" HorizontalAlignment="Left"></Label>				
				<ProgressBar  Margin="0,10,0,0" IsIndeterminate="True" Height="20" Width="390" HorizontalAlignment="Center"/>				
            </StackPanel>				
				
		<!--		</Border> -->
            </Grid>
			
    </Window>
"@
  
    $reader=(New-Object System.Xml.XmlNodeReader $xaml)
    $syncProgress.Window=[Windows.Markup.XamlReader]::Load( $reader )
    $syncProgress.Label = $syncProgress.window.FindName("ProgressStep")	

    $syncProgress.Window.ShowDialog() #| Out-Null
    $syncProgress.Error = $Error
})




################ Launch Progress Bar  ########################  
Function Launch_modal_progress{    
    $PsChildCmd.Runspace = $childRunspace
    $Script:Childproc = $PsChildCmd.BeginInvoke()
	
}

################ Close Progress Bar  ########################  
Function Close_modal_progress{
    $syncProgress.Window.Dispatcher.Invoke([action]{$syncProgress.Window.close()})
    $PsChildCmd.EndInvoke($Script:Childproc) | Out-Null
}























################################################################################################################################################################
# 																CONTROLS FROM EXPORT PART
################################################################################################################################################################

$Load_Computers_List_Help.Add_Click({
	[MahApps.Metro.Controls.Dialogs.DialogManager]::ShowMessageAsync($Form, "Info", "To export BIOS configurations of multiple computers, browse a TXT file containing all computers names")	
})


$Open_Creds_Part.Add_Click({
	$Flyout_Right.IsOpen = $True
})

$Export_Type.Add_Click({
	If($Export_Type.IsChecked -eq $False)
		{
			$Remote_Comp_Block.Visibility = "Collapsed"
		}
	Else
		{
			$Remote_Comp_Block.Visibility = "Visible"
		}
})




################################################################################################################################################################
# 																CONTROLS FROM COMPARE PART
################################################################################################################################################################

$Computer_Type.Add_Click({
	If($Computer_Type.IsChecked -eq $False)
		{
			$One_Comp_Block.Visibility = "Visible"
			$Multiple_Comp_Block.Visibility = "Collapsed"
		}
	Else
		{
			$One_Comp_Block.Visibility = "Collapsed"
			$Multiple_Comp_Block.Visibility = "Visible"
		}
})

$Compare_type.Add_Click({
	If($Compare_type.IsChecked -eq $False)
		{
			$Compare_CSV_Block.Visibility = "Visible"
			$Compare_Remote_Block.Visibility = "Collapsed"
		}
	Else
		{
			$Compare_CSV_Block.Visibility = "Collapsed"
			$Compare_Remote_Block.Visibility = "Visible"
		}
})


$Browse_Export_Path.Add_Click({
	$Browse_Folder = $object.BrowseForFolder(0, $message, 0, 0) 
	If ($Browse_Folder -ne $null) 
		{ 			
			$Script:Export_folder = $Browse_Folder.self.Path 
			$Export_Path_TXT.Text = $Export_folder
		}
})


$Browse_Compare_Path.Add_Click({
	$Browse_Compare__Folder = $object.BrowseForFolder(0, $message, 0, 0)
	If ($Browse_Compare__Folder -ne $null) 
		{ 			
			$Script:Comparison_folder = $Browse_Compare__Folder.self.Path
			$Compare_Path_TXT.Text = $Comparison_folder
		}
})


$Load_Computers_List.Add_Click({
	$OpenFileDialog1 = New-Object System.Windows.Forms.OpenFileDialog
	$openfiledialog1.Filter = "TXT File (.txt)|*.txt;"
	$openfiledialog1.title = "Select the TXT file to upload"
	$openfiledialog1.ShowHelp = $True
	$OpenFileDialog1.initialDirectory = [Environment]::GetFolderPath("Desktop")
	$OpenFileDialog1.ShowDialog() | Out-Null
	
	If($OpenFileDialog1 -ne $null)
		{
			$Script:Computers_List_File_Path = $OpenFileDialog1.filename
			$Script:Computers_List_File_Name = split-path $openfiledialog1.FileName -leaf -resolve
			$Computers.Text = $Computers_List_File_Name			
		}
	

})

$Load_CSV1.Add_Click({
	$OpenFileDialog1 = New-Object System.Windows.Forms.OpenFileDialog
	$openfiledialog1.Filter = "CSV File (.csv)|*.csv;"
	$openfiledialog1.title = "Select the CSV file to upload"
	$openfiledialog1.ShowHelp = $True
	$OpenFileDialog1.initialDirectory = [Environment]::GetFolderPath("Desktop")
	
	If($OpenFileDialog1 -ne $null)
		{
			$OpenFileDialog1.ShowDialog() | Out-Null
			$Script:CSV1_File_Path = $OpenFileDialog1.filename	
			$Script:CSV1_File_Name = split-path $openfiledialog1.FileName -leaf -resolve	
			$CSV1_TextBox_Path.Text = $CSV1_File_Name
			$Script:file1_content =  import-csv $CSV1_File_Path	#-Delimiter ";"
		}
})

$Load_CSV2.Add_Click({
	$OpenFileDialog1 = New-Object System.Windows.Forms.OpenFileDialog
	$openfiledialog1.Filter = "CSV File (.csv)|*.csv;"
	$openfiledialog1.title = "Select the CSV file to upload"
	$openfiledialog1.ShowHelp = $True
	$OpenFileDialog1.initialDirectory = [Environment]::GetFolderPath("Desktop")
	$OpenFileDialog1.ShowDialog() | Out-Null
	
	If($OpenFileDialog1 -ne $null)
		{
			$Script:CSV2_File_Path = $OpenFileDialog1.filename
			$Script:CSV2_File_Name = split-path $openfiledialog1.FileName -leaf -resolve
			$CSV2_TextBox_Path.Text = $CSV2_File_Name
			$Script:file2_content =  import-csv $CSV2_File_Path #-Delimiter ";"
		}		
})




################################################################################################################################################################
# 																				GET MANUFACTURER BIOS	
################################################################################################################################################################

Function Get_Dell_BIOS_Settings
	{
		BEGIN {}
		PROCESS 
			{
			$Script:Selected_Manufacturer = "Dell"
			If (Get-Module -ListAvailable -Name DellBIOSProvider)
				{} 
			Else 
				{
					Install-Module -Name DellBIOSProvider -Force
				}		 
			get-command -module DellBIOSProvider | out-null
			$Script:Get_BIOS_Settings = get-childitem -path DellSmbios:\ | select-object category | 
			foreach {
			get-childitem -path @("DellSmbios:\" + $_.Category)  | select-object attribute, currentvalue 
			# get-childitem -path @("DellSmbios:\" + $_.Category)  | select attribute, currentvalue, possiblevalues, PSPath 
			}		
				$Script:Get_BIOS_Settings = $Get_BIOS_Settings |  % { New-Object psobject -Property @{
					Setting = $_."attribute"
					Value = $_."currentvalue"
					}}  | select-object Setting, Value 
				$Get_BIOS_Settings
			}
		END{ }			
	}
	
Function Get_HP_BIOS_Settings
	{	
		Try
			{
				$Script:Get_BIOS_Settings = Get-WmiObject -Namespace root/hp/instrumentedBIOS -Class hp_biosEnumeration -ErrorAction SilentlyContinue |  % { New-Object psobject -Property @{				
					Setting = $_."Name"	
					Value = $_."currentvalue"
					}}  | select-object Setting, Value
				$Get_BIOS_Settings
			}
		Catch
			{}
	}	


Function Get_LENOVO_BIOS_Settings
	{
		Try
			{
				$Script:Get_BIOS_Settings = gwmi -class Lenovo_BiosSetting -namespace root\wmi  | select-object currentsetting | Where-Object {$_.CurrentSetting -ne ""} |
				select-object @{label = "Name"; expression = {$_.currentsetting.split(",")[0]}} , 
				@{label = "Active value"; expression = {$_.currentsetting.split(",*;[")[1]}} 

				# ConvertTo-HTML  -body " $Title<br>$BIOS_WMI" -CSSUri $CSS_File | 
				# Out-File -encoding ASCII $HTML_BIOS				
				# $Script:Get_BIOS_Settings = Get-WmiObject -Namespace root/hp/instrumentedBIOS -Class hp_biosEnumeration -ErrorAction SilentlyContinue  | select Name, Value, CurrentValue			
			}
		Catch
			{}
	}		
	

	

################################################################################################################################################################
# 																				EXPORT BIOS PART 	
################################################################################################################################################################


Function Export_Report_Format
	{
		param(
		$Computer_To_Export
		)
		If (($Export_CSV.IsSelected) -eq $True)
			{
				$CSV_Name = "Export_BIOS_$Computer_To_Export.csv"
				$Excel_File_Name = "Export_BIOS_$Computer_To_Export.xlsx"
				$CSV_Full_Path = "$Export_folder\$CSV_Name"
				$XLS_File_Full_Path = "$Export_folder\$Excel_File_Name"
				# $Get_BIOS_Settings | select Setting, Value | export-csv $CSV_Full_Path -NoTypeInformation -UseCulture	
				# $Get_BIOS_Settings | select-object Setting, Value | export-csv $CSV_Full_Path -encoding UTF8 -notype -Delimiter ";"
				$Get_BIOS_Settings | select-object Setting, Value | export-csv $CSV_Full_Path -encoding UTF8 -notype 

				$xl = new-object -comobject excel.application
				$xl.visible = $False
				$xl.DisplayAlerts=$False

				$Workbook = $xl.workbooks.open($CSV_Full_Path)

				$WorkSheet=$WorkBook.activesheet
				$WorkSheet.columns.autofit()

				$table=$Workbook.ActiveSheet.ListObjects.add( 1,$Workbook.ActiveSheet.UsedRange,0,1)
				$WorkSheet.columns.autofit()

				$Workbook.SaveAs($XLS_File_Full_Path,51)
				$Workbook.Saved = $True
				$xl.Quit()
				# invoke-item $Export_folder
			}
		ElseIf(($Export_HTML.IsSelected) -eq $True)
			{
				# $CSS_File = "$Current_Path\Master_Export_Compare.css" 
				$CSS_File = "D:\BIOS_Checker\Master_Export_Compare.css" 				
				$Title = "<br><p><span class=titre_list>BIOS Export on $Computer_To_Export</span><br><span class=subtitle>This document has been updated on $Date</span></p><br>"	
				$HTML_File_Name = "Export_BIOS_$Computer_To_Export.html"
				$HTML_File_Full_Path = "$Export_folder\$HTML_File_Name"	
				If (test-path $HTML_File_Full_Path)
					{
						remove-item $HTML_File_Full_Path -force
					}
				$Get_BIOS_Settings | ConvertTo-Html -CSSUri $CSS_File -body $Title  | Out-File -FilePath $HTML_File_Full_Path	
				invoke-item $HTML_File_Full_Path
			}		
	}
	

	
Function Invoke_Remote_BIOS_Settings
	{
		param(
		$My_Remote_Computer,
		[PSCredential] $credential
		)
		If (($BIOS_HP.IsSelected) -eq $True)
			{
				$Get_BIOS_Settings = Invoke-Command  -credential $credential -ComputerName $My_Remote_Computer -ScriptBlock ${Function:Get_HP_BIOS_Settings} 
			}
		ElseIf (($BIOS_Dell.IsSelected) -eq $True)
			{
				$Get_BIOS_Settings = Invoke-Command  -credential $credential -ComputerName $My_Remote_Computer -ScriptBlock ${Function:Get_Dell_BIOS_Settings} 
			}
		ElseIf (($BIOS_Lenovo.IsSelected) -eq $True)
			{
				$Get_BIOS_Settings = Invoke-Command  -credential $credential -ComputerName $My_Remote_Computer -ScriptBlock ${Function:Get_LENOVO_BIOS_Settings} 												
			}			
	}	


Function Export_BIOS_Part
	{
		$Export_Folder_TextBox = $Export_Path_TXT.Text.ToString()
		If($Export_Folder_TextBox -ne "")
			{
				# Choose the appropriate command for the BIOS Settings
				If (($BIOS_HP.IsSelected) -eq $True)
					{
						Get_HP_BIOS_Settings
					}
				ElseIf (($BIOS_Dell.IsSelected) -eq $True)
					{
						Get_Dell_BIOS_Settings
					}
				ElseIf (($BIOS_Lenovo.IsSelected) -eq $True)
					{
						Get_LENOVO_BIOS_Settings
					}	

				If(($Export_Type.IsChecked) -eq $False) # Meaning if you want a local BIOS export	
					{
						Try
							{
								$CompName = $env:computername
								Export_Report_Format -Computer_To_Export $CompName
							}
						Catch
							{
								[MahApps.Metro.Controls.Dialogs.DialogManager]::ShowMessageAsync($Form, "Oops :-(", "Issue during the report !!!")	
							}
					}
				Else # Meaning you want to export from a remote computer
					{
						$Remote_UserName = $User_Name_TextBox.Text.ToString()
						$Remote_UserPassword = $User_Name_PWD.Password.ToString()

						If(($Remote_UserName -eq "") -or ($Remote_UserPassword -eq ""))
							{
								[MahApps.Metro.Controls.Dialogs.DialogManager]::ShowMessageAsync($Form, "Oops :-(", "User name or password missing !!!")
							}
						Else	
							{
								$Script:Creds = New-Object PSCredential($Remote_UserName, (ConvertTo-SecureString $Remote_UserPassword -AsPlainText -Force))
								If(($Computer_Type.IsChecked) -eq $True) # Meaning you want to export from a list of computer
									{
										$Get_Computers_List_Content = Get-Content $Computers_List_File_Path
										ForEach($Computer_Line in $Get_Computers_List_Content)
											{
												$SourceSession = New-PSSession -ComputerName $Computer_Line -credential $Creds		
												
												# Invoke_Remote_BIOS_Settings -My_Remote_Computer $Computer_Line -credential $Creds
				
												If (($BIOS_HP.IsSelected) -eq $True)
													{
														$Get_BIOS_Settings = Invoke-Command  -credential $Creds -ComputerName $Computer_Line -ScriptBlock ${Function:Get_HP_BIOS_Settings} 
													}
												ElseIf (($BIOS_Dell.IsSelected) -eq $True)
													{
														$Get_BIOS_Settings = Invoke-Command  -credential $Creds -ComputerName $Computer_Line -ScriptBlock ${Function:Get_Dell_BIOS_Settings} 
													}
												ElseIf (($BIOS_Lenovo.IsSelected) -eq $True)
													{
														$Get_BIOS_Settings = Invoke-Command  -credential $Creds -ComputerName $Computer_Line -ScriptBlock ${Function:Get_LENOVO_BIOS_Settings} 												
													}
											
												Export_Report_Format -Computer_To_Export $Computer_Line
												remove-pssession ($SourceSession.id)
											}
									}
								Else # Meaning if you want to export from one computer
									{
										$Remote_Computer = $Computer_Name.Text.ToString()
										$SourceSession = New-PSSession -ComputerName $Remote_Computer -credential $Creds

										If (($BIOS_HP.IsSelected) -eq $True)
											{
												$Get_BIOS_Settings = Invoke-Command  -credential $Creds -ComputerName $Remote_Computer -ScriptBlock ${Function:Get_HP_BIOS_Settings} 									
											}
										ElseIf (($BIOS_Dell.IsSelected) -eq $True)
											{
												$Get_BIOS_Settings = Invoke-Command  -credential $Creds -ComputerName $Remote_Computer -ScriptBlock ${Function:Get_Dell_BIOS_Settings} 									
											}
										ElseIf (($BIOS_Lenovo.IsSelected) -eq $True)
											{
												$Get_BIOS_Settings = Invoke-Command  -credential $Creds -ComputerName $Remote_Computer -ScriptBlock ${Function:Get_LENOVO_BIOS_Settings} 																					
											}
										
										Export_Report_Format -Computer_To_Export $Remote_Computer
										remove-pssession ($SourceSession.id)
									}
							}
					}
			}
		Else
			{
				[MahApps.Metro.Controls.Dialogs.DialogManager]::ShowMessageAsync($Form, "Oops :-(", "Please select a path to export the report !!!")				
			}	
	}





################################################################################################################################################################
# 																				COMPARE BIOS PART 	
################################################################################################################################################################

Function CompareBIOSToXLS
	{
		$Comparison_Temp_Folder = "$Comparison_folder\Temp_Comparison_Folder"
		new-item $Comparison_Temp_Folder -type directory -force
	
		$Comparison_Excel_File = "$Comparison_folder\BIOS_Settings_Comparison.xlsx"
		$Temp_CSV_Equal = "$Comparison_Temp_Folder\CSV_Equal_Value.csv"
		$Temp_CSV_MissingInFile1 = "$Comparison_Temp_Folder\CSV_MissingInFile1_Value.csv"
		$Temp_CSV_MissingInFile2 = "$Comparison_Temp_Folder\CSV_MissingInFile2_Value.csv"
		$Temp_CSV_DiffValues = "$Comparison_Temp_Folder\CSV_DiffValues_Value.csv"
		
		$nbnewfile1 = 0
		$nbnewfile2 = 0	
		$nbdiffver = 0
		$nbsame = 0	
	
		$equal = compare-object $file1_content $file2_content -property setting, value -includeequal  | Where-Object {$_.SideIndicator -eq "=="} | 
		   Group-Object -Property setting | % { New-Object psobject -Property @{
				setting=$_.group[0].setting
				value=$_.group[0].value	
			}}  | Select-object setting, value | export-csv -encoding UTF8 -notype $Temp_CSV_Equal #-Delimiter ";"
	
		$nbnewfile1	= (compare-object $file1_content $file2_content -property setting  | Where-Object {$_.SideIndicator -eq "<="} |measure-object).count 
		$nbnewfile2	= (compare-object $file1_content $file2_content -property setting  | Where-Object {$_.SideIndicator -eq "=>"} |measure-object).count 		
		$nbsame = (compare-object $file1_content $file2_content -property setting -includeequal  | Where-Object {$_.SideIndicator -eq "=="}|measure-object).count 		

		### NEW SETTING IN FILE 1
		$found = $false
		$New_Settings_In_File1 = Foreach ($line1 in $file1_content)
			{
				$found = $false
				ForEach ($line2 in $file2_content)
					{
						IF ($line1.setting -eq $line2.setting)
							{
								$found = $true
								break
							}
					}

				IF (-not $found) 
					{
						New-Object -TypeName PSObject -Property @{
							setting = $line1.setting
							Value = $line1.value
							}
						$Script:nbnewfile1 = $nbnewfile1 + 1
					}
			}	

		### NEW SETTING IN FILE 2
		$found = $false
		$New_Settings_In_File2 = Foreach ($line2 in $file2_content)
			{
				$found = $false
				ForEach ($line1 in $file1_content)
					{
						IF ($line1.setting -eq $line2.setting)
							{
								$found = $true
								break
							}
					}

				IF (-not $found) 
					{
						New-Object -TypeName PSObject -Property @{
							Setting = $line2.setting
							Value = $line2.Value
							}
						$Script:nbnewfile2 = $nbnewfile2 + 1
					}
			}
			

		### SAME SETTING BUT DIFFERENT VALUE
		$Get_Same_Settings_Diff_Values = ForEach ($line1 in $file1_content)
		{
			ForEach ($line2 in $file2_content)
				{
					IF ($line1.setting -eq $line2.setting)
						{
							IF ($line1.value -ne $line2.value)
								{		
									New-Object -TypeName PSObject -Property @{
										Setting = $line1.setting
										Value_F1 = $line1.value
										Value_F2 = $line2.value 
										}  	
									$nbdiffver = $nbdiffver + 1	
								}
								Break
						}
				}
		}	
		$Same_Same.Content = $nbsame
		$Diff_Values.Content = $Get_Same_Settings_Diff_Values.count
		$NewInFile1.Content = $nbnewfile1
		$NewInFile2.Content = $nbnewfile2

		$Get_Same_Settings_Diff_Values | select-object Setting, Value_F1, Value_F2 | export-csv -encoding UTF8 -notype  $Temp_CSV_DiffValues #-Delimiter ";"
		$New_Settings_In_File1 | select-object Setting, Value | export-csv -encoding UTF8 -notype  $Temp_CSV_MissingInFile2 #-Delimiter ";"
		$New_Settings_In_File2 | select-object Setting, Value | export-csv -encoding UTF8 -notype  $Temp_CSV_MissingInFile1 #-Delimiter ";"
		

		$xl = new-object -comobject excel.application
		$xl.visible = $false
		$xl.DisplayAlerts=$False

		$Workbook1 = $xl.workbooks.open($Temp_CSV_Equal)
		$Workbook2 = $xl.workbooks.open($Temp_CSV_MissingInFile1)
		$Workbook3 = $xl.workbooks.open($Temp_CSV_MissingInFile2) 
		$Workbook4 = $xl.workbooks.open($Temp_CSV_DiffValues) 

		$WorkBook0 = $xl.WorkBooks.add()

		$sh1_wborkbook0 = $WorkBook0.sheets.item(1) # first sheet in destination workbook
		$sheetToCopy1 = $Workbook1.sheets.item(1) # source sheet to copy
		$sheetToCopy1.copy($sh1_wborkbook0) # copy source sheet to destination workbook

		$sh2_wborkbook0 = $WorkBook0.sheets.item(2) # first sheet in destination workbook
		$sheetToCopy2 = $Workbook2.sheets.item(1) # source sheet to copy
		$sheetToCopy2.copy($sh2_wborkbook0) # copy source sheet to destination workbook

		$sh3_wborkbook0 = $WorkBook0.sheets.item(3) # first sheet in destination workbook
		$sheetToCopy3 = $Workbook3.sheets.item(1) # source sheet to copy
		$sheetToCopy3.copy($sh3_wborkbook0) # copy source sheet to destination workbook
		
		$sh4_wborkbook0 = $WorkBook0.sheets.item(4) # first sheet in destination workbook
		$sheetToCopy4 = $Workbook4.sheets.item(1) # source sheet to copy
		$sheetToCopy4.copy($sh4_wborkbook0) # copy source sheet to destination workbook		
		
		$equalboth = $WorkBook0.Worksheets.item(1)
		$missingin1 = $WorkBook0.Worksheets.item(2)
		$missingin2 = $WorkBook0.Worksheets.item(3)
		$diffvers = $WorkBook0.Worksheets.item(4)
		
		$equalboth.name = 'Same settings and values'
		$missingin1.name = 'New settings in file 2'
		$missingin2.name = 'New settings in file 1'
		$diffvers.name = 'Different values'
		
		$equalboth.columns.autofit()
		$missingin1.columns.autofit()
		$missingin2.columns.autofit()
		$diffvers.columns.autofit()
		
		$Table_Equal = $equalboth.ListObjects.add( 1,$equalboth.UsedRange,0,1)
		$equalboth.ListObjects.Item($Table_Equal.Name).TableStyle="TableStyleMedium6"

		$Table_Miss1 = $missingin1.ListObjects.add( 1,$missingin1.UsedRange,0,1)
		$missingin1.ListObjects.Item($Table_Miss1.Name).TableStyle="TableStyleMedium3"

		$Table_Miss1 = $missingin2.ListObjects.add( 1,$missingin2.UsedRange,0,1)
		$missingin2.ListObjects.Item($Table_Miss1.Name).TableStyle="TableStyleMedium5"

		$Table_Miss1 = $diffvers.ListObjects.add( 1,$diffvers.UsedRange,0,1)
		$diffvers.ListObjects.Item($Table_Miss1.Name).TableStyle="TableStyleMedium8"
		
		$WorkBook0.SaveAs($Comparison_Excel_File,51)
		$WorkBook0.Saved = $True
		$xl.Quit()		
	
	}		
	
	
Function CompareBIOSToHTML
	{
		$Comparison_Temp_Folder = "$Comparison_folder\Temp_Comparison_Folder"
		new-item $Comparison_Temp_Folder -type directory -force
	
		$Comparison_HTML_File = "$Comparison_folder\BIOS_Settings_Comparison.html"
		
		$nbnewfile1 = 0
		$nbnewfile2 = 0		
		$NB_Diff_Values = 0
		$NB_Same_Settings_Values = 0
	
		### SAME DRIVERS AND SAME VERSION
		$Get_Same_Settings_Values = compare-object $file1_content $file2_content -includeequal -property setting, value | Where-Object {$_.SideIndicator -eq "=="} | 
		  Group-Object -Property setting | % { New-Object psobject -Property @{
			setting=$_.group[0].setting
			value=$_.group[0].value
			}}  | ConvertTo-HTML -Fragment
			
		$NB_Same_Settings_Values = (compare-object $file1_content $file2_content -property setting, value -includeequal  | Where-Object {$_.SideIndicator -eq "=="}|measure-object).count 	
		$nbnewfile1	= (compare-object $file1_content $file2_content -property setting  | Where-Object {$_.SideIndicator -eq "<="} |measure-object).count 
		$nbnewfile2	= (compare-object $file1_content $file2_content -property setting  | Where-Object {$_.SideIndicator -eq "=>"} |measure-object).count 		

		### NEW SETTING IN FILE 1
		$found = $false
		$New_Settings_In_File1 = Foreach ($line1 in $file1_content)
			{
				$found = $false
				ForEach ($line2 in $file2_content)
					{
						IF ($line1.setting -eq $line2.setting)
							{
								$found = $true
								break
							}
					}

				IF (-not $found) 
					{
						New-Object -TypeName PSObject -Property @{
							setting = $line1.setting
							Value = $line1.value
							}
					}
			}	

		### NEW SETTING IN FILE 2
		$found = $false
		$New_Settings_In_File2 = Foreach ($line2 in $file2_content)
			{
				$found = $false
				ForEach ($line1 in $file1_content)
					{
						IF ($line1.setting -eq $line2.setting)
							{
								$found = $true
								break
							}
					}

				IF (-not $found) 
					{
						New-Object -TypeName PSObject -Property @{
							Setting = $line2.setting
							Value = $line2.Value
							}
					}
			}									
			

		### SAME SETTING BUT DIFFERENT VALUE
		$Get_Same_Settings_Diff_Values = ForEach ($line1 in $file1_content)
		{
			ForEach ($line2 in $file2_content)
				{
					IF ($line1.Setting -eq $line2.Setting)
						{
							IF ($line1.Value -ne $line2.Value)
								{
									New-Object -TypeName PSObject -Property @{
										Setting = $line1.Setting
										Value_CSV1 = $line1.Value
										Value_CSV2 = $line2.Value 
										}  	
									$NB_Diff_Values = $NB_Diff_Values + 1
								}
								Break
						}
				}
		}	
				
		$Same_Same.Content = $NB_Same_Settings_Values
		$Diff_Values.Content = $NB_Diff_Values
		$NewInFile1.Content = $nbnewfile1
		$NewInFile2.Content = $nbnewfile2	

		$Title_Same_Settings_Values = "<p class=equal_list>Same setting and same value</p>"
		$Title_New_Settings_In_File1 = "<p class=New_object>New setting in CSV1</p"
		$Title_New_Settings_In_File2 = "<p class=New_object>New setting in CSV2</p>"
		$Result_version = "<p class=notequal_list>Same settings but differents values</p>"
		
		$CSS_File = "$Current_Path\Master_Export_Compare.css"
		$HTML_Equal_Part = $Title_Same_Settings_Values + $Get_Same_Settings_Values
		$HTML_Diff_Values = $Get_Same_Settings_Diff_Values | select-object Setting, Value_CSV1, Value_CSV2 | convertto-html -CSSUri $CSS_File
		$HTML_New_Settings_In_File1 = $New_Settings_In_File1 | select-object  Setting, Value | convertto-html -CSSUri $CSS_File
		$HTML_New_Settings_In_File2 = $New_Settings_In_File2 | select-object  Setting, Value | convertto-html -CSSUri $CSS_File

		$Title = "<br><p><span class=titre_list>BIOS Comparison between CSV1 and CSV2</span><br>
		<span class=subtitle>This document has been updated on $Date</span></p><br><br></span>				
		<p><span class=CSV_Path_Title>CSV files</span><br>
		<p><span class=CSV_Path>CSV1 = $CSV1_File_Name</span><br>
		<span class=CSV_Path>CSV2 = $CSV2_File_Name</span></p>
		<br>
		<p><span class=CSV_Files_Name>Quick comparison resume</span><br>		
		<table>	
		<tr>
		<td>Same settings and values</td>
		<td>$NB_Same_Settings_Values</td>
		</tr>
		
		<tr>
		<td>Same settings but differents values</td>
		<td>$NB_Diff_Values</td>
		</tr>
		
		<tr>
		<td>New settings in CSV 1</td>
		<td>$nbnewfile1</td>
		</tr>	
		
		<tr>
		<td>New settings in CSV 2</td>
		<td>$nbnewfile2</td>
		</tr>			
		</table>
		<br>
		"

		
		$html_final = convertto-html -body "$Title 
		<div id=left>$HTML_Equal_Part</div>
		<div id=middle> $Title_New_Settings_In_File1 $HTML_New_Settings_In_File1 <br> $Title_New_Settings_In_File2 $HTML_New_Settings_In_File2</div>
		<div id=right> $Result_version $HTML_Diff_Values </div>
			
		" -CSSUri $CSS_File

		$html_final | out-file -encoding ASCII $Comparison_HTML_File
		invoke-item $Comparison_HTML_File
		# invoke-expression $Comparison_HTML_File
	}	


$Manage_BIOS.Add_Click({
	If($Export_BIOS_Tab.IsSelected -eq $True)
		{
			$Form.ShowInTaskbar = $false
			$Form.WindowState = [System.Windows.Forms.FormWindowState]::Minimized	
			Launch_modal_progress
			Export_BIOS_Part
			Close_modal_progress
			$Open_Report_Folder.Visibility = "Visible"			
			$Form.ShowInTaskbar = $true
			$Form.WindowState = [System.Windows.Forms.FormWindowState]::Normal		
		}
	ElseIf($Compare_BIOS_Tab.IsSelected -eq $True)
		{
			$Form.ShowInTaskbar = $false
			$Form.WindowState = [System.Windows.Forms.FormWindowState]::Minimized	
			Launch_modal_progress
			If($Compare_Export_HTML.IsSelected -eq $True)
				{
					CompareBIOSToHTML
				}
			Else
				{
					CompareBIOSToXLS
				}
			$Comparison_Result_Block.Visibility = "Visible"
			Close_modal_progress
			$Open_Report_Folder.Visibility = "Visible"			
			$Form.ShowInTaskbar = $true
			$Form.WindowState = [System.Windows.Forms.FormWindowState]::Normal		
		}
})	

$Open_Report_Folder.Add_Click({
	If($Export_BIOS_Tab.IsSelected -eq $True)
		{
			invoke-item $Export_folder
		}
	ElseIf($Compare_BIOS_Tab.IsSelected -eq $True)
		{
			invoke-item $Comparison_folder		
		}
})	
		


$Form.ShowDialog() | Out-Null
