Import-Module PsHistogram -Force

Describe 'make histogram data' {
    It 'correctly converts sample (months)' {
        $records = "$($PSCommandPath | Split-Path -Parent)\..\Resources\sample1.xml" |
            Resolve-Path |
            Import-Clixml
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
        $records = "$($PSCommandPath | Split-Path -Parent)\..\Resources\sample1.xml" |
            Resolve-Path |
            Import-Clixml
        $splat = @{
            Independent = {$_.Time}
            Dependent   = {$_}
            Aggregate   = {$_ | Measure | % Count }
            MaxBins     = 30
        }
        $r = $records | Get-Bins @splat -Strategy 'DateTime'

        $r.Count | Should be '10'
        $r[0].Interval | Should be '2016W09'
        $r[0].Aggregate | Should be '5'
        $r[1].Aggregate | Should be '0'
        $r[9].Aggregate | Should be '46'
    }
}
