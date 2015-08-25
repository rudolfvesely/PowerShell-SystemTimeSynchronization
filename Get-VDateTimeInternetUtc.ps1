Workflow Get-VDateTimeInternetUtc
{
    <#
    .SYNOPSIS
        Get current date and time for internet.

    .DESCRIPTION
        Developer
            Developer: Rudolf Vesely, http://rudolfvesely.com/
            Copyright (c) Rudolf Vesely. All rights reserved
            License: Free for private use only

            "V" is the first letter of the developer's surname. The letter is used to distingue Rudolf Vesely's cmdlets from the other cmdlets.

        Description
            Get current date and time for internet.

        Requirements
            Developed and tested using PowerShell 4.0.

    .EXAMPLE
        'Get using HTTP'
        Get-VDateTimeInternetUtc

    .INPUTS

    .OUTPUTS

    .LINK
        https://techstronghold.com/
    #>

    [CmdletBinding(
        HelpURI = 'https://techstronghold.com/',
        ConfirmImpact = 'Medium'
    )]

    # Configurations
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'

    $webRequest = Invoke-WebRequest -Uri 'http://nist.time.gov/actualtime.cgi?lzbc=siqm9b'

    $milliseconds = [int64](($webRequest.Content -replace '.*time="|" delay=".*') / 1000)

    # Return
    InlineScript
    {
        (New-Object -TypeName DateTime -ArgumentList (1970, 1, 1)).AddMilliseconds($Using:milliseconds)
    }
}
