Workflow Start-VSystemTimeSynchronization
{
    <#
    .SYNOPSIS
        Start time synchronization with NTP server (time source). NTP server have to be configured in Windows Registry (via Group Policy, w32tm command or by manual edit of Registry).

    .DESCRIPTION
        Developer
            Developer: Rudolf Vesely, http://rudolfvesely.com/
            Copyright (c) Rudolf Vesely. All rights reserved
            License: Free for private use only

            "V" is the first letter of the developer's surname. The letter is used to distingue Rudolf Vesely's cmdlets from the other cmdlets.

        Description
            Start time synchronization with NTP server (time source). NTP server have to be configured in Windows Registry (via Group Policy, w32tm command or by manual edit of Registry).

        Requirements
            Developed and tested using PowerShell 4.0.

    .PARAMETER Force
        If True then time synchronization will start imediately.

    .PARAMETER Rediscover
        First rediscover time sources and then do the start time synchronization.

    .EXAMPLE
        'Start time synchronization'
        Start-VSystemTimeSynchronization -Force:$true -Verbose

    .EXAMPLE
        'Rediscover time sources (configured NTP servers)'
        Start-VSystemTimeSynchronization -Rediscover:$true -Verbose

    .EXAMPLE
        'Invoke time synchronization on remote devices'
        Start-VSystemTimeSynchronization `
            -Force:$true `
            -PSComputerName contoso0, contoso1, contoso2 `
            -Verbose

    .EXAMPLE
        'Invoke time source rediscover on remote devices'
        Start-VSystemTimeSynchronization `
            -Rediscover:$true `
            -PSComputerName contoso0, contoso1, contoso2 `
            -Verbose

    .INPUTS

    .OUTPUTS
        System.Boolean

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
            Mandatory = $false,
            # Position = ,
            ParameterSetName = 'Force'
        )]
        [bool]$Force = $true,

        [Parameter(
            Mandatory = $false,
            # Position = ,
            ParameterSetName = 'Rediscover'
        )]
        [bool]$Rediscover = $false
    )

    # Configurations
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'



    <#
    Start service
    #>

    try
    {
        if ((Get-Service -Name W32Time).Status -ne 'Running')
        {
            Write-Verbose -Message '[Start] [Start service] [Verbose] Start service: W32Time (Windows Time)'
            Start-Service -Name W32Time
        }
    }
    catch
    {
        Write-Warning -Message  ('[Start] [Start service] [Exception] {0}' -f $_.Message)

        # Return
        $false
    }



    <#
    Start time synchronization
    #>

    try
    {
        if ($Rediscover)
        {
            $w32tmOutput = InlineScript { & 'w32tm' '/resync', '/rediscover' }
        }
        elseif ($Force)
        {
            $w32tmOutput = InlineScript { & 'w32tm' '/resync', '/force' }
        }
        else
        {
            $w32tmOutput = InlineScript { & 'w32tm' '/resync' }
        }

        if ($w32tmOutput | Select-String -Pattern 'The command completed successfully.')
        {
            Write-Debug -Message ('[Start] [Synchronization] [Debug] Command completed successfully.')

            # Return
            $true
        }
        else
        {
            Write-Warning -Message ('[Start] [Synchronization] [Error] Command did not completed successfully.')

            # Return
            $false
        }
    }
    catch
    {
        Write-Warning -Message  ('[Start] [Synchronization] [Exception] {0}' -f $_.Message)

        # Return
        $false
    }
}
