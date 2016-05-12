function Get-Bins
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipeline = $true)]
        $Object,

        [Parameter(Mandatory = $true)]
        [scriptblock]
        $Independent,

        [scriptblock]
        $Dependent = {$_},

        [scriptblock]
        $Aggregate = {$_ | Measure | % Count},

        [uint32]
        $MaxBins = 30,

        $Strategy
    )
    begin
    {
        $objects = New-Object System.Collections.ArrayList
        # https://stackoverflow.com/a/28666284/1404637
        $indSb = [scriptblock]::Create($Independent)
        $depSb = [scriptblock]::Create($Dependent)
        $aggSb = [scriptblock]::Create($Aggregate)
    }
    process
    {
        $objects.Add($Object) | Out-Null
    }
    end
    {
        $strategySplat = @{}
        if ($Strategy) { $strategySplat.Strategy = $Strategy }

        $bins = $objects |
            Get-Extremes $indSb |
            Get-BinDomains $MaxBins @strategySplat
        $objects |
            Add-ItemsToBins $indSb $bins |
            Add-AggregateValueToBin $aggSb | Out-Null
        return $bins
    }
}
function Get-Extremes
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipeline = $true)]
        $Object,

        [Parameter(Position = 1,
                   Mandatory = $true)]
        [scriptblock]
        $Scriptblock
    )
    begin {
        # https://stackoverflow.com/a/28666284/1404637
        $scriptBlockNotBoundToModule = [scriptblock]::Create($Scriptblock)

        $first = $true
    }
    process {
        $thisValue = Out-Collection $Object -ea Stop |
            % { & $scriptBlockNotBoundToModule }
        if ( $first )
        {
            $lowest = $thisValue
            $highest = $thisValue
            $first = $false
        }
        if ( $thisValue -lt $lowest )
        {
            $lowest = $thisValue
        }
        if ( $thisValue -gt $highest )
        {
            $highest = $thisValue
        }
    }
    end {
        New-Object psobject -Property @{
            Minimum = $lowest
            Maximum = $highest
        }
    }
}
function Get-BinDomains
{
    [CmdletBinding()]
    param
    (
        [ValidateSet('numeric','DateTime')]
        [string]
        $Strategy='numeric',

        [Parameter(ValueFromPipelineByPropertyName = $true,
                   Mandatory = $true)]
        $Minimum,

        [Parameter(ValueFromPipelineByPropertyName = $true,
                   Mandatory = $true)]
        $Maximum,

        [Parameter(Position = 1,
                   Mandatory = $true)]
        [ValidateScript({$_ -ge 1})]
        $MaxBins
    )
    process
    {
        $bp = (& (gbpm))

        if ( 'Strategy' -notin $bp.Keys)
        {
            $Strategy = Get-BinDomainsStrategy $Minimum,$Maximum
        }

        if ( $Maximum -le $Minimum )
        {
            throw New-Object System.ArgumentException(
                'Maximum must be greater than Minimum.',
                'Maximum'
            )
        }

        switch ($Strategy)
        {
            'numeric' { $bp | >> | Get-BinDomainsNumerical }
            'DateTime'  { $bp | >> | Get-BinDomainsDateTime  }
        }
    }
}
function Add-ItemsToBins
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true,
                   Mandatory = $true)]
        $Object,

        [Parameter(Position = 1,
                   Mandatory = $true)]
        [scriptblock]
        $Scriptblock,

        [Parameter(Position = 2,
                   Mandatory = $true)]
        [psobject[]]
        $Bins
    )
    begin {
        # https://stackoverflow.com/a/28666284/1404637
        $scriptBlockNotBoundToModule = [scriptblock]::Create($Scriptblock)
    }
    process {
        $value = Out-Collection $Object -ea Stop |
            % { & $scriptBlockNotBoundToModule }
        foreach ($bin in $Bins)
        {
            if
            (
                $value -ge $bin.LowerBound -and
                $value -lt $bin.UpperBound
            )
            {
                if ( $null -eq $bin.Items )
                {
                    $bin | Add-Member 'Items' (New-Object System.Collections.ArrayList)
                }
                $bin.Items.Add($Object)
            }
        }
    }
    end {
        $Bins
    }
}
function Add-AggregateValueToBin
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true,
                   Mandatory = $true)]
        [psobject]
        $Bin,

        [Parameter(Position = 1,
                   Mandatory = $true)]
        [scriptblock]
        $Scriptblock
    )
    begin {
        # https://stackoverflow.com/a/28666284/1404637
        $scriptBlockNotBoundToModule = [scriptblock]::Create($Scriptblock)
    }
    process
    {
        $aggregateValue = ,$Bin.Items | % { & $scriptBlockNotBoundToModule }
        $Bin |
            Add-Member Aggregate $aggregateValue
    }
    end {
        $Bin
    }
}
function Get-BinDomainsStrategy
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 1,
                   Mandatory = $true)]
        $Objects
    )
    process
    {
        $types = $Objects |
            % {
                New-Object psobject -Property @{
                    Type = $_.GetType()
                    IsComparable = $_ -is [System.IComparable]
                    IsNumeric = $_.GetType() | Test-NumericType
                }
            } |
            Select Type,IsComparable,IsNumeric -Unique

        if
        (
            ($types | Measure | % Count) -eq 1 -and
            $types[0].Type -eq [datetime]
        )
        {
            return 'DateTime'
        }

        if ( -not ($types | ? {-not $_.IsNumeric} ) )
        {
            return 'numeric'
        }

        if ( ($types | % Type) -contains [datetime] )
        {
            throw New-Object System.ArgumentException(
                'Independent values contains a mix of DateTime and other types.',
                'Objects'
            )
        }
        if ( $types | ? { -not $_.IsComparable})
        {
            throw New-Object System.ArgumentException(
                'Independent values contains items that are not IComparable.',
                'Objects'
            )
        }
    }
}
