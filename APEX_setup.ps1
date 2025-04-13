# Oracle APEX Full Automation Script for Windows

# === Configuration ===
$OracleSID = "XE"
$OracleHome = "C:\app\oracle\product\19.0.0\dbhome_1" #verify location
$Env:Path = "$OracleHome\bin;$Env:Path"

$DBUser = "sys" #verify db username is created
$DBPassword = "YourSysPassword" #db user password
$ApexZip = "apex_23.1.zip" #verify version
$ApexDir = "apex"

Write-Host "============================================"
Write-Host " Oracle APEX Install + Verify + Cleanup Tool"
Write-Host "============================================"

# === Step 1: Unzip APEX ===
if (Test-Path $ApexDir) {
    Write-Host "APEX directory already exists. Skipping unzip." -ForegroundColor Yellow
} else {
    Write-Host "Unzipping APEX package..." -ForegroundColor Cyan
    Expand-Archive -Path $ApexZip -DestinationPath "."
}

# === Step 2: Install APEX ===
Write-Host "Installing Oracle APEX into database..." -ForegroundColor Cyan
& sqlplus "$DBUser/$DBPassword@$OracleSID as sysdba" "@$ApexDir\apexins.sql SYSAUX SYSAUX TEMP /i/"

# === Step 3: Set Admin Password ===
Write-Host "Setting APEX Administrator password..." -ForegroundColor Cyan
& sqlplus "$DBUser/$DBPassword@$OracleSID as sysdba" "@$ApexDir\apxchpwd.sql"

# === Step 4: Unlock APEX_PUBLIC_USER and configure REST ===
Write-Host "Running REST configuration script..." -ForegroundColor Cyan
& sqlplus "$DBUser/$DBPassword@$OracleSID as sysdba" "@$ApexDir\restconfig.sql"

# === Step 5: Verify Installation ===
Write-Host "Verifying Oracle APEX installation..." -ForegroundColor Cyan

$sqlCheck = @"
SET HEADING OFF
SET FEEDBACK OFF
SELECT version FROM apex_release;
EXIT;
"@
$sqlCheck | Out-File -Encoding ascii ".\check_apex.sql"

$output = & sqlplus "$DBUser/$DBPassword@$OracleSID as sysdba" "@check_apex.sql"
Remove-Item ".\check_apex.sql"

if ($output -match "\d+\.\d+\.\d+") {
    Write-Host "✅ APEX Installed Successfully! Detected Version: $($output.Trim())" -ForegroundColor Green
} else {
    Write-Host "❌ APEX Version Check Failed — Please verify manually!" -ForegroundColor Red
}

# === Step 6: Cleanup ===
if (Test-Path $ApexDir) {
    Write-Host "Cleaning up: removing extracted APEX directory..." -ForegroundColor Cyan
    Remove-Item -Recurse -Force $ApexDir
} else {
    Write-Host "No extracted APEX directory found. Cleanup skipped." -ForegroundColor Yellow
}

Write-Host "============================================"
Write-Host " Oracle APEX Automation Completed!"
Write-Host "============================================"
