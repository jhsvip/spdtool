param([string]$In, [string]$Out, [int]$X, [int]$Y, [int]$W, [int]$H, [double]$Scale = 2.0)
Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Image]::FromFile($In)
$dw = [int]($W * $Scale); $dh = [int]($H * $Scale)
$bmp = New-Object System.Drawing.Bitmap($dw, $dh)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.DrawImage($src, (New-Object System.Drawing.Rectangle(0, 0, $dw, $dh)), (New-Object System.Drawing.Rectangle($X, $Y, $W, $H)), [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose(); $src.Dispose()
Write-Output ("cropped " + $Out + " " + $dw + "x" + $dh)
