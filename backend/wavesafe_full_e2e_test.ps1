# ============================================================
# WaveSafe -- FULL Feature-by-Feature E2E Test
# Every endpoint tested individually. A failing test is
# recorded and SKIPPED -- script always continues to the next.
# Run from: backend folder (venv activated)
# Usage:    .\wavesafe_full_e2e_test.ps1
# ============================================================

# ---------- CONFIG (edit these) ----------
$BaseUrl = "http://localhost:8000"
$DbHost  = "localhost"
$DbPort  = "5433"
$DbUser  = "coastal"
$DbName  = "coastal_safety"
$DbPass  = "changeme"
$Token   = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJmYjhkNzE2ZC1jYWIzLTQ0ZTktYjYyNS03MzlmNWQ1ZTY2MWUiLCJleHAiOjE3ODgwMDk5ODN9.7Q_o5lgnRV4V191r5ZBsr3ykA2FkPvxfpg7DnEXqW50"  # <-- PASTE JWT HERE (skips OTP flow)
$InternalKey = "change-me"  # <-- internal service key if internal.py needs it
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
        $script:Results += [PSCustomObject]@{ Step = $Name; Status = "SKIP/FAIL"; Detail = $_.Exception.Message }
        Write-Host "SKIP (fail): $($_.Exception.Message)" -ForegroundColor Yellow
        return $null
    }
}

function Psql-Scalar($query) {
    $out = psql -h $DbHost -p $DbPort -U $DbUser -d $DbName -t -A -c $query
    return $out.Trim()
}

$Headers = @{}
$TokenUserId = $null
if ($Token) {
    $Headers = @{ Authorization = "Bearer $Token" }
    try {
        $payload = $Token.Split(".")[1]
        $payload += ("=" * ((4 - $payload.Length % 4) % 4))
        $json = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($payload))
        $TokenUserId = ($json | ConvertFrom-Json).sub
    } catch { Write-Host "Could not decode token sub" -ForegroundColor Yellow }
}

# ============================================================
# 1. HEALTH
# ============================================================
Test-Step "GET /healthz" { Invoke-RestMethod -Uri "$BaseUrl/healthz" -Method Get }
Test-Step "GET /readyz"  { Invoke-RestMethod -Uri "$BaseUrl/readyz" -Method Get }
Test-Step "GET /openapi.json reachable" {
    $r = Invoke-RestMethod -Uri "$BaseUrl/openapi.json" -Method Get
    if (-not $r) { throw "Empty response" }; "OK"
}

# ============================================================
# 2. AUTH (OTP flow)
# ============================================================
Test-Step "POST /v1/auth/otp/request" {
    $body = @{ phone = "+919999999999" } | ConvertTo-Json
    Invoke-RestMethod -Uri "$BaseUrl/v1/auth/otp/request" -Method Post -Body $body -ContentType "application/json"
}
Test-Step "POST /v1/auth/otp/verify" {
    $body = @{ phone = "+919999999999"; code = "123456" } | ConvertTo-Json
    Invoke-RestMethod -Uri "$BaseUrl/v1/auth/otp/verify" -Method Post -Body $body -ContentType "application/json"
}
Test-Step "POST /v1/auth/logout" {
    Invoke-RestMethod -Uri "$BaseUrl/v1/auth/logout" -Method Post -Headers $Headers
}

# ============================================================
# 3. BEACH
# ============================================================
$BeachId = $null
Test-Step "GET /v1/beaches" {
    $r = Invoke-RestMethod -Uri "$BaseUrl/v1/beaches" -Method Get
    $items = if ($r.items) { $r.items } else { $r }
    if (@($items).Count -gt 0) { $script:BeachId = $items[0].id }
    "count=$(@($items).Count)"
}
Test-Step "GET /v1/beaches/{id}" {
    if (-not $BeachId) { throw "No beach id from prior step" }
    Invoke-RestMethod -Uri "$BaseUrl/v1/beaches/$BeachId" -Method Get
}
Test-Step "GET /v1/beaches/{id}/risk" {
    if (-not $BeachId) { throw "No beach id" }
    Invoke-RestMethod -Uri "$BaseUrl/v1/beaches/$BeachId/risk" -Method Get
}
Test-Step "GET /v1/beaches/{id}/forecast" {
    if (-not $BeachId) { throw "No beach id" }
    Invoke-RestMethod -Uri "$BaseUrl/v1/beaches/$BeachId/forecast" -Method Get
}
Test-Step "GET /v1/alerts" { Invoke-RestMethod -Uri "$BaseUrl/v1/alerts?near=13.05,80.28&radius_m=50000" -Method Get }

# ============================================================
# 4. TRIPS
# ============================================================
$TripId = $null
Test-Step "GET /v1/trips" { Invoke-RestMethod -Uri "$BaseUrl/v1/trips" -Method Get -Headers $Headers }
Test-Step "POST /v1/trips" {
    $body = @{
        beach_id = $BeachId; activity_type = "swimming"
        planned_from = (Get-Date).AddHours(1).ToString("o")
        planned_to   = (Get-Date).AddHours(3).ToString("o")
    } | ConvertTo-Json
    $r = Invoke-RestMethod -Uri "$BaseUrl/v1/trips" -Method Post -Headers $Headers -Body $body -ContentType "application/json"
    $script:TripId = $r.trip_id
    $r
}
Test-Step "GET /v1/trips/{id}" {
    if (-not $TripId) { throw "No trip id" }
    Invoke-RestMethod -Uri "$BaseUrl/v1/trips/$TripId" -Method Get -Headers $Headers
}
Test-Step "GET /v1/trips/{id}/risk" {
    if (-not $TripId) { throw "No trip id" }
    Invoke-RestMethod -Uri "$BaseUrl/v1/trips/$TripId/risk" -Method Get -Headers $Headers
}
Test-Step "POST /v1/trips/{id}/rescan" {
    if (-not $TripId) { throw "No trip id" }
    Invoke-RestMethod -Uri "$BaseUrl/v1/trips/$TripId/rescan" -Method Post -Headers $Headers
}
Test-Step "POST /v1/trips/{id}/cancel" {
    if (-not $TripId) { throw "No trip id" }
    Invoke-RestMethod -Uri "$BaseUrl/v1/trips/$TripId/cancel" -Method Post -Headers $Headers
}

# ============================================================
# 5. SOS / INCIDENTS
# ============================================================
$IncidentId = $null
Test-Step "POST /v1/sos -- full dispatch pipeline" {
    $sosBody = @{
        user_id = $TokenUserId
        device_id = "3fa85f64-5717-4562-b3fc-2c963f66afa6"
        trigger_type = "manual"; incident_type = "drowning_risk"; severity = "high"
        beach_id = $BeachId; activity_type = "swimming"
        location = @{ lat = 13.05; lng = 80.28; accuracy_m = 5; source = "gps" }
        hazard_context = @{ alert_flags = @() }; device_state = @{ offline = $false }
        contacts = @(); media = @(); notes = "e2e automated test"
    } | ConvertTo-Json -Depth 5
    $r = Invoke-RestMethod -Uri "$BaseUrl/v1/sos" -Headers $Headers -Method Post -Body $sosBody -ContentType "application/json"
    if ($r.incident_id) { $script:IncidentId = $r.incident_id }
    $r
}
Test-Step "GET /v1/incidents/{id}" {
    if (-not $IncidentId) { throw "No incident id" }
    Invoke-RestMethod -Uri "$BaseUrl/v1/incidents/$IncidentId" -Method Get -Headers $Headers
}
Test-Step "GET /v1/incidents/{id}/status" {
    if (-not $IncidentId) { throw "No incident id" }
    Invoke-RestMethod -Uri "$BaseUrl/v1/incidents/$IncidentId/status" -Method Get -Headers $Headers
}
Test-Step "POST /v1/incidents/{id}/media" {
    if (-not $IncidentId) { throw "No incident id" }
    $body = @{ type = "photo"; url = "https://example.com/f.jpg" } | ConvertTo-Json
    Invoke-RestMethod -Uri "$BaseUrl/v1/incidents/$IncidentId/media" -Method Post -Headers $Headers -Body $body -ContentType "application/json"
}
Test-Step "POST /v1/incidents/{id}/ack" {
    if (-not $IncidentId) { throw "No incident id" }
    $body = @{ target_type = "112"; target_name = "e2e-responder"; ack_status = "received" } | ConvertTo-Json
    Invoke-RestMethod -Uri "$BaseUrl/v1/incidents/$IncidentId/ack" -Method Post -Headers $Headers -Body $body -ContentType "application/json"
}

# ============================================================
# 6. EMERGENCY SHARE
# ============================================================
$ShareId = $null
Test-Step "POST /v1/emergency/share/start" {
    if (-not $IncidentId) { throw "No incident id (needs SOS to succeed first)" }
    $body = @{ incident_id = $IncidentId; share_with = @($TokenUserId); share_live_location = $true; share_route = $true } | ConvertTo-Json
    $r = Invoke-RestMethod -Uri "$BaseUrl/v1/emergency/share/start" -Method Post -Headers $Headers -Body $body -ContentType "application/json"
    $script:ShareId = $r.share_session_id
    $r
}
Test-Step "GET /v1/emergency/share/{id}" {
    if (-not $ShareId) { throw "No share id" }
    Invoke-RestMethod -Uri "$BaseUrl/v1/emergency/share/$ShareId" -Method Get -Headers $Headers
}
Test-Step "POST /v1/emergency/share/stop" {
    if (-not $ShareId) { throw "No share id" }
    $body = @{ share_session_id = $ShareId } | ConvertTo-Json
    Invoke-RestMethod -Uri "$BaseUrl/v1/emergency/share/stop" -Method Post -Headers $Headers -Body $body -ContentType "application/json"
}

# ============================================================
# 7. NOTIFICATIONS
# ============================================================
Test-Step "GET /v1/notifications" { Invoke-RestMethod -Uri "$BaseUrl/v1/notifications" -Method Get -Headers $Headers }
Test-Step "POST /v1/notifications/{id}/read" {
    $body = "00000000-0000-0000-0000-000000000000"
    Invoke-RestMethod -Uri "$BaseUrl/v1/notifications/$body/read" -Method Post -Headers $Headers
}

# ============================================================
# 8. OFFLINE SYNC
# ============================================================
Test-Step "GET /v1/sync/bundle" {
    $syncHeaders = $Headers.Clone()
    $syncHeaders["x-device-id"] = "e2e-device-1"
    Invoke-RestMethod -Uri "$BaseUrl/v1/sync/bundle" -Method Get -Headers $syncHeaders
}
Test-Step "POST /v1/sync/sos-queue" {
    $body = @{
        device_id = "e2e-device-1"
        packets = @(@{
            client_incident_id = [guid]::NewGuid().ToString()
            user_id = $TokenUserId
            device_id = "e2e-device-1"
            created_at_client = (Get-Date).ToString("o")
            lat = 13.05; lng = 80.28
            source_of_location = "gps"
            incident_type = "drowning_risk"; severity = "high"
            offline_flag = $true
        })
    } | ConvertTo-Json -Depth 5
    Invoke-RestMethod -Uri "$BaseUrl/v1/sync/sos-queue" -Method Post -Headers $Headers -Body $body -ContentType "application/json"
}

# ============================================================
# 9. SAFEZONE
# ============================================================
$GuidanceId = $null
Test-Step "POST /v1/safezone/guidance" {
    $body = @{ lat = 13.05; lng = 80.28; beach_id = $BeachId } | ConvertTo-Json
    $r = Invoke-RestMethod -Uri "$BaseUrl/v1/safezone/guidance" -Method Post -Headers $Headers -Body $body -ContentType "application/json"
    $script:GuidanceId = $r.guidance_id
    $r
}
Test-Step "POST /v1/safezone/guidance/{id}/recompute" {
    if (-not $GuidanceId) { throw "No guidance id" }
    $body = @{ lat = 13.06; lng = 80.29; reason = "user_moved" } | ConvertTo-Json
    Invoke-RestMethod -Uri "$BaseUrl/v1/safezone/guidance/$GuidanceId/recompute" -Method Post -Headers $Headers -Body $body -ContentType "application/json"
}
Test-Step "GET /v1/safezone/guidance/active" {
    Invoke-RestMethod -Uri "$BaseUrl/v1/safezone/guidance/active" -Method Get -Headers $Headers
}
Test-Step "POST /v1/safezone/guidance/{id}/share" {
    if (-not $GuidanceId) { throw "No guidance id" }
    Invoke-RestMethod -Uri "$BaseUrl/v1/safezone/guidance/$GuidanceId/share" -Method Post -Headers $Headers
}

# ============================================================
# 10. TRACKING
# ============================================================
$SessionId = $null
Test-Step "POST /v1/tracking/sessions" {
    if (-not $IncidentId) { throw "No incident id (tracking needs an incident_report_id)" }
    $body = @{ incident_report_id = $IncidentId } | ConvertTo-Json
    $r = Invoke-RestMethod -Uri "$BaseUrl/v1/tracking/sessions" -Method Post -Headers $Headers -Body $body -ContentType "application/json"
    $script:SessionId = $r.session_id
    $r
}
Test-Step "POST /v1/tracking/sessions/{id}/ping" {
    if (-not $SessionId) { throw "No session id" }
    $body = @{ lat = 13.05; lng = 80.28 } | ConvertTo-Json
    Invoke-RestMethod -Uri "$BaseUrl/v1/tracking/sessions/$SessionId/ping" -Method Post -Headers $Headers -Body $body -ContentType "application/json"
}
Test-Step "GET /v1/tracking/sessions/{id}" {
    if (-not $SessionId) { throw "No session id" }
    Invoke-RestMethod -Uri "$BaseUrl/v1/tracking/sessions/$SessionId" -Method Get -Headers $Headers
}
Test-Step "PATCH /v1/tracking/sessions/{id}/status" {
    if (-not $SessionId) { throw "No session id" }
    $body = @{ status = "active" } | ConvertTo-Json
    Invoke-RestMethod -Uri "$BaseUrl/v1/tracking/sessions/$SessionId/status" -Method Patch -Headers $Headers -Body $body -ContentType "application/json"
}
Test-Step "POST /v1/tracking/sessions/{id}/stop" {
    if (-not $SessionId) { throw "No session id" }
    $body = @{ reason = "manual_stop" } | ConvertTo-Json
    Invoke-RestMethod -Uri "$BaseUrl/v1/tracking/sessions/$SessionId/stop" -Method Post -Headers $Headers -Body $body -ContentType "application/json"
}

# ============================================================
# 11. ADMIN
# ============================================================
Test-Step "POST /v1/admin/beaches" {
    $body = @{ name = "E2E Test Beach"; lat = 13.0; lng = 80.2 } | ConvertTo-Json
    Invoke-RestMethod -Uri "$BaseUrl/v1/admin/beaches" -Method Post -Headers $Headers -Body $body -ContentType "application/json"
}
Test-Step "GET /v1/admin/beaches/{id}/validate-geometry" {
    if (-not $BeachId) { throw "No beach id" }
    Invoke-RestMethod -Uri "$BaseUrl/v1/admin/beaches/$BeachId/validate-geometry" -Method Get -Headers $Headers
}
Test-Step "POST /v1/admin/activity-thresholds" {
    $body = @{ activity_type = "swimming"; max_wave_height_m = 2 } | ConvertTo-Json
    Invoke-RestMethod -Uri "$BaseUrl/v1/admin/activity-thresholds" -Method Post -Headers $Headers -Body $body -ContentType "application/json"
}
Test-Step "POST /v1/admin/jurisdictions" {
    $body = @{ name = "E2E Jurisdiction"; authority_type = "coast_guard" } | ConvertTo-Json
    Invoke-RestMethod -Uri "$BaseUrl/v1/admin/jurisdictions" -Method Post -Headers $Headers -Body $body -ContentType "application/json"
}
Test-Step "POST /v1/admin/hospitals" {
    $body = @{ name = "E2E Hospital"; lat = 13.0; lng = 80.2 } | ConvertTo-Json
    Invoke-RestMethod -Uri "$BaseUrl/v1/admin/hospitals" -Method Post -Headers $Headers -Body $body -ContentType "application/json"
}
Test-Step "POST /v1/admin/safe-zones" {
    $body = @{ name = "E2E Safe Zone"; lat = 13.0; lng = 80.2 } | ConvertTo-Json
    Invoke-RestMethod -Uri "$BaseUrl/v1/admin/safe-zones" -Method Post -Headers $Headers -Body $body -ContentType "application/json"
}
Test-Step "GET /v1/admin/incidents" { Invoke-RestMethod -Uri "$BaseUrl/v1/admin/incidents" -Method Get -Headers $Headers }
Test-Step "GET /v1/admin/incidents/{id}/acknowledgements" {
    if (-not $IncidentId) { throw "No incident id" }
    Invoke-RestMethod -Uri "$BaseUrl/v1/admin/incidents/$IncidentId/acknowledgements" -Method Get -Headers $Headers
}
Test-Step "GET /v1/admin/metrics/response-latency" {
    Invoke-RestMethod -Uri "$BaseUrl/v1/admin/metrics/response-latency" -Method Get -Headers $Headers
}
Test-Step "POST /v1/admin/risk-rules/tune" {
    $body = @{ rule = "wave_height"; value = 2 } | ConvertTo-Json
    Invoke-RestMethod -Uri "$BaseUrl/v1/admin/risk-rules/tune" -Method Post -Headers $Headers -Body $body -ContentType "application/json"
}
Test-Step "POST /v1/admin/logs/export" { Invoke-RestMethod -Uri "$BaseUrl/v1/admin/logs/export" -Method Post -Headers $Headers }

# ============================================================
# 12. AUDIT / ANALYTICS
# ============================================================
Test-Step "GET /v1/admin/analytics/response-time" { Invoke-RestMethod -Uri "$BaseUrl/v1/admin/analytics/response-time" -Method Get -Headers $Headers }
Test-Step "GET /v1/admin/analytics/alert-accuracy" { Invoke-RestMethod -Uri "$BaseUrl/v1/admin/analytics/alert-accuracy" -Method Get -Headers $Headers }
Test-Step "GET /v1/admin/analytics/missed-warnings" { Invoke-RestMethod -Uri "$BaseUrl/v1/admin/analytics/missed-warnings" -Method Get -Headers $Headers }
Test-Step "GET /v1/admin/analytics/threshold-recommendations" { Invoke-RestMethod -Uri "$BaseUrl/v1/admin/analytics/threshold-recommendations" -Method Get -Headers $Headers }

# ============================================================
# 13. INTERNAL (ingestion / risk recompute) -- needs internal key
# ============================================================
$IntHeaders = @{}
if ($InternalKey) { $IntHeaders = @{ "X-Internal-Key" = $InternalKey } }
Test-Step "POST /internal/ingest/incois" { Invoke-RestMethod -Uri "$BaseUrl/internal/ingest/incois" -Method Post -Headers $IntHeaders }
Test-Step "POST /internal/ingest/sachet" { Invoke-RestMethod -Uri "$BaseUrl/internal/ingest/sachet" -Method Post -Headers $IntHeaders }
Test-Step "POST /internal/recompute/risk" { Invoke-RestMethod -Uri "$BaseUrl/internal/recompute/risk" -Method Post -Headers $IntHeaders }

# ============================================================
# 14. INTERNAL DISPATCH ROUTER
# ============================================================
Test-Step "POST /internal/router/... (dispatch #1)" {
    Invoke-RestMethod -Uri "$BaseUrl/internal/router/dispatch" -Method Post -Headers $IntHeaders
}
Test-Step "GET /internal/router/... (status)" {
    Invoke-RestMethod -Uri "$BaseUrl/internal/router/status" -Method Get -Headers $IntHeaders
}

# ============================================================
# 15. HOSPITAL ROUTER
# ============================================================
$RouteId = $null
Test-Step "POST /internal/hospital-router/dispatch" {
    $body = @{ incident_id = $IncidentId } | ConvertTo-Json
    $r = Invoke-RestMethod -Uri "$BaseUrl/internal/hospital-router/dispatch" -Method Post -Headers $IntHeaders -Body $body -ContentType "application/json"
    $script:RouteId = $r.route_id
    $r
}
Test-Step "POST /hospital-router/routes/{id}/ack" {
    if (-not $RouteId) { throw "No route id" }
    Invoke-RestMethod -Uri "$BaseUrl/hospital-router/routes/$RouteId/ack" -Method Post -Headers $Headers
}

# ============================================================
# 16. AUTHORITY ROUTER
# ============================================================
$AuthRouteId = $null
Test-Step "POST /internal/authority-router/dispatch" {
    $body = @{ incident_id = $IncidentId } | ConvertTo-Json
    $r = Invoke-RestMethod -Uri "$BaseUrl/internal/authority-router/dispatch" -Method Post -Headers $IntHeaders -Body $body -ContentType "application/json"
    $script:AuthRouteId = $r.route_id
    $r
}
Test-Step "POST /authority-router/routes/{id}/ack" {
    if (-not $AuthRouteId) { throw "No route id" }
    Invoke-RestMethod -Uri "$BaseUrl/authority-router/routes/$AuthRouteId/ack" -Method Post -Headers $Headers
}

# ============================================================
# 17. DB SANITY CHECKS
# ============================================================
Test-Step "DB: hospitals seeded, no test rows" {
    $count = Psql-Scalar "SELECT count(*) FROM hospitals;"
    $testCount = Psql-Scalar "SELECT count(*) FROM hospitals WHERE name ILIKE '%test%';"
    "hospitals=$count, test_rows=$testCount"
}
Test-Step "DB: jurisdictions valid authority_type" {
    $bad = Psql-Scalar "SELECT count(*) FROM jurisdictions WHERE authority_type = 'police';"
    if ([int]$bad -ne 0) { throw "Found $bad invalid rows" }
    "OK"
}
Test-Step "DB: no duplicate beach names" {
    $dupe = Psql-Scalar "SELECT count(*) FROM (SELECT name FROM beaches GROUP BY name HAVING count(*) > 1) t;"
    if ([int]$dupe -ne 0) { throw "$dupe duplicate beach names" }
    "OK"
}
Test-Step "DB: safe_zones no test rows" {
    $testZone = Psql-Scalar "SELECT count(*) FROM safe_zones WHERE name ILIKE '%test%';"
    if ([int]$testZone -ne 0) { throw "$testZone test rows found" }
    "OK"
}

# ============================================================
# 18. INGESTION CODE CHECK
# ============================================================
Test-Step "INCOIS connector disabled in build_connectors()" {
    $match = Select-String -Path "app\services\ingestion_service.py" -Pattern "def build_connectors" -Context 0,6 | Select-Object -Last 1
    $block = ($match.Context.PostContext -join "`n")
    if ($block -match "IncoisConnector\(") { throw "IncoisConnector still active" }
    "confirmed disabled"
}

# ============================================================
# SUMMARY
# ============================================================
Write-Host "`n`n================= SUMMARY =================" -ForegroundColor Magenta
$Results | Format-Table -AutoSize
$failCount = ($Results | Where-Object { $_.Status -ne "PASS" }).Count
$color = if ($failCount -eq 0) { "Green" } else { "Yellow" }
Write-Host "$($Results.Count) total | $($Results.Count - $failCount) PASSED | $failCount SKIPPED/FAILED" -ForegroundColor $color