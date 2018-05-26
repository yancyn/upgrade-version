# > powershell -ExecutionPolicy ByPass -File "upgrade-version.ps1"
# Steps
# 1. Get latest version from CHANGLOG.md
# 2. replace version string in AssemblyInfo.cs, Build.proj, Product.ws

echo "Get latest version from CHANGELOG.md";
$global:version = "";
$line = "";
$file = New-Object System.IO.StreamReader -ArgumentList "CHANGELOG.md";
while( ($line = $file.ReadLine()) -ne $null) {
	$words = ([regex]::matches($line, "[0-9.]+") | %{$_.value})
	if($words.Count -gt 0) {
		foreach($w in $words) {
			$global:version += $w;
		}
		break;
	}
}
echo "Latest: $global:version";

# Recursive lookup file contains version
function SeekVersionFile($directoryInfo) {

	# skip these folders
	if($directoryInfo.Name -eq ".git" -Or $directoryInfo.Name -eq ".vs" -Or $directoryInfo.Name -eq "packages") {
		return;
	}

	# list out all files under the directory
	$files = $directoryInfo.GetFiles();
	foreach($file in $files) {
	
		if($file.FullName -match ".+?Build.proj$") {
			echo $file.FullName;			
			$lines = [System.IO.File]::ReadAllLines($file.FullName);
			For($i=0; $i -lt $lines.Count; $i++) {
				if($lines[$i] -match "<Version>[0-9.]+</Version>") {
					$lines[$i] = $lines[$i] -replace "[0-9.]+", $global:version;
					echo $lines[$i];
				}
				if($lines[$i] -match "<FileVersion>[0-9.]+</FileVersion>") {
					$lines[$i] = $lines[$i] -replace "[0-9.]+", $global:version;
					echo $lines[$i];
				}
				if($lines[$i] -match "<InformationalVersion>[0-9.]+</InformationalVersion>") {
					$lines[$i] = $lines[$i] -replace "[0-9.]+", $global:version;
					echo $lines[$i];
				}
			}
			[System.IO.File]::WriteAllLines($file.FullName, $lines);
		}
		
		if($file.FullName -match ".+?Product.wxs$") {
			echo $file.FullName;
			$lines = [System.IO.File]::ReadAllLines($file.FullName);
			For($i=0; $i -lt $lines.Count; $i++) {
				if($i -eq 2) {
					$lines[$i] = $lines[$i] -replace "[0-9.]+", $global:version;
					echo $lines[$i];
				}
			}
			[System.IO.File]::WriteAllLines($file.FullName, $lines);
		}
		
		if($file.FullName -match ".+?AssemblyInfo.cs$") {
			echo $file.FullName;			
			$lines = [System.IO.File]::ReadAllLines($file.FullName);
			For($i=0; $i -lt $lines.Count; $i++) {
				if($lines[$i] -match "^[[]assembly: AssemblyVersion") {
					$lines[$i] = $lines[$i] -replace "[0-9.]+", "$global:version.";
					echo $lines[$i];
				}
			}
			$encoding = New-Object System.Text.UTF8Encoding -ArgumentList true;
			[System.IO.File]::WriteAllLines($file.FullName, $lines, $encoding);
		}
	}
	
	# loop sub folders
	$directories = $directoryInfo.GetDirectories();
	foreach($directory in $directories) {
		SeekVersionFile $directory;
	}
}

$directoryInfo = New-Object System.IO.DirectoryInfo -ArgumentList ".";
SeekVersionFile $directoryInfo;