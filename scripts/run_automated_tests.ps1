Write-Host "Running Python tests..." -ForegroundColor Cyan
c:/Users/Amaan/Downloads/sub-detox/.venv/Scripts/python.exe -m pytest c:/Users/Amaan/Downloads/sub-detox
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Running Flutter analyzer..." -ForegroundColor Cyan
flutter analyze c:/Users/Amaan/Downloads/sub-detox/subdetox_flutter
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Running Functions syntax check..." -ForegroundColor Cyan
node --check c:/Users/Amaan/Downloads/sub-detox/functions/src/index.js
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "All automated checks passed." -ForegroundColor Green
