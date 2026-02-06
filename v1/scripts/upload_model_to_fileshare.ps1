param(
  [Parameter(Mandatory = $true)][string]$KeyVaultName,
  [Parameter(Mandatory = $true)][string]$StorageAccountName,
  [Parameter(Mandatory = $true)][string]$FileShareName
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$modelLocalPath = Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath "training\artifacts\model.pkl"
if (-not (Test-Path $modelLocalPath)) {
  throw "Arquivo nÃ£o encontrado: $modelLocalPath. Execute o treino antes (veja training\README.md)."
}

$saKey = az keyvault secret show --vault-name $KeyVaultName --name "storage-account-key" --query value -o tsv

az storage file upload `
  --account-name $StorageAccountName `
  --account-key $saKey `
  --share-name $FileShareName `
  --source $modelLocalPath `
  --path "model.pkl"

Write-Host "Upload concluÃ­do: model.pkl"
