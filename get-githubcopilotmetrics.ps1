# PowerShell function to call the GitHub Copilot metrics API and return a structured summary.
function Get-GitHubCopilotMetrics {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Organization,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Repository,

        [ValidateNotNullOrEmpty()]
        [string]$Token,

        [datetime]$Since,
        [datetime]$Until,

        [ValidateNotNullOrEmpty()]
        [string]$ApiBaseUrl = 'https://api.github.com',

        [ValidateNotNullOrEmpty()]
        [string]$ApiVersion = '2022-11-28',

        [bool]$Pretty = $true
    )

    $effectiveToken = if ($Token) { $Token } else { $env:GITHUB_TOKEN }
    if (-not $effectiveToken) {
        throw 'GitHub token is required. Pass -Token or set GITHUB_TOKEN.'
    }

    if ($Since -and $Until -and $Since -gt $Until) {
        throw 'Since must be earlier than Until.'
    }

    $headers = @{
        Authorization = "Bearer $effectiveToken"
        Accept = 'application/vnd.github+json'
        'X-GitHub-Api-Version' = $ApiVersion
        'User-Agent' = 'globomantics-robot-fleet-metrics'
    }

    $queryParts = @()
    if ($Since) {
        $queryParts += "since=$([Uri]::EscapeDataString($Since.ToString('o')))"
    }
    if ($Until) {
        $queryParts += "until=$([Uri]::EscapeDataString($Until.ToString('o')))"
    }

    $queryString = if ($queryParts.Count -gt 0) { '?' + ($queryParts -join '&') } else { '' }
    $uri = "$ApiBaseUrl/orgs/$Organization/copilot/metrics$queryString"

    try {
        $raw = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ErrorAction Stop
    } catch {
        throw "GitHub Copilot metrics request failed: $($_.Exception.Message)"
    }

    $items = if ($raw -is [object[]]) {
        $raw
    } elseif ($raw.PSObject.Properties.Name -contains 'items') {
        $raw.items
    } elseif ($raw.PSObject.Properties.Name -contains 'breakdown') {
        $raw.breakdown
    } else {
        @($raw)
    }

    $itemsWithRepoField = $items | Where-Object {
        $_.PSObject.Properties.Name -contains 'repository' -or
        $_.PSObject.Properties.Name -contains 'repo' -or
        $_.PSObject.Properties.Name -contains 'repository_name'
    }

    $repoFilterApplied = $itemsWithRepoField.Count -gt 0
    if ($repoFilterApplied) {
        $filteredItems = $items | Where-Object {
            $repoName = $_.repository
            if (-not $repoName) { $repoName = $_.repo }
            if (-not $repoName) { $repoName = $_.repository_name }
            if (-not $repoName) { return $false }
            $repoSimple = if ($repoName -like '*/*') { $repoName.Split('/')[-1] } else { $repoName }
            $repoName -ieq $Repository -or $repoSimple -ieq $Repository
        }
    } else {
        $filteredItems = $items
    }

    $repoMatchCount = ($filteredItems | Measure-Object).Count

    function Get-MetricValue {
        param (
            [object]$Source,
            [Parameter(Mandatory)]
            [string]$Path
        )

        $current = $Source
        foreach ($segment in $Path -split '\.') {
            if ($null -eq $current) { return 0 }
            $prop = $current.PSObject.Properties[$segment]
            if ($null -eq $prop) { return 0 }
            $current = $prop.Value
        }

        if ($current -is [int] -or $current -is [long] -or $current -is [double] -or $current -is [decimal]) {
            return [decimal]$current
        }

        return 0
    }

    function Get-MetricSum {
        param (
            [object[]]$Values
        )

        $sum = ($Values | Measure-Object -Sum).Sum
        if ($null -eq $sum) { return 0 }
        return [decimal]$sum
    }

    function Get-MetricStats {
        param (
            [object[]]$Values
        )

        $stats = $Values | Measure-Object -Sum -Average -Maximum
        $sum = if ($null -eq $stats.Sum) { 0 } else { [decimal]$stats.Sum }
        $average = if ($null -eq $stats.Average) { 0 } else { [math]::Round([decimal]$stats.Average, 2) }
        $maximum = if ($null -eq $stats.Maximum) { 0 } else { [decimal]$stats.Maximum }

        return [pscustomobject]@{
            sum = $sum
            average = $average
            max = $maximum
        }
    }

    $totalSuggestions = Get-MetricSum @($filteredItems | ForEach-Object {
        Get-MetricValue $_ 'copilot_ide_code_completions.total_suggestions_count'
    })

    $totalAcceptances = Get-MetricSum @($filteredItems | ForEach-Object {
        Get-MetricValue $_ 'copilot_ide_code_completions.total_acceptances_count'
    })

    $totalLinesSuggested = Get-MetricSum @($filteredItems | ForEach-Object {
        Get-MetricValue $_ 'copilot_ide_code_completions.total_lines_suggested'
    })

    $totalLinesAccepted = Get-MetricSum @($filteredItems | ForEach-Object {
        Get-MetricValue $_ 'copilot_ide_code_completions.total_lines_accepted'
    })

    $activeUserStats = Get-MetricStats @($filteredItems | ForEach-Object {
        Get-MetricValue $_ 'total_active_users'
    })

    $engagedUserStats = Get-MetricStats @($filteredItems | ForEach-Object {
        Get-MetricValue $_ 'total_engaged_users'
    })

    $acceptanceRate = if ($totalSuggestions -gt 0) {
        [math]::Round(($totalAcceptances / $totalSuggestions) * 100, 2)
    } else {
        0
    }

    $linesAcceptanceRate = if ($totalLinesSuggested -gt 0) {
        [math]::Round(($totalLinesAccepted / $totalLinesSuggested) * 100, 2)
    } else {
        0
    }

    $result = [pscustomobject]@{
        organization = $Organization
        repository = $Repository
        apiEndpoint = $uri
        filter = [pscustomobject]@{
            repoFilterApplied = $repoFilterApplied
            repoMatchCount = $repoMatchCount
            itemCount = ($items | Measure-Object).Count
        }
        timeframe = [pscustomobject]@{
            since = $Since
            until = $Until
        }
        usage = [pscustomobject]@{
            activeUsers = [pscustomobject]@{
                sum = [long]$activeUserStats.sum
                average = $activeUserStats.average
                max = [long]$activeUserStats.max
            }
            engagedUsers = [pscustomobject]@{
                sum = [long]$engagedUserStats.sum
                average = $engagedUserStats.average
                max = [long]$engagedUserStats.max
            }
        }
        completions = [pscustomobject]@{
            totalSuggestions = [long]$totalSuggestions
            totalAcceptances = [long]$totalAcceptances
            acceptanceRatePercent = $acceptanceRate
            totalLinesSuggested = [long]$totalLinesSuggested
            totalLinesAccepted = [long]$totalLinesAccepted
            lineAcceptanceRatePercent = $linesAcceptanceRate
        }
        raw = $raw
    }

    if ($Pretty) {
        Write-Host ''
        Write-Host "GitHub Copilot Metrics ($Organization/$Repository)"
        Write-Host "Endpoint: $uri"
        if ($Since -or $Until) {
            Write-Host "Timeframe: $($Since) -> $($Until)"
        }
        Write-Host ("Repo filter:      {0} (matched items: {1})" -f $result.filter.repoFilterApplied, $result.filter.repoMatchCount)
        Write-Host ('-' * 60)
        Write-Host ("Active users avg: {0}" -f $result.usage.activeUsers.average)
        Write-Host ("Active users max: {0}" -f $result.usage.activeUsers.max)
        Write-Host ("Engaged users avg: {0}" -f $result.usage.engagedUsers.average)
        Write-Host ("Engaged users max: {0}" -f $result.usage.engagedUsers.max)
        Write-Host ("Suggestions:      {0}" -f $result.completions.totalSuggestions)
        Write-Host ("Acceptances:      {0}" -f $result.completions.totalAcceptances)
        Write-Host ("Accept rate:      {0}%" -f $result.completions.acceptanceRatePercent)
        Write-Host ("Lines suggested:  {0}" -f $result.completions.totalLinesSuggested)
        Write-Host ("Lines accepted:   {0}" -f $result.completions.totalLinesAccepted)
        Write-Host ("Line accept rate: {0}%" -f $result.completions.lineAcceptanceRatePercent)
        Write-Host ''
    }

    return $result
}
# Example invocation (requires GITHUB_TOKEN environment variable)
# Replace dates as needed, or omit for all-time metrics
$org = 'timothywarner-org'
$repo = 'globomantics-robot-fleet'

# Use your system environment variable GITHUB_API_KEY for the token
$token = $env:GITHUB_API_KEY  # Set this in your environment for security

Get-GitHubCopilotMetrics -Organization $org -Repository $repo -Token $token -Pretty $true
