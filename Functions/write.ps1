function ConvertTo-Histogram
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [string]
        $Interval,

        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        $Aggregate
    )
    begin
    {
        $bins = New-Object System.Collections.ArrayList
    }
    process
    {
        $bins.Add((
            New-Object psobject -Property @{
                Interval  = $Interval
                Aggregate = $Aggregate
            }
        )) | Out-Null
    }
    end
    {
        $range = $bins |
            Get-Extremes {$_.Aggregate}
        $labelExtremes = $bins |
            Get-Extremes {$_.Interval.Length}
        New-Object psobject -Property @{
            Bins  = $bins
            Range = $range
            IntervalLabelLength = $labelExtremes.Maximum
        }
    }
}
function Write-Histogram
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        $Range,

        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        $Bins,

        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint32]
        $IntervalLabelLength,

        [Parameter(Position = 1)]
        [string]
        $Width=$Host.UI.RawUI.BufferSize.Width-1,

        [switch]
        $ToString
    )
    process
    {
        # |----------Width------------|
        # |-a-||b||--c--||--d--||--e--|
        #         rhLabel       lhLabel
        # label   XXXXXXX--------------
        #         |--f--||-----g------|

        # calcs

        $lhLabel = $Range.Minimum.ToString()
        $rhLabel = $Range.Maximum.ToString()
        $c = $lhLabel.Length
        $e = $rhLabel.Length
        $a = $IntervalLabelLength
        $b = 1
        $d = $Width-$a-$b-$c-$e

        # heading
        $s = "$(' '*($a+$b))$lhLabel$(' '*$d)$rhLabel"
        if ($ToString)
        {
            $s
        }
        else
        {
            Write-Host $s
        }

        # bins
        foreach ($bin in $Bins)
        {
            $splat = @{
                MaxLength = $Width-$a-$b
                Range = $Range
                Value = $bin.Aggregate
            }
            $f = Get-BarLength @splat
            $g = ($Width-$a-$b-$f)
            $s = "$($Bin.Interval) $('X'*$f)$('-'*$g)"
            if ($ToString)
            {
                $s
            }
            else
            {
                Write-Host $s
            }
        }
    }
}
function Get-BarLength
{
    [CmdletBinding()]
    param
    (
        $MaxLength,

        $Range,

        $Value
    )
    process
    {
        $rangeSpan = $Range.Maximum-$Range.Minimum
        if ( $rangeSpan -eq 0 ) {$rangeSpan = 1}
        $k = $MaxLength/$rangeSpan
        $x = $Value-$Range.Minimum

        if ($x -lt 0)
        {
            return 0
        }

        return [Math]::Round($k*$x)
    }
}
