param([string]$ProjectRoot = (Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
public static class RecoveryRearViews {
    public static void Half(string input, string output) {
        using(var source = new Bitmap(input)) {
            int width = (source.Width + 1) / 2;
            int height = (source.Height + 1) / 2;
            using(var padded = new Bitmap(width * 2, height * 2, PixelFormat.Format32bppArgb))
            using(var image = new Bitmap(width, height, PixelFormat.Format32bppArgb)) {
                using(var g = Graphics.FromImage(padded)) g.DrawImageUnscaled(source, 0, 0);
                using(var g = Graphics.FromImage(image)) {
                    g.CompositingMode = CompositingMode.SourceCopy;
                    g.InterpolationMode = InterpolationMode.NearestNeighbor;
                    g.PixelOffsetMode = PixelOffsetMode.Half;
                    g.DrawImage(padded, new Rectangle(0,0,width,height), new Rectangle(0,0,width*2,height*2), GraphicsUnit.Pixel);
                }
                image.Save(output, ImageFormat.Png);
            }
        }
    }
    public static void Sofa(string input, string output) {
        using(var source = new Bitmap(input)) {
            Rectangle region = new Rectangle(448,384,48,32);
            int x0=region.Right,y0=region.Bottom,x1=-1,y1=-1;
            for(int y=region.Top;y<region.Bottom;y++)for(int x=region.Left;x<region.Right;x++)if(source.GetPixel(x,y).A>0) {
                x0=Math.Min(x0,x);y0=Math.Min(y0,y);x1=Math.Max(x1,x);y1=Math.Max(y1,y);
            }
            using(var image=source.Clone(Rectangle.FromLTRB(x0,y0,x1+1,y1+1),PixelFormat.Format32bppArgb)) image.Save(output,ImageFormat.Png);
            Console.WriteLine("Rear sofa crop: {0},{1},{2},{3}",x0,y0,x1-x0+1,y1-y0+1);
        }
    }
}
'@
$source = Join-Path $ProjectRoot 'art_source/recovery/licensed/imersa-office-free/Props'
$output = Join-Path $ProjectRoot 'assets/recovery/office/rear'
New-Item -ItemType Directory -Path $output -Force | Out-Null
foreach($item in @(
    @{source='Desks/office_desk/office_desk_back.png'; name='office_desk_back.png'},
    @{source='Seating/office_chair/office_chair_front.png'; name='office_chair_front.png'},
    @{source='Tech/computer/computer_back.png'; name='computer_back.png'},
    @{source='Storage/filing_cabinet/filing_cabinet_back.png'; name='filing_cabinet_back.png'}
)) {
    [RecoveryRearViews]::Half((Join-Path $source $item.source),(Join-Path $output $item.name))
}
[RecoveryRearViews]::Sofa((Join-Path $ProjectRoot 'art_source/recovery/licensed/midcentury/midcentury_modern_furnitureset.png'),(Join-Path $output 'sofa_back.png'))
