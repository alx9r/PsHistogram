Import-Module PsHistogram -Force

$df = 'yyyy-MM-dd HH:mm:ss.ffff'
Describe timezone {
    It 'test runner is in acceptable timezone' {
        [System.TimeZone]::CurrentTimeZone.StandardName -in 'Pacific Standard Time','Greenwich Standard Time' |
            Should be $true
    }
}
Describe 'make histogram data' {
    $records = "$($PSCommandPath | Split-Path -Parent)\..\Resources\sample1.xml" |
        Resolve-Path |
        Import-Clixml
    It 'correctly converts sample (months)' {
        $splat = @{
            Independent = {$_.Time}
            Dependent   = {$_}
            Aggregate   = {$_ | Measure | % Count }
            MaxBins     = 4
        }
        $r = $records | Get-Bins @splat -Strategy 'DateTime'

        $r.Count | Should be '4'
        $r[0].Interval | Should be '2016-02'
        $r[0].Aggregate | Should be '5'
        $r[1].Aggregate | Should be '67'
        $r[2].Aggregate | Should be '146'
        $r[3].Aggregate | Should be '65'
    }
    It 'correctly converts sample (weeks)' {
        $splat = @{
            Independent = {$_.Time}
            Dependent   = {$_}
            Aggregate   = {$_ | Measure | % Count }
            MaxBins     = 30
        }
        $r = $records | Get-Bins @splat -Strategy 'DateTime'

        $r.Count | Should be '11'
        $r[0].Interval | Should be '2016W09'
        $r[0].Aggregate | Should be '5'
        $r[1].Aggregate | Should be '0'

        if ([System.TimeZone]::CurrentTimeZone.StandardName -eq 'Pacific Standard Time')
        {
            $r[9].Aggregate | Should be '46'
        }
        else
        {
            # AppVeyor uses Greenwich Standard Time

            $r[9].Aggregate | Should be '52'
        }
    }
}
