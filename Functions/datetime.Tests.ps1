Import-Module PsHistogram -Force

$df = 'yyyy-MM-dd HH:mm:ss.ffff'
Describe 'Get-BinDomains (DateTime)' {
    It 'correctly produces bins (month)' {
        $splat = @{
            Minimum = [DateTime]::Parse('2000-01-01')
            Maximum = [DateTime]::Parse('2000-12-31')
            Maxbins = 20
            Strategy = 'DateTime'
        }
        $r = Get-BinDomains @splat

        $r.Count | Should be 12
        $r[0].LowerBound.ToString($df) | Should be '2000-01-01 00:00:00.0000'
        $r[0].UpperBound.ToString($df) | Should be '2000-02-01 00:00:00.0000'
        $r[0].Interval | Should be '2000-01'
        $r[11].LowerBound.ToString($df) | Should be '2000-12-01 00:00:00.0000'
        $r[11].UpperBound.ToString($df) | Should be '2001-01-01 00:00:00.0000'
    }
    It 'correctly produces bins (weeks) (1)' {
        $splat = @{
            Minimum = [DateTime]::Parse('2000-01-01')
            Maximum = [DateTime]::Parse('2000-02-01')
            Maxbins = 20
            Strategy = 'DateTime'
        }
        $r = Get-BinDomains @splat

        $r.Count | Should be 6
        $r[0].LowerBound.ToString($df) | Should be '1999-12-26 00:00:00.0000'
        $r[0].UpperBound.ToString($df) | Should be '2000-01-02 00:00:00.0000'
        $r[0].Interval | Should be '2000W01'
        $r[5].LowerBound.ToString($df) | Should be '2000-01-30 00:00:00.0000'
        $r[5].UpperBound.ToString($df) | Should be '2000-02-06 00:00:00.0000'
    }
    It 'correctly produces bins (weeks) (2)' {
        $splat = @{
            Minimum = [DateTime]::Parse('2016-01-28 14:30:12.0455')
            Maximum = [DateTime]::Parse('2016-05-14 04:28:50.8995')
            Maxbins = 30
            Strategy = 'DateTime'
        }
        $r = Get-BinDomains @splat

        $r.Count | Should be 16
        $r[0].LowerBound.ToString($df) | Should be '2016-01-24 00:00:00.0000'
        $r[0].UpperBound.ToString($df) | Should be '2016-01-31 00:00:00.0000'
        $r[0].Interval | Should be '2016W05'
        $r[15].LowerBound.ToString($df) | Should be '2016-05-08 00:00:00.0000'
        $r[15].UpperBound.ToString($df) | Should be '2016-05-15 00:00:00.0000'
    }
    It 'correctly produces bins (hours)' {
        $splat = @{
            Minimum = [DateTime]::Parse('2016-05-16 11:41:53.7898')
            Maximum = [DateTime]::Parse('2016-05-16 15:29:22.7822')
            Maxbins = 30
            Strategy = 'DateTime'
        }
        $r = Get-BinDomains @splat

        $r.Count | Should be 5
        $r[0].LowerBound.ToString($df) | Should be '2016-05-16 11:00:00.0000'
        $r[0].UpperBound.ToString($df) | Should be '2016-05-16 12:00:00.0000'
        $r[0].Interval | Should be '11'
    }
}
Describe 'Get-QuantizedDateTime' {
    $tests = @(
        @('1999-12-31','ceiling','week','2000-01-02 00:00:00.0000'),
        @('2016-01-24 14:30:12.0455','floor','week','2016-01-24 00:00:00.0000'),
        @('2000-01-01', 'ceiling', 'month', '2000-02-01 00:00:00.0000'),
        @('2000-01-31', 'floor',   'month', '2000-01-01 00:00:00.0000'),
        @('2000-01-10',    'ceiling', 'year',  '2001-01-01 00:00:00.0000'),
        @('2000-01-10',    'floor',   'year',  '2000-01-01 00:00:00.0000'),
        @('2000-01-10 10:00', 'ceiling', 'day', '2000-01-11 00:00:00.0000'),
        @('2000-01-10 10:01:5.1234', 'ceiling', 'second', '2000-01-10 10:01:06.0000'),
        @('2000-01-01','floor','week','1999-12-26 00:00:00.0000')
    ) |
        % {
            New-Object psobject -Property @{
                Value  = $_[0]
                Method = $_[1]
                Unit   = $_[2]
                Output = $_[3]
            }
        }
    foreach ($test in $tests)
    {

        It "produces correct result $($test.Value) $($test.Method) $($test.Unit)" {
            $r = $test | Get-QuantizedDateTime
            $r.ToString($df) | Should be $test.Output
        }
    }
}
Describe 'Get-DateTimeIntervalLabel' {
    $tests = @(
        @('2000-01-01','year','2000'),
        @('2000-01-01','month','2000-01'),
        @('2000-01-01','day','01-01'),
        @('2000-01-01 10:00','hour','10'),
        @('2000-01-01 10:20:00','minute','10:20'),
        @('2000-01-01 10:30:20','second','30:20'),
        @('2000-01-01','week','2000W01')
    ) |
        % {
            New-Object psobject -Property @{
                LowerBound  = $_[0]
                Unit   = $_[1]
                Output = $_[2]
            }
        }
    foreach ($test in $tests)
    {
        It "produces correct result $($test.LowerBound) $($test.Unit)" {
            $r = $test | Get-DateTimeIntervalLabel
            $r | Should be $test.Output
        }
    }
}
Describe 'DateTime environment assumptions' {
    $i = [System.Globalization.DateTimeFormatInfo]::InvariantInfo
    It 'has correct properties' {
        $i.Calendar -is [System.Globalization.GregorianCalendar] | Should be $true
        $i.FirstDayOfWeek | Should be 'Sunday'
        $i.CalendarWeekRule | Should be 'FirstDay'
    }
}
Describe 'Get-WeekOfYear' {
    $tests = @(
        @('2000-01-01','2000','1'),
        @('2000-01-02','2000','2'),
        @('1999-12-31','2000','1'),
        @('1999-12-25','1999','52')
    ) |
        % {
            New-Object psobject -Property @{
                Date   = $_[0]
                Year   = $_[1]
                WeekNum= $_[2]
            }
        }
    foreach ($test in $tests)
    {
        It "produces correct result $($test.Date)" {
            $r = $test | Get-WeekOfYear
            $r.WeekNum | Should be $test.WeekNum
            $r.Year | Should be $test.Year
        }
    }
}
