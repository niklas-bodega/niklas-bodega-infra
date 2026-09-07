$ErrorActionPreference = "Stop"

Write-Host "Running review-service tests..."
Push-Location ../review-service
./mvnw test
Pop-Location

Write-Host "Running booking-service tests..."
Push-Location ../booking
./mvnw test
Pop-Location

Write-Host "Running user-service tests..."
Push-Location ../user
./mvnw test
Pop-Location

Write-Host "All tests passed."