function Get-BinDomainsNumerical
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName = $true,
                   Mandatory = $true)]
        $Minimum,

        [Parameter(ValueFromPipelineByPropertyName = $true,
                   Mandatory = $true)]
        $Maximum,

        [Parameter(Position = 1,
                   ValueFromPipelineByPropertyName = $true,
                   Mandatory = $true)]
        [ValidateScript({$_ -ge 1})]
        $MaxBins
    )
    process
    {
        $span = $Maximum-$Minimum
        $binSize = $span/$MaxBins

        $lowerBound = $Minimum
        $upperBound = $Minimum+$binSize

        while ($upperBound -le $Maximum)
        {
            New-Object psobject -Property @{
                LowerBound = $lowerBound
                UpperBound = $upperBound
                Interval   = Get-NumericIntervalLabel $lowerBound $upperBound
            }
            $lowerBound += $binSize
            $upperBound += $binSize
        }
    }
}
function Get-NumericIntervalLabel
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 1,
                   Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({$_.GetType() | Test-NumericType})]
        $LowerBound,

        [Parameter(Position = 2,
                   Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({$_.GetType() | Test-NumericType})]
        $UpperBound
    )
    process
    {
        "[$($LowerBound.ToString('0.00')),$($UpperBound.ToString('0.00')))"
    }
}
