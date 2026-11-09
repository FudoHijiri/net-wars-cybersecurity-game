# Crops the extra Recovery office props from the licensed source sheets.
# Every output is an exact pixel crop (no scaling, recolouring, flipping or generation),
# trimmed to its visible pixels. Re-run after changing a rectangle below:
#   powershell -ExecutionPolicy Bypass -File tools/prepare_recovery_props.ps1
param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))

Add-Type -AssemblyName System.Drawing

$midcentury = Join-Path $ProjectRoot 'art_source/recovery/licensed/midcentury/midcentury_modern_furnitureset.png'
$imersa = Join-Path $ProjectRoot 'art_source/recovery/licensed/imersa-office-free/Props'
$outDir = Join-Path $ProjectRoot 'assets/recovery/office/props'
New-Item -ItemType Directory -Force $outDir | Out-Null

# name = source sheet search rectangle (x, y, w, h); the crop is trimmed to visible pixels inside it.
$sheetCrops = [ordered]@{
	'armchair_back_green'   = @(33, 30, 30, 37)
	'armchair_back_brown'   = @(129, 30, 30, 37)
	'bookshelf_front'       = @(98, 352, 46, 98)
	'bookshelf_side'        = @(158, 352, 20, 98)
	'print_blue'            = @(192, 257, 22, 35)
	'print_orange'          = @(213, 257, 22, 35)
	'print_yellow'          = @(234, 257, 22, 35)
	'coffee_table'          = @(318, 36, 34, 28)
	'wall_sun_clock'        = @(352, 191, 32, 28)
	'palm_plant'            = @(413, 226, 38, 66)
	'leafy_plant_stand'     = @(413, 294, 36, 62)
	'small_plant'           = @(355, 262, 22, 29)
	'floor_lamp_white'      = @(545, 295, 32, 58)
	'rug_green'             = @(446, 127, 68, 68)
	'rug_grey'              = @(446, 0, 68, 66)
	'sofa_back_blue'        = @(444, 379, 56, 40)
}

function Save-Trimmed([System.Drawing.Bitmap]$sheet, [int[]]$rect, [string]$path) {
	$x0 = [Math]::Max(0, $rect[0]); $y0 = [Math]::Max(0, $rect[1])
	$x1 = [Math]::Min($sheet.Width, $rect[0] + $rect[2]); $y1 = [Math]::Min($sheet.Height, $rect[1] + $rect[3])
	$minX = $x1; $minY = $y1; $maxX = -1; $maxY = -1
	for ($y = $y0; $y -lt $y1; $y++) {
		for ($x = $x0; $x -lt $x1; $x++) {
			if ($sheet.GetPixel($x, $y).A -gt 0) {
				if ($x -lt $minX) { $minX = $x }; if ($x -gt $maxX) { $maxX = $x }
				if ($y -lt $minY) { $minY = $y }; if ($y -gt $maxY) { $maxY = $y }
			}
		}
	}
	if ($maxX -lt 0) { throw "No visible pixels in $path" }
	$w = $maxX - $minX + 1; $h = $maxY - $minY + 1
	$crop = $sheet.Clone((New-Object System.Drawing.Rectangle $minX, $minY, $w, $h), $sheet.PixelFormat)
	$crop.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
	$crop.Dispose()
	"{0,-22} source ({1},{2}) size {3}x{4}" -f (Split-Path -Leaf $path), $minX, $minY, $w, $h
}

$sheet = [System.Drawing.Bitmap]::FromFile($midcentury)
foreach ($name in $sheetCrops.Keys) {
	Save-Trimmed $sheet $sheetCrops[$name] (Join-Path $outDir "$name.png")
}
$sheet.Dispose()

# The Imersa filing cabinet is a single authored back view; copy it unchanged at its native size.
$imersaFiles = [ordered]@{
	'filing_cabinet_back' = 'Storage/filing_cabinet/filing_cabinet_back.png'
}
foreach ($name in $imersaFiles.Keys) {
	$source = Join-Path $imersa $imersaFiles[$name]
	$target = Join-Path $outDir "$name.png"
	Copy-Item $source $target -Force
	$image = [System.Drawing.Bitmap]::FromFile($target)
	"{0,-22} copied {1}x{2}" -f "$name.png", $image.Width, $image.Height
	$image.Dispose()
}
