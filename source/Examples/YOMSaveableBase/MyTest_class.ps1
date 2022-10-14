using namespace System.Collections
using namespace System.Collections.Specialized
using module YamlObjectModel
using namespace YamlDotNet.Serialization

class MyTest : YOMSaveableBase
{
    [string] $Property1
    [string] $Property2

    MyTest()
    {
        # Default Ctor()
    }

    MyTest([IDictionary] $Definition)
    {
        # constructor for hashtable/Ordered Dictionary
        $this.ResolveSpec($Definition) # Common method coming from YOMBase
    }

    [string] GetString()
    {
        return ('{0} and {1}' -f $this.Property1,$this.Property2)
    }
}

$obj = [YOMApiDispatcher]::DispatchSpec(@{
    kind = 'MyTest'
    spec = @{
        Property1 = 'thingy'
        Property2 = 'something else'
    }
})

$obj.SaveTo('./obj.yml')

# change something in the file
$obj.Reload()

Write-Host -Object $obj.ToString()

# In a different session where the object is loaded and namespace/module available
# using module YamlObjectModel
# add your [MyTest] definition
# Get-YOMObject -Path ./obj.yml
