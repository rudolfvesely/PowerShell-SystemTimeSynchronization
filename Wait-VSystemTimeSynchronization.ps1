Workflow Wait-VSystemTimeSynchronization
{
    <#
    .SYNOPSIS
        Repeat time synchronization trials, do correction actions and wait till the synchronization is successful.

    .DESCRIPTION
        Developer
            Developer: Rudolf Vesely, http://rudolfvesely.com/
            Copyright (c) Rudolf Vesely. All rights reserved
            License: Free for private use only

            "V" is the first letter of the developer's surname. The letter is used to distingue Rudolf Vesely's cmdlets from the other cmdlets.

        Description
            Repeat time synchronization trials, do correction actions and wait till the synchronization is successful.

        Requirements
            Developed and tested using PowerShell 4.0.

    .PARAMETER ComputerName
        Computer names of remote devices. If not set then local device will be processed.

    .PARAMETER CorrectiveActions
        If False then the source rediscover or immediate time synchronization will not be done.

    .PARAMETER RepetitionCount
        If status of the last time synchronization is not valid (wrong source, last synchronization was too long ago) then the script will force source rediscover or immediate time synchronization and check the state again.

        Possibilities
            0 (Default)
                Infinite waiting

            1
                No re-trials

            2 - *
                Multiple trials

    .PARAMETER RepetitionDelaySeconds
        Delay in seconds between repetitions.

    .PARAMETER IgnoreError
        See help from: Test-VSystemTimeSynchronization

    .EXAMPLE
        '    - Get information from the remote devices (servers)'
        '    - Invoke correction actions on the remote devices'
        '    - Do not test source or date and time of last synchronization, test only valid data (date and time cannot be unknown)'
        '    - Wait for an infinitely long time'
        Wait-VSystemTimeSynchronization `
            -ComputerName hyper-v-host0, hyper-v-host-1, hyper-v-host-2 `
            -Verbose

    .EXAMPLE
        '    - Get information from the remote devices (servers)'
        '    - Invoke correction actions on the remote devices'
        '    - Last synchronization have to be a moment ago'
        '    - If the current NTP server (source) is not within specified values then rediscover sources on the defined remote device'
        '    - If the the last time synchronization was not done a moment ago then trigger immidiate time syncrhonization on the defined remote device'
        Wait-VSystemTimeSynchronization `
            -ComputerName hyper-v-host0, hyper-v-host-1, hyper-v-host-2 `
            -RequiredSourceName  '0.pool.ntp.org', '1.pool.ntp.org', '2.pool.ntp.org', '3.pool.ntp.org' `
            -LastTimeSynchronizationMaximumNumberOfSeconds 20 `
            -Verbose

    .EXAMPLE
        '    - Last synchronization have to be a moment ago'
        '    - If the current NTP server (source) is not within values specified in Windows Registry then rediscover sources'
        '    - If three repetitions and trials to do correction were not successful then end waiting and return data with Status property in False'
        Wait-VSystemTimeSynchronization `
            -RequiredSourceTypeConfiguredInRegistry:$true `
            -RepetitionCount 3 `
            -Verbose

    .INPUTS

    .OUTPUTS
        System.Management.Automation.PSCustomObject

    .LINK
        https://techstronghold.com/
    #>

    [CmdletBinding(
        DefaultParametersetName = 'Force',
        HelpURI = 'https://techstronghold.com/',
        ConfirmImpact = 'Medium'
    )]

    Param
    (
        [Parameter(
            Mandatory = $false
            # Position = ,
            # ParameterSetName = ''
        )]
        [AllowNull()]
        [AllowEmptyCollection()]
        [string[]]$ComputerName,

        [Parameter(
            Mandatory = $false
            # Position = ,
            # ParameterSetName = ''
        )]
        [AllowNull()]
        [AllowEmptyCollection()]
        [string[]]$RequiredSourceName,

        [Parameter(
            Mandatory = $false
            # Position = ,
            # ParameterSetName = ''
        )]
        [bool]$RequiredSourceTypeConfiguredInRegistry,

        [Parameter(
            Mandatory = $false
            # Position = ,
            # ParameterSetName = ''
        )]
        [bool]$RequiredSourceTypeNotLocal,

        [Parameter(
            Mandatory = $false
            # Position = ,
            # ParameterSetName = ''
        )]
        [bool]$RequiredSourceTypeNotByHost,

        [Parameter(
            Mandatory = $false
            # Position = ,
            # ParameterSetName = ''
        )]
        [AllowNull()]
        [int]$LastTimeSynchronizationMaximumNumberOfSeconds,

        [Parameter(
            Mandatory = $false
            # Position = ,
            # ParameterSetName = ''
        )]
        [string]$CompareWithNTPServerName,

        [Parameter(
            Mandatory = $false
            # Position = ,
            # ParameterSetName = ''
        )]
        [int]$CompareWithNTPServerMaximumTimeDifferenceSeconds = 10,

        [Parameter(
            Mandatory = $false
            # Position = ,
            # ParameterSetName = ''
        )]
        [bool]$CorrectiveActions = $true,

        [Parameter(
            Mandatory = $false
            # Position = ,
            # ParameterSetName = ''
        )]
        [AllowNull()]
        [int]$RepetitionCount,

        [Parameter(
            Mandatory = $false
            # Position = ,
            # ParameterSetName = ''
        )]
        [int]$RepetitionDelaySeconds = 5,

        [Parameter(
            Mandatory = $false
            # Position = ,
            # ParameterSetName = ''
        )]
        [AllowNull()]
        [AllowEmptyCollection()]
        [string[]]$IgnoreError
    )

    # Configurations
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'

    if ($ComputerName)
    {
        $computerNameItems = $ComputerName
    }
    else
    {
        $computerNameItems = '.'
    }


    $repetitionCountCurrent = 1
    $status = $false

    while (!$status -and ($RepetitionCount -eq 0 -or $repetitionCountCurrent -le $RepetitionCount))
    {
        if ($RepetitionCount -gt 0)
        {
            Write-Verbose -Message ('[Wait] Repetition: {0} / {1}' -f
                $repetitionCountCurrent, $RepetitionCount)

            $repetitionCountCurrent++
        }
        else
        {
            Write-Verbose -Message ('[Wait] Repetition')
        }



        <#
        Gather data
        #>

        $outputItems = Get-VSystemTimeSynchronization `
            -ComputerName                                         $ComputerName                                         `
            -RequiredSourceName                                   $RequiredSourceName                                   `
            -RequiredSourceTypeConfiguredInRegistry               $RequiredSourceTypeConfiguredInRegistry               `
            -RequiredSourceTypeNotLocal                           $RequiredSourceTypeNotLocal                           `
            -RequiredSourceTypeNotByHost                          $RequiredSourceTypeNotByHost                          `
            -LastTimeSynchronizationMaximumNumberOfSeconds        $LastTimeSynchronizationMaximumNumberOfSeconds        `
            -CompareWithNTPServerName                             $CompareWithNTPServerName                             `
            -CompareWithNTPServerMaximumTimeDifferenceSeconds     $CompareWithNTPServerMaximumTimeDifferenceSeconds     `
            -IgnoreError                                          $IgnoreError                                          `
            -Verbose:$false                                                                                             `
            -PSPersist:$false

        $outputOKItems           = $outputItems |
            Where-Object -FilterScript { $_.Status -eq $true }

        $outputWrongSourceItems  = $outputItems |
            Where-Object -FilterScript { $_.StatusSourceName -eq $false -or $_.StatusSourceType -eq $false }

        $outputOtherErrorItems   = $outputItems |
            Where-Object -FilterScript { $_.Status -ne $true -and
                                        ($_.StatusSourceName -ne $false -or $_.StatusSourceType -ne $false) }

        Write-Verbose -Message ('[Wait] Obtained data: Total: {0}, Obtained: {1}, OK: {2}, Wrong source: {3}, Other error: {4}' -f
            @($computerNameItems).Count, @($outputItems).Count, @($outputOKItems).Count,
            @($outputWrongSourceItems).Count, @($outputOtherErrorItems).Count)



        <#
        Corrective actions
        #>

        if ($CorrectiveActions -and ($outputWrongSourceItems -or $outputOtherErrorItems))
        {
            if ($outputWrongSourceItems)
            {
                Write-Verbose -Message ('[Wait] Correction action: Rediscover ({0}): {1}' -f
                    @($outputWrongSourceItem).Count, ($outputWrongSourceItem.ComputerNameNetBIOS -join ', '))

                $null = Start-VSystemTimeSynchronization `
                    -Rediscover:$true `
                    -PSComputerName $outputWrongSourceItem.ComputerNameNetBIOS
            }
            if ($outputOtherErrorItems)
            {
                Write-Verbose -Message ('[Wait] Correction action: Immediate synchronization ({0}): {1}' -f
                    @($outputOtherErrorItems).Count, ($outputOtherErrorItems.ComputerNameNetBIOS -join ', '))

                $null = Start-VSystemTimeSynchronization `
                    -Force:$true `
                    -PSComputerName $outputWrongSourceItem.ComputerNameNetBIOS
            }
        }
        else
        {
            $status = $true
        }


        <#
        Delay
            No delay after last repetition
        #>

        if ($RepetitionDelaySeconds -gt 0 -and
            ($RepetitionCount -eq 0 -or $repetitionCountCurrent -le $RepetitionCount))
        {
            Write-Debug -Message ('[Wait] [Debug] Delay: {0} seconds' -f
                 $RepetitionDelaySeconds)

            Start-Sleep -Seconds $RepetitionDelaySeconds
        }
    }

    <#
    Return
    #>

    if ($outputItems)
    {
        if (@($outputItems).Count -eq @($computerNameItems).Count)
        {
            Write-Verbose -Message ('[Wait] [Verbose] Finish: {0} devices' -f
                @($outputItems).Count)
        }
        else
        {
            Write-Warning -Message ('[Wait] [Error] Not all devices were queried: {0} / {1}' -f
                 @($outputItems).Count, @($computerNameItems).Count)
        }

        $outputItems
    }
    else
    {
        Write-Warning -Message ('[Wait] [Error] No data')
    }
}
