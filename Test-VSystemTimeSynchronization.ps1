Workflow Test-VSystemTimeSynchronization
{
    <#
    .SYNOPSIS
        Test time synchronization of multiple devices in parallel. Get information about their currect state, do correction actions and compare their current time with specific NTP server or with time on the internet.

    .DESCRIPTION
        Developer
            Developer: Rudolf Vesely, http://rudolfvesely.com/
            Copyright (c) Rudolf Vesely. All rights reserved
            License: Free for private use only

            "V" is the first letter of the developer's surname. The letter is used to distingue Rudolf Vesely's cmdlets from the other cmdlets.

        Description
            Test time synchronization of multiple devices in parallel. Get information about their currect state, do correction actions and compare their current time with specific NTP server or with time on the internet.

        Requirements
            Developed and tested using PowerShell 4.0.

    .PARAMETER ComputerName
        Computer names of remote devices. If not set then local device will be processed.

    .PARAMETER CompareWithNTPServerName
        Compare time difference between device and specified NTP server and raise error when the time difference has exceeded defined maximum.

        It is handy to use different NTP server then server that is used internally.

        Type of comparison: Between remote device (target) and NTP server (UDP 123).

            Advantages: Accurate

            Disadvantages: Remote device has to have opened UDP 123 to remote NTP server.

    .PARAMETER CompareWithNTPServerMaximumTimeDifferenceSeconds
        Defined maximum of seconds of time difference.

    .PARAMETER CompareWithWeb
        Compare time difference between device and external website and raise error when the time difference has exceeded defined maximum.

        Type of comparison: Between local device (device that run the Workflow against remote device) and NTP server (TCP 80, proxy could be used).

            Advantages: Remote device does not have opened firewall (comparison is done on the device that run the Workflow).

            Disadvantages: Inaccurate

    .PARAMETER CompareWithWebMaximumTimeDifferenceSeconds
        Defined maximum of seconds of time difference.

    .PARAMETER IgnoreError
        Ignore some specific errors.

        Possibilities
            WrongComputerName
                Device does not exists (not in DNS).

            DeviceIsNotAccessible
                Device exists (defined in DNS) but it is not reachable (not running, FW issue, etc.).

            CompareWithNTPServerNoConnection
                Error when the remote device cannot connect NTP server.

            CompareWithWebNoConnection
                Error when the local device cannot connect web to get time.

    .EXAMPLE
        '    - Get information from the remote devices (servers)'
        '    - Invoke correction actions on the remote devices'
        '    - Compare remote device''s time with defined NTP server (UDP 123 from remote server)'
        '        - It is possible to set IPv4 (for example 192.168.3.5), IPv6 (for example fd12:3456::0045) or DNS name (for example 0.pool.ntp.org)'
        '    - Compare remote device''s time with time obtained from website (from the internet) (TCP 80 from local server, inaccurate)'
        '    - Ignore when it is not possible to connect to get time from internet or from NTP server'
        Test-VSystemTimeSynchronization `
            -CompareWithNTPServerName 'fd12:3456::0045' `
            -CompareWithNTPServerMaximumTimeDifferenceSeconds 30 `
            -CompareWithWeb:$true `
            -CompareWithWebMaximumTimeDifferenceSeconds 60 `
            -IgnoreError CompareWithNTPServerNoConnection,
                CompareWithWebNoConnection `

    .EXAMPLE
        '    - Send e-mail when the Status is not True'
        '    - Ignore all errors related to network connectivity (devices could be inaccessible)'
        '    - Source has to be uqueal to one of the NTP servers that are configured in Windows Registry'
        '    - Last synchronization cannot be older then 24 hours'
        try
        {
            $results = Test-VSystemTimeSynchronization `
                -ComputerName hyperv-host0, hyperv-host1, hyperv-host2 `
                -RequiredSourceTypeConfiguredInRegistry:$true `
                -LastTimeSynchronizationMaximumNumberOfSeconds 86400 `
                -RepetitionCount 3 `
                -RepetitionDelaySeconds 5 `
                -IgnoreError DeviceIsNotAccessible,
                    CompareWithNTPServerNoConnection,
                    CompareWithWebNoConnection `
                -Verbose `
                -ErrorAction Stop

            $wrongResult = $results | Where-Object -Property Status -NE -Value $true

            if ($wrongResult)
            {
                Send-MailMessage `
                    -From 'User01 <user01@example.com>' `
                    -To 'User02 <user02@example.com>', 'User03 <user03@example.com>' `
                    -Subject 'Time synchronization error' `
                    -Body ('Error on following servers: {0}' -f ($wrongResult.ComputerNameBasic -join ', ')) `
                    -Priority High `
                    -SmtpServer smtp.contoso.com
            }
        }
        catch
        {
            Write-Warning -Message 'Exception that is not related to network accessibility.'

            if ($wrongResult)
            {
                Send-MailMessage `
                    -From 'User01 <user01@example.com>' `
                    -To 'User02 <user02@example.com>', 'User03 <user03@example.com>' `
                    -Subject 'Time synchronization error' `
                    -Body ('Exception: {0}' -f $_.Exception.Message) `
                    -Priority High `
                    -SmtpServer smtp.contoso.com
            }

            'Some action in case of unknwon exception...'
        }

    .INPUTS

    .OUTPUTS
        System.Management.Automation.PSCustomObject

    .LINK
        https://techstronghold.com/
    #>

    [CmdletBinding(
        DefaultParametersetName = 'ComputerName',
        HelpURI = 'https://techstronghold.com/',
        ConfirmImpact = 'Medium'
    )]

    Param
    (
        [Parameter(
            Mandatory = $false,
            Position = 0,
            ParameterSetName = 'ComputerName'
        )]
        [ValidateLength(1, 255)]
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
        [switch]$CompareWithWeb,

        [Parameter(
            Mandatory = $false
            # Position = ,
            # ParameterSetName = ''
        )]
        [int]$CompareWithWebMaximumTimeDifferenceSeconds = 30,

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
        [int]$RepetitionCount = 3,

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
        [ValidateSet(
            'WrongComputerName',
            'DeviceIsNotAccessible',
            'CompareWithNTPServerNoConnection',
            'CompareWithWebNoConnection'
        )]
        [string[]]$IgnoreError
    )

    # Configurations
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'



    <#
    Time from internet
    #>

    $dateTimeInternetUtc          = $null
    $dateTimeInternetUtcObtained  = $null

    if ($CompareWithWeb)
    {
        try
        {
            $dateTimeInternetUtc          = Get-VDateTimeInternetUtc -Verbose:$false
            $dateTimeInternetUtcObtained  = (Get-Date).ToUniversalTime()
        }
        catch
        {
            if ($IgnoreError -contains 'CompareWithWebNoConnection')
            {
                Write-Warning -Message '[Test] [Compare with web] [Error] Cannot obtain date and time from the internet'
            }
            else
            {
                Write-Error -Exception $_
            }
        }
    }



    <#
    Gathering data and correction actions
    #>

    $outputItems = Wait-VSystemTimeSynchronization `
        -ComputerName                                      $ComputerName                                      `
        -RequiredSourceName                                $RequiredSourceName                                `
        -RequiredSourceTypeConfiguredInRegistry            $RequiredSourceTypeConfiguredInRegistry            `
        -RequiredSourceTypeNotLocal                        $RequiredSourceTypeNotLocal                        `
        -RequiredSourceTypeNotByHost                       $RequiredSourceTypeNotByHost                       `
        -LastTimeSynchronizationMaximumNumberOfSeconds     $LastTimeSynchronizationMaximumNumberOfSeconds     `
        -CompareWithNTPServerName                          $CompareWithNTPServerName                          `
        -CompareWithNTPServerMaximumTimeDifferenceSeconds  $CompareWithNTPServerMaximumTimeDifferenceSeconds  `
        -CorrectiveActions                                 $CorrectiveActions                                 `
        -RepetitionCount                                   $RepetitionCount                                   `
        -RepetitionDelaySeconds                            $RepetitionDelaySeconds                            `
        -IgnoreError                                       $IgnoreError
    $outputItemsObtainedDateTimeUtc = (Get-Date).ToUniversalTime()



    <#
    Processing gathered data
    #>

    foreach -parallel ($outputItem in $outputItems)
    {
        $errorItems  = $outputItem.ErrorEvents
        $statusItems = $outputItem.StatusEvents



        <#
        Error handling: Time from internet
        #>

        $comparisonWebTimeDifferenceSeconds = $null
        $statusComparisonWeb = $null

        if ($dateTimeInternetUtc)
        {
            # Correct time from the internet that was obtained a couple seconds ago
            $dateTimeInternetUtcWithCorrection = $dateTimeInternetUtc + ($outputItemsObtainedDateTimeUtc - $dateTimeInternetUtcObtained)

            $comparisonWebTimeDifferenceSeconds = [int]($dateTimeInternetUtcWithCorrection - $outputItem.DateTimeUtc).TotalSeconds

            if ($comparisonWebTimeDifferenceSeconds -eq $null -or
                $comparisonWebTimeDifferenceSeconds -lt ($CompareWithWebMaximumTimeDifferenceSeconds * -1) -or
                $comparisonWebTimeDifferenceSeconds -gt $CompareWithWebMaximumTimeDifferenceSeconds)
            {
                $statusComparisonWeb = $false

                $errorItems += ('[Test] [Compare with web] [Error] Elapsed: {0} seconds; Defined maximum: {1} seconds' -f
                    $comparisonWebTimeDifferenceSeconds, $CompareWithWebMaximumTimeDifferenceSeconds)
            }
            else
            {
                $statusComparisonWeb = $true
            }
        }
        else
        {
            if ($CompareWithWeb)
            {
                $statusItems += '[Test] [Compare with web] [Error] Cannot obtain date and time from the internet'
            }
        }



        <#
        Return
        #>

        [PsCustomObject]@{
            DateTimeUtc                                     = $outputItem.DateTimeUtc
            DateTimeInternetUtc                             = $dateTimeInternetUtcWithCorrection
            ComputerNameBasic                               = $outputItem.ComputerNameBasic
            ComputerNameNetBIOS                             = $outputItem.ComputerNameNetBIOS
            ComputerNameFQDN                                = $outputItem.ComputerNameFQDN
            ConfiguredNTPServerName                         = $outputItem.ConfiguredNTPServerName
            ConfiguredNTPServerNameRaw                      = $outputItem.ConfiguredNTPServerNameRaw
            ConfiguredNTPServerByPolicy                     = $outputItem.ConfiguredNTPServerByPolicy
            SourceName                                      = $outputItem.SourceName
            SourceNameRaw                                   = $outputItem.SourceNameRaw
            LastTimeSynchronizationDateTime                 = $outputItem.LastTimeSynchronizationDateTime
            LastTimeSynchronizationElapsedSeconds           = $outputItem.LastTimeSynchronizationElapsedSeconds
            ComparisonNTPServerName                         = $outputItem.ComparisonNTPServerName
            ComparisonNTPServerTimeDifferenceSeconds        = $outputItem.ComparisonNTPServerTimeDifferenceSeconds

            ComparisonWebTimeDifferenceSeconds              = $comparisonWebTimeDifferenceSeconds

            StatusRequiredSourceName                        = $outputItem.StatusRequiredSourceName
            StatusRequiredSourceType                        = $outputItem.StatusRequiredSourceType
            StatusDateTime                                  = $outputItem.StatusDateTime
            StatusLastTimeSynchronization                   = $outputItem.StatusLastTimeSynchronization
            StatusComparisonNTPServer                       = $outputItem.StatusComparisonNTPServer

            StatusComparisonWeb                             = $statusComparisonWeb

            Status                                          = $(if ($errorItems) { $false } else { $true })
            StatusEvents                                    = $statusItems
            Error                                           = $(if ($errorItems) { $true } else { $false })
            ErrorEvents                                     = $errorItems
        }

        Write-Verbose -Message ('[Test: {0}] [Verbose]: Finished with additional details: {1}' -f
            $outputItem.ComputerNameBasic, $(if ($statusItems) { $statusItems -join '; ' } else { 'None' } ))
    }
}
