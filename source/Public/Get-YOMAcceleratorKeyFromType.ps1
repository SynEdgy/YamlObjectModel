function Get-YOMAcceleratorKeyFromType
{
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
        [Parameter()]
        [string]
        $Type
    )

    $fullTypeName = ($Type -as [Type]).FullName
    if ([string]::IsNullOrEmpty($fullTypeName))
    {
        Write-Debug -Message ('Type ''{0}'' not found.' -f $Type)
        return
    }

    $typeAcceleratorsClass = [psobject].Assembly.GetType(
        'System.Management.Automation.TypeAccelerators'
    )

    $existingTypeAccelerators = $typeAcceleratorsClass::Get
    if ($fullTypeName -in $existingTypeAccelerators.Values.FullName)
    {
        # the class' full Name has a matching type accelerator
        @($existingTypeAccelerators.GetEnumerator()).Where{$_.Value.FullName -eq $fullTypeName}
    }
}
