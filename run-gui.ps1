Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

$script:scriptDir = if ($PSScriptRoot) { (Resolve-Path -LiteralPath $PSScriptRoot).Path } else { (Get-Location).Path }
$script:runScript = Join-Path -Path $script:scriptDir -ChildPath "run.ps1"
$script:selectedPdfs = New-Object System.Collections.Generic.List[string]

function Get-PdfFilesFromItems {
    param([string[]]$Items)

    $results = New-Object System.Collections.Generic.List[string]
    foreach ($item in ($Items | Where-Object { $_ })) {
        if (-not (Test-Path -LiteralPath $item)) { continue }

        if (Test-Path -LiteralPath $item -PathType Container) {
            $pdfs = Get-ChildItem -LiteralPath $item -Recurse -File -Filter "*.pdf" -ErrorAction SilentlyContinue |
                ForEach-Object { $_.FullName }
            foreach ($pdf in $pdfs) { $results.Add($pdf) }
        } elseif ($item.ToLowerInvariant().EndsWith(".pdf")) {
            $results.Add((Resolve-Path -LiteralPath $item).Path)
        }
    }

    return $results
}

function Set-SelectedPdfs {
    param(
        [object[]]$Paths,
        [System.Windows.Controls.TextBox]$FilesBox,
        [System.Windows.Controls.TextBlock]$DropLabel
    )

    $script:selectedPdfs.Clear()
    $unique = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($path in ($Paths | Where-Object { $_ })) {
        $pathText = [string]$path
        if ($pathText -and $unique.Add($pathText)) {
            $script:selectedPdfs.Add($pathText)
        }
    }

    $FilesBox.Text = ($script:selectedPdfs -join [Environment]::NewLine)
    if ($script:selectedPdfs.Count -gt 0) {
        $DropLabel.Text = ("{0} files selected" -f $script:selectedPdfs.Count)
    } else {
        $DropLabel.Text = "Drop PDF files or folders here"
    }
}

function Write-LogLine {
    param(
        [System.Windows.Controls.TextBox]$LogBox,
        [string]$Message
    )

    $LogBox.AppendText($Message + [Environment]::NewLine)
    $LogBox.ScrollToEnd()
}

function ConvertTo-QuotedArg {
    param([string]$Value)
    if ($null -eq $Value) { return '""' }
    $escaped = $Value.Replace('"', '\"')
    return ('"{0}"' -f $escaped)
}

function Update-Ui {
    param([System.Windows.Window]$Window)
    $Window.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
}

$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="PDF OCR" Height="650" Width="760" MinHeight="620" MinWidth="720"
        WindowStartupLocation="CenterScreen">
    <Grid Margin="12">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="110"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TextBlock Grid.Row="0" Text="Input PDFs" FontWeight="Bold" Margin="0,0,0,6"/>

        <TextBox x:Name="txtFiles" Grid.Row="1" IsReadOnly="True" AcceptsReturn="True"
                 VerticalScrollBarVisibility="Auto" TextWrapping="NoWrap"/>

        <StackPanel Grid.Row="2" Orientation="Horizontal" Margin="0,8,0,0">
            <Button x:Name="btnPickFiles" Content="Select Files..." Width="110" Height="28"/>
            <Button x:Name="btnPickFolder" Content="Select Folder..." Width="115" Height="28" Margin="8,0,0,0"/>
            <Button x:Name="btnClearFiles" Content="Clear" Width="70" Height="28" Margin="8,0,0,0"/>
        </StackPanel>

        <Border x:Name="dropZone" Grid.Row="3" Margin="0,10,0,0" BorderBrush="#6AA2D8" BorderThickness="1"
                Background="#F2F8FF" CornerRadius="4" Padding="10" AllowDrop="True">
            <TextBlock x:Name="lblDrop" Text="Drop PDF files or folders here"
                       HorizontalAlignment="Center" Foreground="#4A6A8A"/>
        </Border>

        <Grid Grid.Row="4" Margin="0,12,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <CheckBox x:Name="chkSameDir" Grid.Column="0" Content="Save next to input file" IsChecked="True" VerticalAlignment="Center"/>
            <TextBox x:Name="txtOutputDir" Grid.Column="1" Margin="10,0,8,0" IsEnabled="False"/>
            <Button x:Name="btnOutputDir" Grid.Column="2" Content="Browse..." Width="90" IsEnabled="False"/>
        </Grid>

        <Grid Grid.Row="5" Margin="0,10,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="130"/>
                <ColumnDefinition Width="20"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="80"/>
                <ColumnDefinition Width="20"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <TextBlock Grid.Column="0" Text="Engine:" VerticalAlignment="Center"/>
            <ComboBox x:Name="cmbEngine" Grid.Column="1" Margin="8,0,0,0" SelectedIndex="0">
                <ComboBoxItem Content="yomitoku"/>
                <ComboBoxItem Content="ndlocr"/>
            </ComboBox>
            <TextBlock Grid.Column="3" Text="DPI:" VerticalAlignment="Center"/>
            <TextBox x:Name="txtDpi" Grid.Column="4" Margin="8,0,0,0" Text="200"/>
            <CheckBox x:Name="chkLite" Grid.Column="6" Content="Lite mode (yomitoku only)" VerticalAlignment="Center"/>
        </Grid>

        <GroupBox Grid.Row="6" Header="Log" Margin="0,12,0,0">
            <TextBox x:Name="txtLog" IsReadOnly="True" AcceptsReturn="True"
                     VerticalScrollBarVisibility="Auto" TextWrapping="NoWrap"/>
        </GroupBox>

        <StackPanel Grid.Row="7" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,12,0,0">
            <Button x:Name="btnRun" Content="Run" Width="90" Height="30"/>
            <Button x:Name="btnClose" Content="Close" Width="90" Height="30" Margin="8,0,0,0"/>
        </StackPanel>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$txtFiles = $window.FindName("txtFiles")
$btnPickFiles = $window.FindName("btnPickFiles")
$btnPickFolder = $window.FindName("btnPickFolder")
$btnClearFiles = $window.FindName("btnClearFiles")
$dropZone = $window.FindName("dropZone")
$lblDrop = $window.FindName("lblDrop")
$chkSameDir = $window.FindName("chkSameDir")
$txtOutputDir = $window.FindName("txtOutputDir")
$btnOutputDir = $window.FindName("btnOutputDir")
$cmbEngine = $window.FindName("cmbEngine")
$txtDpi = $window.FindName("txtDpi")
$chkLite = $window.FindName("chkLite")
$txtLog = $window.FindName("txtLog")
$btnRun = $window.FindName("btnRun")
$btnClose = $window.FindName("btnClose")

$chkSameDir.Add_Checked({
    $txtOutputDir.IsEnabled = $false
    $btnOutputDir.IsEnabled = $false
})
$chkSameDir.Add_Unchecked({
    $txtOutputDir.IsEnabled = $true
    $btnOutputDir.IsEnabled = $true
})

$btnPickFiles.Add_Click({
    $dialog = New-Object Microsoft.Win32.OpenFileDialog
    $dialog.Filter = "PDF files (*.pdf)|*.pdf"
    $dialog.Multiselect = $true
    if ($dialog.ShowDialog() -eq $true) {
        Set-SelectedPdfs -Paths (Get-PdfFilesFromItems -Items $dialog.FileNames) -FilesBox $txtFiles -DropLabel $lblDrop
    }
})

$btnPickFolder.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $result = $dialog.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK -and $dialog.SelectedPath) {
        Set-SelectedPdfs -Paths (Get-PdfFilesFromItems -Items @($dialog.SelectedPath)) -FilesBox $txtFiles -DropLabel $lblDrop
    }
})

$btnClearFiles.Add_Click({
    Set-SelectedPdfs -Paths @() -FilesBox $txtFiles -DropLabel $lblDrop
})

$dropZone.Add_PreviewDragOver({
    if ($_.Data.GetDataPresent([System.Windows.DataFormats]::FileDrop)) {
        $_.Effects = [System.Windows.DragDropEffects]::Copy
    } else {
        $_.Effects = [System.Windows.DragDropEffects]::None
    }
    $_.Handled = $true
})

$dropZone.Add_Drop({
    if ($_.Data.GetDataPresent([System.Windows.DataFormats]::FileDrop)) {
        $items = [string[]]$_.Data.GetData([System.Windows.DataFormats]::FileDrop)
        Set-SelectedPdfs -Paths (Get-PdfFilesFromItems -Items $items) -FilesBox $txtFiles -DropLabel $lblDrop
    }
    $_.Handled = $true
})

$btnOutputDir.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($txtOutputDir.Text -and (Test-Path -LiteralPath $txtOutputDir.Text -PathType Container)) {
        $dialog.SelectedPath = $txtOutputDir.Text
    }
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtOutputDir.Text = $dialog.SelectedPath
    }
})

$btnRun.Add_Click({
    if (-not (Test-Path -LiteralPath $script:runScript)) {
        [System.Windows.MessageBox]::Show(("Missing file: {0}" -f $script:runScript), "PDF OCR")
        return
    }

    if ($script:selectedPdfs.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Please select at least one PDF file.", "PDF OCR")
        return
    }

    $dpi = 0
    if (-not [int]::TryParse($txtDpi.Text, [ref]$dpi) -or $dpi -lt 100 -or $dpi -gt 400) {
        [System.Windows.MessageBox]::Show("DPI must be an integer between 100 and 400.", "PDF OCR")
        return
    }

    $sameDir = [bool]$chkSameDir.IsChecked
    $outputDir = $txtOutputDir.Text.Trim()
    if (-not $sameDir) {
        if (-not $outputDir) {
            [System.Windows.MessageBox]::Show("Please choose an output directory.", "PDF OCR")
            return
        }
        if (-not (Test-Path -LiteralPath $outputDir -PathType Container)) {
            [System.Windows.MessageBox]::Show("Output directory does not exist.", "PDF OCR")
            return
        }
    }

    $engine = $cmbEngine.Text
    $useLite = ([bool]$chkLite.IsChecked) -and ($engine -eq "yomitoku")

    $btnRun.IsEnabled = $false
    $txtLog.Clear()
    Write-LogLine -LogBox $txtLog -Message "Starting batch..."

    $success = 0
    $fail = 0

    foreach ($inputFile in $script:selectedPdfs) {
        $resolvedInput = (Resolve-Path -LiteralPath $inputFile).Path
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($resolvedInput)
        $targetOutput = if ($sameDir) {
            Join-Path -Path (Split-Path -Path $resolvedInput -Parent) -ChildPath ($baseName + ".md")
        } else {
            Join-Path -Path $outputDir -ChildPath ($baseName + ".md")
        }

        Write-LogLine -LogBox $txtLog -Message ("Processing: {0}" -f [System.IO.Path]::GetFileName($resolvedInput))
        Update-Ui -Window $window

        $invokeArgs = @(
            "-NoProfile",
            "-ExecutionPolicy", "Bypass",
            "-File", $script:runScript,
            "-InputPdf", $resolvedInput,
            "-Output", $targetOutput,
            "-Dpi", [string]$dpi,
            "-Engine", $engine
        )
        if ($useLite) { $invokeArgs += "-Lite" }
        $argLine = ($invokeArgs | ForEach-Object { ConvertTo-QuotedArg -Value $_ }) -join " "

        $stdoutFile = [System.IO.Path]::GetTempFileName()
        $stderrFile = [System.IO.Path]::GetTempFileName()

        try {
            $proc = Start-Process -FilePath "powershell.exe" -ArgumentList $argLine `
                -RedirectStandardOutput $stdoutFile -RedirectStandardError $stderrFile `
                -Wait -PassThru -NoNewWindow

            $stdoutLines = if (Test-Path -LiteralPath $stdoutFile) { Get-Content -LiteralPath $stdoutFile } else { @() }
            $stderrLines = if (Test-Path -LiteralPath $stderrFile) { Get-Content -LiteralPath $stderrFile } else { @() }

            foreach ($line in $stdoutLines) {
                if ($line) { Write-LogLine -LogBox $txtLog -Message ("  " + $line) }
            }
            foreach ($line in $stderrLines) {
                if ($line) { Write-LogLine -LogBox $txtLog -Message ("  " + $line) }
            }

            if ($proc.ExitCode -eq 0) {
                Write-LogLine -LogBox $txtLog -Message ("  Done: {0}" -f $targetOutput)
                $success++
            } else {
                Write-LogLine -LogBox $txtLog -Message ("  Failed (exit code: {0})" -f $proc.ExitCode)
                $fail++
            }
        } catch {
            Write-LogLine -LogBox $txtLog -Message ("  Failed: {0}" -f $_.Exception.Message)
            $fail++
        } finally {
            if (Test-Path -LiteralPath $stdoutFile) { Remove-Item -LiteralPath $stdoutFile -Force -ErrorAction SilentlyContinue }
            if (Test-Path -LiteralPath $stderrFile) { Remove-Item -LiteralPath $stderrFile -Force -ErrorAction SilentlyContinue }
        }

        Update-Ui -Window $window
    }

    Write-LogLine -LogBox $txtLog -Message ""
    Write-LogLine -LogBox $txtLog -Message ("Completed: success {0}, failed {1}" -f $success, $fail)
    $btnRun.IsEnabled = $true
})

$btnClose.Add_Click({ $window.Close() })

[void]$window.ShowDialog()
