param(
  [Parameter(Mandatory = $true)][string]$PredictUrl,
  [Parameter(Mandatory = $true)][string]$ApiKey
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Example 1: Iris Setosa (small petals)
Write-Host "`n--- Predicting Iris Setosa ---"
$body = @{
  sepal_length = 5.1
  sepal_width  = 3.5
  petal_length = 1.4
  petal_width  = 0.2
} | ConvertTo-Json

Invoke-RestMethod -Method POST -Uri $PredictUrl -Headers @{ "X-API-Key" = $ApiKey } -ContentType "application/json" -Body $body

# Example 2: Iris Versicolor (medium petals)
Write-Host "`n--- Predicting Iris Versicolor ---"
$body = @{
  sepal_length = 7.0
  sepal_width  = 3.2
  petal_length = 4.7
  petal_width  = 1.4
} | ConvertTo-Json

Invoke-RestMethod -Method POST -Uri $PredictUrl -Headers @{ "X-API-Key" = $ApiKey } -ContentType "application/json" -Body $body

# Example 3: Iris Virginica (large petals)
Write-Host "`n--- Predicting Iris Virginica ---"
$body = @{
  sepal_length = 6.3
  sepal_width  = 3.3
  petal_length = 6.0
  petal_width  = 2.5
} | ConvertTo-Json

Invoke-RestMethod -Method POST -Uri $PredictUrl -Headers @{ "X-API-Key" = $ApiKey } -ContentType "application/json" -Body $body
