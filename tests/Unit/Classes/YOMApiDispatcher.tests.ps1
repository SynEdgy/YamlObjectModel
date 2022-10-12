param ()

BeforeAll {
    $CurrentModule = @{
        ModuleName = 'YamlObjectModel'
    }

    Import-Module -Name YamlObjectModel -Force -ErrorAction Stop
}

Describe 'Validating static class [YOMApiDispatcher]' {

    BeforeAll {
    }

    It 'should have empty hash return to false from IsDefinition()' {
        $isDefinition = InModuleScope @CurrentModule -ScriptBlock {
            [YOMApiDispatcher]::IsDefinition(@{})
        }

        $isDefinition | Should -be $false
    }


    It 'should have kind/spec return true from IsDefinition()' {
        $isDefinition = InModuleScope @CurrentModule -ScriptBlock {
            [YOMApiDispatcher]::IsDefinition(@{
                kind = 'YOMBase'
                spec = @{}
            })
        }

        $isDefinition | Should -be $true
    }

    It 'should have string object return false from IsDefinition()' {
        {
            $isDefinition = InModuleScope @CurrentModule -ScriptBlock {
                [YOMApiDispatcher]::IsDefinition('abc')
            }
        } | Should -Not -Throw

        $isDefinition = InModuleScope @CurrentModule -ScriptBlock {
            [YOMApiDispatcher]::IsDefinition('abc')
        }

        $isDefinition | Should -be $false
    }

    It 'should correctly instantiate a module specific class' {
        $YOMInstance = InModuleScope @CurrentModule -ScriptBlock {
            [YOMApiDispatcher]::DispatchSpec(
                @{
                    kind = 'YamlObjectModel\YOMBase'
                    spec = @{}
                }
            )
        }
        $YOMInstance | Should -not -BeNullOrEmpty
    }

    It 'should correctly instantiate with a class method' {
        $YOMInstance = InModuleScope @CurrentModule -ScriptBlock {
            [YOMApiDispatcher]::DispatchSpec(
                @{
                    kind = '[YOMApiDispatcher]::DispatchSpec()'
                    spec = @{
                        kind = 'YOMBase'
                        spec = @{}
                    }
                }
            )
        }

        $YOMInstance | Should -not -BeNullOrEmpty
    }

    It 'should correctly dispatch with a function' {
        $YOMInstance = InModuleScope @CurrentModule -ScriptBlock {
            [YOMApiDispatcher]::DispatchSpec(
                @{
                    kind = 'YamlObjectModel\Get-YOMObject'
                    spec = @{
                        Definition = @{
                            kind = 'YOMBase'
                            spec = @{}
                        }
                    }
                }
            )
        }

        $YOMInstance | Should -not -BeNullOrEmpty
    }

    It 'should correctly dispatch with default type and hash' {
        $YOMInstance = InModuleScope @CurrentModule -ScriptBlock {
            [YOMApiDispatcher]::DispatchSpec(
                'YOMBase',
                @{
                    kind = 'YOMBase'
                    spec = @{
                        stuff = 'abc'
                    }
                }
            )
        }

        $YOMInstance | Should -not -BeNullOrEmpty
    }
}
