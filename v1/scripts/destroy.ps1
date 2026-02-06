Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Push-Location infra
terraform destroy -auto-approve
Pop-Location
