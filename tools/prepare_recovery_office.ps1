param([string]$ProjectRoot = (Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System; using System.Drawing; using System.Drawing.Imaging; using System.IO; using System.Collections.Generic;
public static class RecoveryOfficeArt {
    static Rectangle Bounds(Bitmap b, int threshold) {
        int x0=b.Width,y0=b.Height,x1=-1,y1=-1;
        for(int y=0;y<b.Height;y++)for(int x=0;x<b.Width;x++)if(b.GetPixel(x,y).A>=threshold){
            x0=Math.Min(x0,x);y0=Math.Min(y0,y);x1=Math.Max(x1,x);y1=Math.Max(y1,y);
        }
        if(x1<0)throw new Exception("Empty artwork");
        return Rectangle.FromLTRB(x0,y0,x1+1,y1+1);
    }
    public static void Slice(string input,string output,int x,int y,int width,int height) {
        using(var src=new Bitmap(input))using(var dst=src.Clone(new Rectangle(x,y,width,height),PixelFormat.Format32bppArgb))dst.Save(output,ImageFormat.Png);
    }
    public static string Crop(string input,string output) {
        using(var src=new Bitmap(input)) {
            Rectangle core=Bounds(src,16);
            using(var dst=src.Clone(core,PixelFormat.Format32bppArgb))dst.Save(output,ImageFormat.Png);
            return String.Format("{0}: source {1}x{2}, visible crop ({3},{4},{5},{6}); alpha threshold 16; no recolouring or resizing",Path.GetFileName(output),src.Width,src.Height,core.X,core.Y,core.Width,core.Height);
        }
    }
    public static int[] Gif(string input,string output) {
        using(var src=Image.FromFile(input)) {
            int count=src.GetFrameCount(FrameDimension.Time);
            byte[] raw=src.GetPropertyItem(0x5100).Value;
            int[] times=new int[count];
            Rectangle all=Rectangle.Empty;
            for(int i=0;i<count;i++){
                src.SelectActiveFrame(FrameDimension.Time,i);
                using(var b=new Bitmap(src))all=Rectangle.Union(all.IsEmpty?Bounds(b,16):all,Bounds(b,16));
                times[i]=Math.Max(1,BitConverter.ToInt32(raw,i*4));
            }
            using(var sheet=new Bitmap(all.Width*count,all.Height,PixelFormat.Format32bppArgb)) {
                for(int i=0;i<count;i++){
                    src.SelectActiveFrame(FrameDimension.Time,i);
                    using(var b=new Bitmap(src))for(int y=0;y<all.Height;y++)for(int x=0;x<all.Width;x++)sheet.SetPixel(i*all.Width+x,y,b.GetPixel(all.X+x,all.Y+y));
                }
                sheet.Save(output,ImageFormat.Png);
                Console.WriteLine("GIF: "+count+" frames, common crop "+all+", native delay units 1/100s");
            }
            return times;
        }
    }
}
'@
$sourceRoot = Join-Path $ProjectRoot 'art_source/recovery/office_v2/originals'
$outputRoot = Join-Path $ProjectRoot 'assets/recovery/office'
New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null
$report = @()
foreach ($file in Get-ChildItem -LiteralPath $sourceRoot -Filter '*.png' -File) {
    if ($file.Name -eq 'office-background.png') {
        Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $outputRoot $file.Name) -Force
    } else {
        $report += [RecoveryOfficeArt]::Crop($file.FullName,(Join-Path $outputRoot $file.Name))
    }
}
$delays = [RecoveryOfficeArt]::Gif((Join-Path $sourceRoot 'server-rack-blink.gif'),(Join-Path $outputRoot 'server-rack-frames.png'))
[IO.File]::WriteAllText((Join-Path $ProjectRoot 'art_source/recovery/office_v2/gif-delays.json'),($delays | ConvertTo-Json),[Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllLines((Join-Path $ProjectRoot 'art_source/recovery/office_v2/processing.txt'),$report,[Text.UTF8Encoding]::new($false))
$report

# Optional CC0 Pixel Office dressing; slice complete sprites without resampling.
$officeAtlas = Join-Path $ProjectRoot 'art_source/recovery/licensed/pixel-office/PixelOfficeAssets.png'
if (Test-Path -LiteralPath $officeAtlas) {
    $decorOutput = Join-Path $outputRoot 'decor'
    New-Item -ItemType Directory -Path $decorOutput -Force | Out-Null
    foreach ($piece in @(
        @{name='plant';x=169;y=63;w=16;h=22},
        @{name='bookcase';x=184;y=126;w=25;h=32},
        @{name='wastebasket';x=159;y=91;w=9;h=12},
        @{name='clock';x=158;y=107;w=23;h=8}
    )) {
        [RecoveryOfficeArt]::Slice($officeAtlas,(Join-Path $decorOutput ($piece.name + '.png')),$piece.x,$piece.y,$piece.w,$piece.h)
    }
}
