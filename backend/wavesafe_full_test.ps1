# ============================================================
# WaveSafe -- FULL FEATURE TEST SUITE
# Every check runs independently; a failure is logged and the
# suite moves on (no early exit). Run from backend/ with venv active.
# Usage: .\wavesafe_full_test.ps1
# ============================================================

$BaseUrl = "http://localhost:8000"
$DbHost="localhost"; $DbPort="5433"; $DbUser="coastal"; $DbName="coastal_safety"; $DbPass="changeme"
$env:PGPASSWORD = $DbPass

# Paste a valid JWT (avoid re-triggering OTP/SMS)
$Token = ""     # <-- PASTE JWT HERE

$Results = @()
function Step {
    param($Name, [scriptblock]$Block)
    Write-Host "`n--- $Name ---" -ForegroundColor Cyan
    try {
        $r = & $Block
        $script:Results += [PSCustomObject]@{ Step=$Name; Status="PASS"; Detail=$r }
        Write-Host "PASS: $r" -ForegroundColor Green
    } catch {
        $script:Results += [PSCustomObject]@{ Step=$Name; Status="FAIL"; Detail=$_.Exception.Message }
        Write-Host "FAIL (skipped): $($_.Exception.Message)" -ForegroundColor Yellow
    }
}
function Psql($q) { (psql -h $DbHost -p $DbPort -U $DbUser -d $DbName -t -A -c $q).Trim() }

$Headers = @{}
$UserId = $null
if ($Token -and $Token.Trim() -ne "") {
    try {
        $p = $Token.Split(".")[1]; $p += ("=" * ((4 - $p.Length % 4) % 4))
        $claims = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($p)) | ConvertFrom-Json
        $UserId = $claims.sub
        $Headers = @{ Authorization = "Bearer $Token" }
    } catch {}
}

# ============================================================
# 1. HEALTH
# ============================================================
Step "Health check /healthz" { (Invoke-RestMethod "$BaseUrl/healthz") | Out-String }
Step "Readiness /readyz" { (Invoke-RestMethod "$BaseUrl/readyz") | Out-String }
Step "OpenAPI schema loads" { if (-not (Invoke-RestMethod "$BaseUrl/openapi.json")) { throw "empty" }; "OK" }

# ============================================================
# 2. AUTH
# ============================================================
Step "POST /v1/auth/otp/request (dev fallback, no SMS)" {
    $b = @{ phone = "+919999999999" } | ConvertTo-Json
    Invoke-RestMethod -Uri "$BaseUrl/v1/auth/otp/request" -Method Post -Body $b -ContentType "application/json" | Out-String
}
Step "JWT provided is valid" {
    if (-not $Token) { throw "no token supplied" }
    if ($Token.Split(".").Count -ne 3) { throw "malformed JWT" }
    "sub=$UserId"
}
Step "POST /v1/auth/logout" {
    if (-not $Token) { throw "no token" }
    Invoke-RestMethod -Uri "$BaseUrl/v1/auth/logout" -Headers $Headers -Method Post | Out-String
}

# ============================================================
# 3. BEACHES
# ============================================================
Step "GET /v1/beaches (list/search)" {
    $r = Invoke-RestMethod "$BaseUrl/v1/beaches"
    $items = if ($r.items) { $r.items } else { $r }
    if (@($items).Count -eq 0) { throw "no beaches returned" }
    "count=$(@($items).Count)"
}
$BeachId = "e5afce33-9d88-45cf-b2a7-6d5257a262d4"  # Marina Beach
Step "GET /v1/beaches/{id}" { (Invoke-RestMethod "$BaseUrl/v1/beaches/$BeachId").name }
Step "GET /v1/beaches/{id}/forecast" { (Invoke-RestMethod "$BaseUrl/v1/beaches/$BeachId/forecast") | Out-String }
Step "GET /v1/beaches/{id}/risk" { (Invoke-RestMethod "$BaseUrl/v1/beaches/$BeachId/risk") | Out-String }
Step "GET /v1/beaches/{id}/validate-geometry" { (Invoke-RestMethod "$BaseUrl/v1/beaches/$BeachId/validate-geometry") | Out-String }

# ============================================================
# 4. SOS / INCIDENTS
# ============================================================
Step "POST /v1/sos (full dispatch pipeline)" {
    if (-not $Token) { throw "no token" }
    $body = @{
        user_id = $UserId; device_id = "3fa85f64-5717-4562-b3fc-2c963f66afa6"
        trigger_type = "manual"; incident_type = "drowning_risk"; severity = "high"
        beach_id = $BeachId; activity_type = "swimming"
        location = @{ lat=13.05; lng=80.28; accuracy_m=5; source="gps" }
        hazard_context = @{ alert_flags=@() }; device_state = @{ offline=$false }
        contacts=@(); media=@(); notes = "full suite test"
    } | ConvertTo-Json -Depth 5
    $r = Invoke-RestMethod -Uri "$BaseUrl/v1/sos" -Headers $Headers -Method Post -Body $body -ContentType "application/json"
    $script:LastIncidentId = $r.incident_id
    "status=$($r.status), id=$($r.incident_id)"
}
Step "GET /v1/incidents/{id}" {
    if (-not $script:LastIncidentId) { throw "no incident_id from prior step" }
    (Invoke-RestMethod -Uri "$BaseUrl/v1/incidents/$($script:LastIncidentId)" -Headers $Headers) | Out-String
}
Step "GET /v1/incidents/{id}/status" {
    if (-not $script:LastIncidentId) { throw "no incident_id from prior step" }
    (Invoke-RestMethod -Uri "$BaseUrl/v1/incidents/$($script:LastIncidentId)/status" -Headers $Headers) | Out-String
}
Step "POST /v1/incidents/{id}/ack" {
    if (-not $script:LastIncidentId) { throw "no incident_id from prior step" }
    Invoke-RestMethod -Uri "$BaseUrl/v1/incidents/$($script:LastIncidentId)/ack" -Headers $Headers -Method Post | Out-String
}

# ============================================================
# 5. SAFEZONE
# ============================================================
Step "GET /v1/guidance/active" {
    Invoke-RestMethod -Uri "$BaseUrl/v1/guidance/active" -Headers $Headers | Out-String
}
Step "POST /v1/guidance (compute route)" {
    $body = @{ beach_id = $BeachId; lat=13.05; lng=80.28 } | ConvertTo-Json
    $r = Invoke-RestMethod -Uri "$BaseUrl/v1/guidance" -Headers $Headers -Method Post -Body $body -ContentType "application/json"
    $script:GuidanceId = $r.id
    $r | Out-String
}

# ============================================================
# 6. TRIPS
# ============================================================
Step "GET /v1/trips (list)" { Invoke-RestMethod -Uri "$BaseUrl/v1/trips" -Headers $Headers | Out-String }
Step "POST /v1/trips (create)" {
    $body = @{ beach_id=$BeachId; activity_type="swimming"; planned_start="2026-08-25T09:00:00Z" } | ConvertTo-Json
    $r = Invoke-RestMethod -Uri "$BaseUrl/v1/trips" -Headers $Headers -Method Post -Body $body -ContentType "application/json"
    $script:TripId = $r.id
    $r | Out-String
}
Step "GET /v1/trips/{id}" {
    if (-not $script:TripId) { throw "no trip_id from prior step" }
    Invoke-RestMethod -Uri "$BaseUrl/v1/trips/$($script:TripId)" -Headers $Headers | Out-String
}
Step "GET /v1/trips/{id}/risk" {
    if (-not $script:TripId) { throw "no trip_id from prior step" }
    Invoke-RestMethod -Uri "$BaseUrl/v1/trips/$($script:TripId)/risk" -Headers $Headers | Out-String
}

# ============================================================
# 7. NOTIFICATIONS
# ============================================================
Step "GET /v1/notifications" { Invoke-RestMethod -Uri "$BaseUrl/v1/notifications" -Headers $Headers | Out-String }

# ============================================================
# 8. EMERGENCY SHARE
# ============================================================
Step "POST /v1/share/start" {
    $body = @{ beach_id = $BeachId } | ConvertTo-Json
    $r = Invoke-RestMethod -Uri "$BaseUrl/v1/share/start" -Headers $Headers -Method Post -Body $body -ContentType "application/json"
    $script:ShareSessionId = $r.share_session_id
    $r | Out-String
}
Step "GET /v1/share/{share_session_id}" {
    if (-not $script:ShareSessionId) { throw "no share_session_id" }
    Invoke-RestMethod -Uri "$BaseUrl/v1/share/$($script:ShareSessionId)" | Out-String
}
Step "POST /v1/share/stop" {
    $body = @{ share_session_id = $script:ShareSessionId } | ConvertTo-Json
    Invoke-RestMethod -Uri "$BaseUrl/v1/share/stop" -Headers $Headers -Method Post -Body $body -ContentType "application/json" | Out-String
}

# ============================================================
# 9. OFFLINE SYNC
# ============================================================
Step "GET /v1/offline/bundle" { Invoke-RestMethod -Uri "$BaseUrl/v1/offline/bundle?beach_id=$BeachId" -Headers $Headers | Out-String }
Step "POST /v1/offline/sos-queue" {
    $body = @{ packets = @() } | ConvertTo-Json
    Invoke-RestMethod -Uri "$BaseUrl/v1/offline/sos-queue" -Headers $Headers -Method Post -Body $body -ContentType "application/json" | Out-String
}

# ============================================================
# 10. TRACKING (live sessions)
# ============================================================
Step "POST /v1/tracking/sessions (start)" {
    $body = @{ beach_id = $BeachId } | ConvertTo-Json
    $r = Invoke-RestMethod -Uri "$BaseUrl/v1/tracking/sessions" -Headers $Headers -Method Post -Body $body -ContentType "application/json"
    $script:TrackSessionId = $r.session_id
    $r | Out-String
}
Step "POST /v1/tracking/sessions/{id}/ping" {
    if (-not $script:TrackSessionId) { throw "no session_id" }
    $body = @{ lat=13.05; lng=80.28 } | ConvertTo-Json
    Invoke-RestMethod -Uri "$BaseUrl/v1/tracking/sessions/$($script:TrackSessionId)/ping" -Headers $Headers -Method Post -Body $body -ContentType "application/json" | Out-String
}
Step "GET /v1/tracking/sessions/{id}" {
    if (-not $script:TrackSessionId) { throw "no session_id" }
    Invoke-RestMethod -Uri "$BaseUrl/v1/tracking/sessions/$($script:TrackSessionId)" -Headers $Headers | Out-String
}
Step "POST /v1/tracking/sessions/{id}/stop" {
    if (-not $script:TrackSessionId) { throw "no session_id" }
    Invoke-RestMethod -Uri "$BaseUrl/v1/tracking/sessions/$($script:TrackSessionId)/stop" -Headers $Headers -Method Post | Out-String
}

# ============================================================
# 11. AUTHORITY / HOSPITAL ROUTER (internal dispatch)
# ============================================================
Step "POST /internal/authority-router/dispatch" {
    $body = @{ incident_id = $script:LastIncidentId } | ConvertTo-Json
    Invoke-RestMethod -Uri "$BaseUrl/internal/authority-router/dispatch" -Method Post -Body $body -ContentType "application/json" | Out-String
}
Step "POST /internal/hospital-router/dispatch" {
    $body = @{ incident_id = $script:LastIncidentId } | ConvertTo-Json
    Invoke-RestMethod -Uri "$BaseUrl/internal/hospital-router/dispatch" -Method Post -Body $body -ContentType "application/json" | Out-String
}

# ============================================================
# 12. ADMIN / AUDIT
# ============================================================
Step "GET /v1/admin/alerts" { Invoke-RestMethod -Uri "$BaseUrl/v1/admin/alerts" -Headers $Headers | Out-String }
Step "GET /v1/admin/alert-accuracy" { Invoke-RestMethod -Uri "$BaseUrl/v1/admin/alert-accuracy" -Headers $Headers | Out-String }
Step "GET /v1/admin/missed-warnings" { Invoke-RestMethod -Uri "$BaseUrl/v1/admin/missed-warnings" -Headers $Headers | Out-String }
Step "GET /v1/admin/response-time" { Invoke-RestMethod -Uri "$BaseUrl/v1/admin/response-time" -Headers $Headers | Out-String }
Step "GET /v1/admin/threshold-recommendations" { Invoke-RestMethod -Uri "$BaseUrl/v1/admin/threshold-recommendations" -Headers $Headers | Out-String }
Step "GET /v1/audit/metrics/response-latency" { Invoke-RestMethod -Uri "$BaseUrl/v1/audit/metrics/response-latency" -Headers $Headers | Out-String }
Step "POST /v1/audit/logs/export" {
    Invoke-RestMethod -Uri "$BaseUrl/v1/audit/logs/export" -Headers $Headers -Method Post | Out-String
}

# ============================================================
# 13. INGESTION
# ============================================================
Step "POST /internal/ingest/sachet" {
    Invoke-RestMethod -Uri "$BaseUrl/internal/ingest/sachet" -Method Post | Out-String
}
Step "INCOIS connector confirmed disabled (code check)" {
    $match = Select-String -Path "app\services\ingestion_service.py" -Pattern "def build_connectors" -Context 0,6 | Select-Object -Last 1
    $block = ($match.Context.PostContext -join "`n")
    if ($block -match "IncoisConnector\(") { throw "IncoisConnector still active" }
    "confirmed"
}

# ============================================================
# 14. DB-LEVEL SANITY (data integrity regression checks)
# ============================================================
Step "DB: no duplicate Marina Beach" {
    $c = Psql "SELECT count(*) FROM beaches WHERE name='Marina Beach';"
    if ([int]$c -ne 1) { throw "found $c rows" }; "OK"
}
Step "DB: no invalid jurisdiction authority_type" {
    $c = Psql "SELECT count(*) FROM jurisdictions WHERE authority_type='police';"
    if ([int]$c -ne 0) { throw "found $c bad rows" }; "OK"
}
Step "DB: no test hospitals/safe_zones" {
    $h = Psql "SELECT count(*) FROM hospitals WHERE name ILIKE '%test%';"
    $s = Psql "SELECT count(*) FROM safe_zones WHERE name ILIKE '%test%';"
    if ([int]$h -ne 0 -or [int]$s -ne 0) { throw "test rows present (h=$h,s=$s)" }; "OK"
}

# ============================================================
# SUMMARY
# ============================================================
Write-Host "`n`n================= SUMMARY =================" -ForegroundColor Magenta
$Results | Format-Table -AutoSize
$pass = ($Results | Where-Object Status -eq "PASS").Count
$fail = ($Results | Where-Object Status -eq "FAIL").Count
Write-Host "$pass PASSED / $fail FAILED (out of $($Results.Count))" -ForegroundColor $(if($fail -eq 0){"Green"}else{"Yellow"})
if ($fail -gt 0) {
    Write-Host "`nFailed steps:" -ForegroundColor Yellow
    $Results | Where-Object Status -eq "FAIL" | ForEach-Object { Write-Host "  - $($_.Step): $($_.Detail)" -ForegroundColor Yellow }
}