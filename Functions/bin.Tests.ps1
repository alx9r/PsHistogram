Import-Module -Force PsHistogram

Describe Get-Extremes {
    It 'correctly reports extremes' {
        $r = 1,2,3,4,5 |
            Get-Extremes {$_}
        $r.Minimum | Should be 1
        $r.Maximum | Should be 5
    }
    It 'correctly evaluates scriptblock' {
        $r = -1,2,3,4,-5 |
            Get-Extremes {$_*$_}
        $r.Minimum | Should be 1
        $r.Maximum | Should be 25
    }
}
InModuleScope PsHistogram {
    Describe 'Get-BinDomains (strategy selection)' {
        Context 'provided as parameter' {
            Mock Get-BinDomainsStrategy -Verifiable
            Mock Get-BinDomainsNumerical -Verifiable
            It 'selects strategy.' {
                $splat = @{
                    Minimum = 100
                    Maximum = 1000
                    Maxbins = 10
                }
                Get-BinDomains @splat -Strategy numeric

                Assert-MockCalled Get-BinDomainsStrategy -Times 0
                Assert-MockCalled Get-BinDomainsNumerical -Times 1
            }
        }
        Context 'numeric' {
            Mock Get-BinDomainsStrategy -Verifiable {'numeric'}
            Mock Get-BinDomainsNumerical -Verifiable
            It 'selects strategy.' {
                $splat = @{
                    Minimum = 100
                    Maximum = 1000
                    Maxbins = 10
                }
                Get-BinDomains @splat

                Assert-MockCalled Get-BinDomainsStrategy -Times 1
                Assert-MockCalled Get-BinDomainsNumerical -Times 1
            }
        }
        Context 'DateTime' {
            Mock Get-BinDomainsStrategy -Verifiable {'DateTime'}
            Mock Get-BinDomainsDateTime -Verifiable
            It 'selects strategy.' {
                $splat = @{
                    Minimum = [datetime]::Parse('2000-01-01')
                    Maximum = [datetime]::Parse('2000-01-02')
                    Maxbins = 10
                }
                Get-BinDomains @splat

                Assert-MockCalled Get-BinDomainsStrategy -Times 1
                Assert-MockCalled Get-BinDomainsDateTime -Times 1
            }
        }
    }
}
Describe Add-ItemsToBins {
    $splat = @{
        Minimum = 100
        Maximum = 1000
        Maxbins = 10
    }
    $bins = Get-BinDomains @splat
    It 'correctly adds first value.' {
        100 | Add-ItemsToBins {$_} $bins
        $bins[0].Items[0] | Should be 100
        $bins[1].Items | Should beNullOrEmpty
    }
    It 'correctly adds second value.' {
        100 | Add-ItemsToBins {$_} $bins
        $bins[0].Items[1] | Should be 100
        $bins[1].Items | Should beNullOrEmpty
    }
    It 'correctly adds upperbound value.' {
        189 | Add-ItemsToBins {$_} $bins
        $bins[0].Items[2] | Should be 189
        $bins[1].Items | Should beNullOrEmpty
    }
    It 'correctly adds lowerbound value.' {
        190 | Add-ItemsToBins {$_} $bins
        $bins[1].Items[0] | Should be 190
    }
}
Describe Add-AggregateValue {
    $splat = @{
        Minimum = 100
        Maximum = 1000
        Maxbins = 10
    }
    $bins = Get-BinDomains @splat
    100,101,102,103 | Add-ItemsToBins {$_} $bins
    It 'correctly calculates aggregate value.' {
        $bins[0] |
            Add-AggregateValueToBin {
                $_ |
                    Measure -Sum |
                    % Sum
            }
        $bins[0].Aggregate | Should be 406
    }
}
Describe Get-Bins {
    $data = @(
        @(4,5),
        @(4,5),
        @(1,10),
        @(1,10),
        @(1,10),
        @(3,10),
        @(9,20),
        @(10,1)
    ) |
        % {
            New-Object psobject -Property @{
                x = $_[0]
                y = $_[1]
                date = [datetime]::Parse("2000-$($_[0])-01")
            }
        }
    It 'outputs a bin vector.' {
        $splat = @{
            Independent = {$_.x}
            Dependent   = {$_.y}
            Aggregate   = {$_.y | Measure -Sum | % Sum }
            MaxBins     = 9
        }
        $r = $data | Get-Bins @splat

        $r[0].LowerBound = 1
        $r[0].UpperBound = 2
        $r[0].Aggregate  = 30
        $r[8].Interval | Should be '[9.00,10.00)'
        $r[8].Aggregate | Should be 20
    }
}
Describe Get-BinDomainsStrategy {
    It 'works for single objects.' {
        $r = Get-BinDomainsStrategy 1
        $r | Should be 'numeric'
    }
    It 'selects numeric for integers.' {
        $r = Get-BinDomainsStrategy  1,2,3,4,5
        $r | Should be 'numeric'
    }
    It 'selects numeric for a mix of integers and floats.' {
        $r = Get-BinDomainsStrategy 1,2,3,4,5.0
        $r | Should be 'numeric'
    }
    It 'throws for mix of integers and dates.' {
        $data = 1,2,3,4,[datetime]::Parse('2000-01-01')

        { Get-BinDomainsStrategy $data } |
            Should throw 'Independent values contains a mix of DateTime and other types.'
    }
    It 'throws for hashtable.' {
        try
        {
            Get-BinDomainsStrategy 1,2,3,4,@{a=1}
        }
        catch [System.ArgumentException]
        {
            $threw = $true
            $_.Exception | Should match 'Independent values contains items that are not IComparable.'
        }
        $threw | Should be $true
    }
    It 'selects DateTime.' {
        $r = Get-BinDomainsStrategy ([datetime]::Parse('2000-01-01'),[datetime]::Parse('2000-01-01'))
        $r | Should be 'DateTime'
    }
}
