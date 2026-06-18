$root = "C:\Users\lfcos\Downloads\CLAUDE\copy site teste"
$prefix = "http://localhost:8765/"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)
$listener.Start()
Write-Host "Serving $root at $prefix"

$mime = @{
  ".html"="text/html"; ".htm"="text/html"; ".js"="application/javascript";
  ".mjs"="application/javascript"; ".css"="text/css"; ".json"="application/json";
  ".gif"="image/gif"; ".png"="image/png"; ".jpg"="image/jpeg"; ".jpeg"="image/jpeg";
  ".webp"="image/webp"; ".svg"="image/svg+xml"; ".woff"="font/woff"; ".woff2"="font/woff2";
  ".ico"="image/x-icon"; ".mp4"="video/mp4"
}

while ($listener.IsListening) {
  try {
    $ctx = $listener.GetContext()
    $reqPath = [System.Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath.TrimStart("/"))
    if ([string]::IsNullOrEmpty($reqPath)) { $reqPath = "index_raw.html" }
    $file = Join-Path $root $reqPath
    $ext = [System.IO.Path]::GetExtension($file).ToLower()
    # SPA fallback: routes without a file extension serve index_raw.html
    if (-not (Test-Path $file -PathType Leaf) -and [string]::IsNullOrEmpty($ext)) {
      $file = Join-Path $root "index_raw.html"
      $ext = ".html"
    }
    if (Test-Path $file -PathType Leaf) {
      $ext = [System.IO.Path]::GetExtension($file).ToLower()
      $ct = $mime[$ext]; if (-not $ct) { $ct = "application/octet-stream" }
      $bytes = [System.IO.File]::ReadAllBytes($file)
      $ctx.Response.ContentType = $ct
      $ctx.Response.ContentLength64 = $bytes.Length
      $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $ctx.Response.StatusCode = 404
    }
    $ctx.Response.OutputStream.Close()
  } catch {}
}
