param(
  [string]$BaseUrl = "http://127.0.0.1:8000",
  [string]$DevUser = "manual-user"
)

$headers = @{ 'X-Dev-User' = $DevUser }

function New-RangeJson {
  $now = (Get-Date).ToUniversalTime()
  $from = $now.AddDays(-90).ToString("o")
  $to = $now.ToString("o")
  return @{ from = $from; to = $to }
}

$health = Invoke-RestMethod -Uri "$BaseUrl/health" -Method Get

$consentReq = @{
  consentDuration = @{ unit = "MONTH"; value = "4" }
  vua = "9999999999@onemoney"
  fiTypes = @("DEPOSIT")
  consentTypes = @("PROFILE", "SUMMARY", "TRANSACTIONS")
  dataRange = New-RangeJson
  context = @(@{ key = "fipId"; value = "setu-fip,setu-fip-2" })
  additionalParams = @{ tags = @("manual-smoke") }
}

$consent = Invoke-RestMethod `
  -Uri "$BaseUrl/v2/consents" `
  -Method Post `
  -Headers $headers `
  -Body ($consentReq | ConvertTo-Json -Depth 12) `
  -ContentType "application/json"

$approve = Invoke-RestMethod `
  -Uri "$BaseUrl/v2/simulator/consents/$($consent.id)/action" `
  -Method Post `
  -Headers $headers `
  -Body '{"action":"approve"}' `
  -ContentType "application/json"

$sessionReq = @{
  consentId = $consent.id
  dataRange = New-RangeJson
  format = "json"
}

$session = Invoke-RestMethod `
  -Uri "$BaseUrl/v2/sessions" `
  -Method Post `
  -Headers $headers `
  -Body ($sessionReq | ConvertTo-Json -Depth 8) `
  -ContentType "application/json"

$fetch = Invoke-RestMethod -Uri "$BaseUrl/v2/sessions/$($session.id)" -Method Get -Headers $headers

$analyze = Invoke-RestMethod `
  -Uri "$BaseUrl/api/analyze-transactions" `
  -Method Post `
  -Headers $headers `
  -Body '{}' `
  -ContentType "application/json"

$latest = Invoke-RestMethod -Uri "$BaseUrl/api/analysis/latest" -Method Get -Headers $headers
$merchant = $latest.detected_subscriptions[0].merchant_code

$revoke = Invoke-RestMethod `
  -Uri "$BaseUrl/api/revoke-mandate" `
  -Method Post `
  -Headers $headers `
  -Body (@{ merchant_code = $merchant } | ConvertTo-Json) `
  -ContentType "application/json"

[PSCustomObject]@{
  health = $health.status
  consentStatus = $consent.status
  approvedStatus = $approve.status
  sessionStatus = $session.status
  fetchStatus = $fetch.status
  detectedCount = $analyze.detected_subscriptions.Count
  latestDetectedCount = $latest.detected_subscriptions.Count
  revokedMerchant = $revoke.merchant_code
  revokeStatus = $revoke.status
} | Format-List
