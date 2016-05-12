Import-Module PsHistogram -Force

Describe ConvertTo-Histogram {
    $bins = @(
        @('a',1),
        @('bb',3),
        @('c',6),
        @('ddd',3),
        @('e',1)
    ) |
        % {
            New-Object psobject -Property @{
                Interval = $_[0]
                Aggregate = $_[1]
            }
        }
    It 'converts bins to histogram data.' {
        $r = $bins | ConvertTo-Histogram

        $r.Range.Minimum | Should be 1
        $r.Range.Maximum| Should be 6
        $r.Bins.Count | Should be 5
        $r.IntervalLabelLength | Should be 3
    }
}
Describe Write-Histogram {
    $histogram = @(
        @('a',1),
        @('b',3),
        @('c',6),
        @('d',3),
        @('e',1)
    ) |
        % {
            New-Object psobject -Property @{
                Interval = $_[0]
                Aggregate = $_[1]
            }
        } |
        ConvertTo-Histogram
    It 'does.' {
        $r = $histogram | Write-Histogram -Width 12 -ToString
        $r[0] | Should be '  1        6'
        $r[1] | Should be 'a ----------'
        $r[2] | Should be 'b XXXX------'
        $r[3] | Should be 'c XXXXXXXXXX'
        $r[4] | Should be 'd XXXX------'
        $r[5] | Should be 'e ----------'
    }
}
Describe Get-BarLength {
    Context '0 to 10' {
        $splat = @{
            Range = @{
                Minimum = 0
                Maximum = 10
            }
            MaxLength = 10
        }
        foreach ($value in 0,1,9,10)
        {
            It "value = $value" {
                $splat.Value = $value
                $r = Get-BarLength @splat

                $r | Should be $value
            }
        }
    }
    Context '10 to 20' {
        $splat = @{
            Range = @{
                Minimum = 10
                Maximum = 20
            }
            MaxLength = 10
        }
        foreach (
            $pair in @(
                @(0,0),
                @(9,0),
                @(10,0),
                @(11,1),
                @(19,9),
                @(20,10)
            )
        )
        {
            $in = $pair[0]
            $out = $pair[1]
            It "value = $in" {
                $splat.Value = $in
                $r = Get-BarLength @splat

                $r | Should be $out
            }
        }
    }
    Context '10 to 21' {
        $splat = @{
            Range = @{
                Minimum = 10
                Maximum = 21
            }
            MaxLength = 10
        }
        foreach (
            $pair in @(
                @(10,0),
                @(14,4),
                @(15,5),
                @(16,5),
                @(17,6),
                @(21,10)
            )
        )
        {
            $in = $pair[0]
            $out = $pair[1]
            It "value = $in" {
                $splat.Value = $in
                $r = Get-BarLength @splat

                $r | Should be $out
            }
        }
    }
}
