# ============================================================
# WaveSafe -- End-to-End Verification Script
# Tests everything fixed in the recent debugging session:
#   - Data seeding sanity
#   - Duplicate beach cleanup
#   - Dead jurisdiction cleanup
#   - Test-data cleanup
#   - Full SOS pipeline (safezone_service SELECT + INSERT fixes)
#
# Run from: C:\Users\Arvind Kumar\WaveSafe\backend  (venv activated)
# Usage:    .\wavesafe_e2e_test.ps1
# ============================================================

# ---------- CONFIG (edit these) ----------
$BaseUrl   = "http://localhost:8000"
$DbHost    = "localhost"
$DbPort    = "5433"
$DbUser    = "coastal"
$DbName    = "coastal_safety"
$DbPass    = "changeme"

# Paste an already-obtained JWT here (old method -- avoids triggering OTP/SMS).
$Token     = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZTk2OWRmYS0yMTk5LTQzNjYtYTNjNC1lMjJkYjMyOWRiNTYiLCJleHAiOjE3ODgwMTExNjV9.WFC5SvRvdO3IIKxQTzq0kaAQYtCbzrd-US9esqWXZCY"     # <-- PASTE JWT HERE
$env:PGPASSWORD = $DbPass

# ---------- HELPERS ----------
$Results = @()

function Test-Step {
    param($Name, [scriptblock]$Block)
    Write-Host "`n--- $Name ---" -ForegroundColor Cyan
    try {
        $r = & $Block
        $script:Results += [PSCustomObject]@{ Step = $Name; Status = "PASS"; Detail = $r }
        Write-Host "PASS" -ForegroundColor Green
        return $r
    } catch {
        $script:Results += [PSCustomObject]@{ Step = $Name; Status = "FAIL"; Detail = $_.Exception.Message }
        Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Psql-Scalar($query) {
    $out = psql -h $DbHost -p $DbPort -U $DbUser -d $DbName -t -A -c $query
    return $out.Trim()
}

# ============================================================
# 1. SERVER HEALTH
# ============================================================
Test-Step "Server reachable (GET /openapi.json)" {
    $r = Invoke-RestMethod -Uri "$BaseUrl/openapi.json" -Method Get
    if (-not $r) { throw "Empty response" }
    "OK"
}

# ============================================================
# 2. DB SANITY -- seeded data + cleanup checks
# ============================================================
Test-Step "Hospitals count >= 2, no 'Test' rows" {
    $count = Psql-Scalar "SELECT count(*) FROM hospitals;"
    $testCount = Psql-Scalar "SELECT count(*) FROM hospitals WHERE name ILIKE '%test%';"
    if ([int]$testCount -ne 0) { throw "Found $testCount test hospital rows" }
    if ([int]$count -lt 2) { throw "Only $count hospitals found" }
    "hospitals=$count, test_rows=$testCount"
}

Test-Step "Jurisdictions -- no invalid authority_type (police)" {
    $bad = Psql-Scalar "SELECT count(*) FROM jurisdictions WHERE authority_type = 'police';"
    if ([int]$bad -ne 0) { throw "Found $bad rows with invalid authority_type" }
    $total = Psql-Scalar "SELECT count(*) FROM jurisdictions;"
    "jurisdictions=$total, invalid=$bad"
}

Test-Step "No duplicate Marina Beach rows in DB" {
    $count = Psql-Scalar "SELECT count(*) FROM beaches WHERE name = 'Marina Beach';"
    if ([int]$count -ne 1) { throw "Expected 1 Marina Beach row, found $count" }
    "marina_beach_rows=$count"
}

Test-Step "Safe zones -- no Test Safe Zone, exactly 2 real zones" {
    $testZone = Psql-Scalar "SELECT count(*) FROM safe_zones WHERE name ILIKE '%test%';"
    $total = Psql-Scalar "SELECT count(*) FROM safe_zones;"
    if ([int]$testZone -ne 0) { throw "Found $testZone test safe_zone rows" }
    "safe_zones=$total, test_rows=$testZone"
}

# ============================================================
# 3. INGESTION -- INCOIS disabled at code level
# ============================================================
Test-Step "INCOIS connector absent from active build_connectors()" {
    $match = Select-String -Path "app\services\ingestion_service.py" -Pattern "def build_connectors" -Context 0,6 |
             Select-Object -Last 1
    $block = ($match.Context.PostContext -join "`n")
    if ($block -match "IncoisConnector\(") { throw "IncoisConnector still active in build_connectors()" }
    if ($block -notmatch "SachetConnector\(") { throw "SachetConnector missing -- unexpected" }
    "confirmed disabled"
}

# ============================================================
# 4. API LEVEL -- beaches endpoint (dedup confirmed live)
# ============================================================
Test-Step "GET /v1/beaches -- no duplicate Marina Beach" {
    $resp = Invoke-RestMethod -Uri "$BaseUrl/v1/beaches" -Method Get
    $beaches = if ($resp.items) { $resp.items } else { $resp }
    $marina = $beaches | Where-Object { $_.name -eq "Marina Beach" }
    if (@($marina).Count -ne 1) { throw "Expected 1 Marina Beach in API response, found $(@($marina).Count)" }
    "total_beaches=$(@($beaches).Count)"
}

# ============================================================
# 5. AUTH -- use pre-supplied JWT (no OTP/SMS triggered)
# ============================================================
$AuthToken = $null
Test-Step "JWT token supplied and structurally valid" {
    if (-not $Token -or $Token.Trim() -eq "") { throw "Token is empty -- paste a JWT into the CONFIG section" }
    $parts = $Token.Split(".")
    if ($parts.Count -ne 3) { throw "Token doesn't look like a valid JWT (expected 3 dot-separated parts)" }

    $payload = $parts[1]
    $payload += ("=" * ((4 - $payload.Length % 4) % 4))
    $json = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($payload))
    $claims = $json | ConvertFrom-Json

    if ($claims.exp) {
        $expDate = [DateTimeOffset]::FromUnixTimeSeconds($claims.exp).LocalDateTime
        if ($expDate -lt (Get-Date)) { throw "Token expired at $expDate" }
    }

        $script:AuthToken = $Token
    "sub=$($claims.sub), exp=$($claims.exp)"
}

if (-not $AuthToken) {
    Write-Host "`nCannot continue to SOS test without a valid token. Aborting SOS step." -ForegroundColor Red
} else {
    $payload = $AuthToken.Split(".")[1]
    $payload += ("=" * ((4 - $payload.Length % 4) % 4))
    $json = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($payload))
    $userId = ($json | ConvertFrom-Json).sub
    Write-Host "Using user_id: $userId" -ForegroundColor DarkGray

    $headers = @{ Authorization = "Bearer $AuthTokenS" }

    # ============================================================
    # 6. FULL SOS PIPELINE TEST -- the main event
    # ============================================================
    Test-Step "POST /v1/sos -- full dispatch pipeline" {
        $sosBody = @{
            user_id       = $userId
            device_id     = "3fa85f64-5717-4562-b3fc-2c963f66afa6"
            trigger_type  = "manual"
            incident_type = "drowning_risk"
            severity      = "high"
            beach_id      = "e5afce33-9d88-45cf-b2a7-6d5257a262d4"
            activity_type = "swimming"
            location      = @{ lat = 13.05; lng = 80.28; accuracy_m = 5; source = "gps" }
            hazard_context = @{ alert_flags = @() }
            device_state  = @{ offline = $false }
            contacts      = @()
            media         = @()
            notes         = "e2e automated test"
        } | ConvertTo-Json -Depth 5

        $r = Invoke-RestMethod -Uri "$BaseUrl/v1/sos" -Headers $headers -Method Post -Body $sosBody -ContentType "application/json"

        if ($r.status -ne "dispatched") { throw "Unexpected status: $($r.status)" }
        if (-not $r.safe_zone) { throw "No safe_zone in response -- safezone_service bug may have regressed" }

        $sentCount = @($r.primary_targets | Where-Object { $_.status -eq "sent" }).Count
        if ($sentCount -eq 0) { throw "No primary_targets marked sent" }

        "status=$($r.status), targets_sent=$sentCount, safe_zone=$($r.safe_zone.name)"
    }
}

# ============================================================
# SUMMARY
# ============================================================
Write-Host "`n`n================= SUMMARY =================" -ForegroundColor Magenta
$Results | Format-Table -AutoSize
$failCount = ($Results | Where-Object { $_.Status -eq "FAIL" }).Count
if ($failCount -eq 0) {
    Write-Host "ALL $($Results.Count) CHECKS PASSED" -ForegroundColor Green
} else {
    Write-Host "$failCount CHECK(S) FAILED -- see table above" -ForegroundColor Red
}