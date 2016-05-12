Import-Module PsHistogram -Force

Describe 'Get-BinDomains (numeric)' {
    It 'correctly produces bins' {
        $splat = @{
            Minimum = 100
            Maximum = 1000
            Maxbins = 10
        }
        $r = Get-BinDomains @splat

        $r.Count | Should be 10
        $r[0].LowerBound | Should be 100
        $r[0].UpperBound | Should be 190
        $r[0].Interval | Should be '[100.00,190.00)'
        $r[9].LowerBound | Should be 910
        $r[9].UpperBound | Should be 1000
    }
    It 'throws when maximum is not less than minimum' {
        $splat = @{
            Minimum = 1
            Maximum = 1
            Maxbins = 10
        }
        { Get-BinDomains @splat } |
            Should throw 'Maximum must be greater than Minimum.'
    }
}
Describe 'Get-NumericIntervalLabel' {
    $tests = @(
        @(1,2,'[1.00,2.00)'),
        @((1/3),(2/3),'[0.33,0.67)'),
        @((1/30),(2/30),'[0.03,0.07)')
    ) |
        % {
            New-Object psobject -Property @{
                LowerBound  = $_[0]
                UpperBound   = $_[1]
                Output = $_[2]
            }
        }
    foreach ($test in $tests)
    {
        It "produces correct result $($test.Output)" {
            $r = $test | Get-NumericIntervalLabel
            $r | Should be $test.Output
        }
    }
}
