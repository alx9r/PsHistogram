[![Build status](https://ci.appveyor.com/api/projects/status/jl2k058mu8fluq0p/branch/master?svg=true&passingText=master%20-%20OK)](https://ci.appveyor.com/project/alx9r/PsHistogram/branch/master)

## PowerShell Module for Showing Data as a Histogram

### Example Usage

````PowerShell
Get-WinEvent -FilterHashtable @{
    ID = 6006
    LogName = 'System'
    StartTime = (Get-Date).AddMonths(-12)
} |
    Get-Bins -Independent {$_.TimeCreated} |
    ConvertTo-Histogram |
    Write-Histogram
````

Outputs a histogram of the number of reboots in the past 12 months:

````
        8          30
2015-05 ------------
2015-06 XXXXXXXXX---
2015-07 XXXXXXX-----
2015-08 XXXXXXXX----
2015-09 XXXXXXXXXXXX
2015-10 XXXXXXXX----
2015-11 XXXXXXXXXX--
2015-12 XXXXXXXX----
2016-01 XXXXXXX-----
2016-02 XXX---------
2016-03 XXXXXXXXX---
2016-04 XXXXXXXXX---
2016-05 X-----------
````