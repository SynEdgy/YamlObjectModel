class YOMTest : YOMBase
{
    [string] $Stuff

    YOMTest()
    {
        # Default ctor
    }

    YOMTest([System.Collections.IDictionary]$RawSpec)
    {
        $this.ResolveSpec($RawSpec)
    }
}
