$filePath = 'telegraf.exe';
$newArgs = [System.Collections.ArrayList]@($args);
if ($newArgs.Count -gt 0 -and -not $newArgs[0].StartsWith('-')) {
  $filePath = $newArgs[0]
  $newArgs.Remove(0);
}
if ($newArgs.Count -gt 0) {
  Start-Process -FilePath $filePath -ArgumentList $newArgs -NoNewWindow -Wait;
} else {
  Start-Process -FilePath $filePath -ArgumentList $newArgs -NoNewWindow -Wait;
}
Exit $LASTEXITCODE;
