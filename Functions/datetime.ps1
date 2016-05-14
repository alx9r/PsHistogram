function Get-BinDomainsDateTime
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName = $true,
                   Mandatory = $true)]
        [DateTime]
        $Minimum,

        [Parameter(ValueFromPipelineByPropertyName = $true,
                   Mandatory = $true)]
        [DateTime]
        $Maximum,

        [Parameter(Position = 1,
                   ValueFromPipelineByPropertyName = $true,
                   Mandatory = $true)]
        [ValidateScript({$_ -ge 1})]
        $MaxBins
    )
    process
    {
        $timeSpan = $Maximum.Subtract($Minimum)

        foreach (
            $amount in
                @(
                    @( 'Millisecond', $timeSpan.TotalMilliseconds ),
                    @( 'Second', $timeSpan.TotalSeconds   ),
                    @( 'Minute', $timeSpan.TotalMinutes   ),
                    @( 'Hour',   $timeSpan.TotalMinutes   ),
                    @( 'Day',    $timeSpan.TotalDays      ),
                    @( 'Week',   ($timeSpan.TotalDays/7)    ),
                    @( 'Month',  ($timeSpan.TotalDays/28)   ),
                    #@( 'Quarters',($timeSpan.TotalDays/90)   ),
                    @( 'Year',   ($timeSpan.TotalYears/365) )
                )
        )
        {
            if ( $amount[1] -lt $MaxBins )
            {
                break
            }
        }
        $binSize = $amount[0]

        $lowerBound = $Minimum | Get-QuantizedDateTime 'floor' $binSize
        $upperBound = $lowerBound | Get-QuantizedDateTime 'ceiling' $binSize

        $endUpperBound = $Maximum | Get-QuantizedDateTime 'ceiling' $binSize

        while ($upperBound -le $endUpperBound)
        {
            New-Object psobject -Property @{
                LowerBound = $lowerBound
                UpperBound = $upperBound
                Interval   = Get-DateTimeIntervalLabel $lowerBound $binSize
            }
            $lowerBound = $lowerBound | Get-QuantizedDateTime 'ceiling' $binSize
            $upperBound = $upperBound | Get-QuantizedDateTime 'ceiling' $binSize
        }
    }
}
function Get-QuantizedDateTime
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [DateTime]
        $Value,

        [Parameter(Position = 1,
                   Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('floor','ceiling')]
        [string]
        $Method,

        [Parameter(Position = 2,
                   Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('year','month','week','day','hour','minute','second')]
        [string]
        $Unit
    )
    process
    {
        if ( $Unit -eq 'week' )
        {
            $dayOfWeek = [int]$Value.DayOfWeek

            $Value = $Value.AddDays(
                    @{
                        'ceiling' = 6-$dayOfWeek
                        'floor'   = -$dayOfWeek
                    }.$Method
                )
            $Unit = 'day'
        }

        $splat = @{}
        foreach
        (
            $unitName in 'millisecond','second','minute',
                         'hour','day','month','year'
        )
        {
            if ( $unitName -eq $Unit )
            {
                break
            }
            if ( $unitName -in 'day','month','year')
            {
                $splat.$unitName = 1
            }
            else
            {
                $splat.$unitName = 0
            }
        }

        $output = $Value | Get-Date @splat

        if ($Method -eq 'ceiling')
        {
            $output = $output."Add$unitName`s"(1)
        }

        return $output
    }
}
function Get-DateTimeIntervalLabel
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 1,
                   Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [DateTime]
        $LowerBound,

        [Parameter(Position = 2,
                   Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('year','month','week','day','hour','minute','second')]
        [string]
        $Unit
    )
    process
    {
        if ( $Unit -eq 'week' )
        {
            $weekNum = $LowerBound | Get-WeekOfYear
            return "$($weekNum.Year)W$($weekNum.WeekNum.ToString('00'))"
        }

        $df = @{
            'year' = 'yyyy'
            'month' = 'yyyy-MM'
            'day'   = 'MM-dd'
            'hour'  = 'HH'
            'minute' = 'HH:mm'
            'second' = 'mm:ss'
        }.$Unit

        $LowerBound.ToString($df)
    }
}
function Get-WeekOfYear
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 1,
                   Mandatory = $true,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [DateTime]
        $Date
    )
    process
    {
        $dfi = [System.Globalization.DateTimeFormatInfo]::InvariantInfo
        $cal = $dfi.Calendar

        $result = @{
            WeekNum = $cal.GetWeekOfYear($Date,$dfi.CalendarWeekRule,$dfi.FirstDayOfWeek)
            Year = $Date.Year
        }

        if ($result.WeekNum -eq 53)
        {
            $result.WeekNum = 1
            $result.Year += 1
        }

        New-Object psobject -Property $result
    }
}
