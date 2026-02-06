param(
  [Parameter(Mandatory = $true)][string]$PredictUrl,
  [Parameter(Mandatory = $true)][string]$ApiKey
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$body = @{
  sepal_length = 9.1
  sepal_width  = 9.5
  petal_length = 9.4
  petal_width  = 9.2
} | ConvertTo-Json

Invoke-RestMethod -Method POST -Uri $PredictUrl -Headers @{ "X-API-Key" = $ApiKey } -ContentType "application/json" -Body $body
