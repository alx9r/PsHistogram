Import-Module PsHistogram -Force

$df = 'yyyy-MM-dd HH:mm:ss.ffff'
Describe 'make histogram data' {
    $records = "$($PSCommandPath | Split-Path -Parent)\..\Resources\sample1.xml" |
        Resolve-Path |
        Import-Clixml
    It 'sample data matches assumptions.' {
        $records.Count | Should be 283
        $extremes = $records | Get-Extremes {$_.Time}

        $extremes.Minimum.ToString($df) | Should be '2016-02-22 16:48:47.1630'
        $extremes.Maximum.ToString($df) | Should be '2016-05-07 03:29:41.8263'
    }
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

        $i=0
        foreach ( $record in $r )
        {
            Write-Host "==== $i ===="
            Write-Host $record
            $i++
        }

        $r.Count | Should be '10'
        $r[0].Interval | Should be '2016W09'
        $r[0].Aggregate | Should be '5'
        $r[1].Aggregate | Should be '0'
        $r[9].Aggregate | Should be '46'
    }
}
