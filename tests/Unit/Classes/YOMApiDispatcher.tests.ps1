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

    It 'should dispatch a Kubernetes-style resource envelope' {
        $YOMInstance = InModuleScope @CurrentModule -ScriptBlock {
            [YOMApiDispatcher]::DispatchSpec(
                [ordered]@{
                    apiVersion = 'yom.synedgy.com/v1alpha1'
                    kind = 'YOMBase'
                    metadata = [ordered]@{
                        Name = 'resource-one'
                    }
                    spec = [ordered]@{}
                }
            )
        }

        $YOMInstance.ApiVersion | Should -Be 'yom.synedgy.com/v1alpha1'
        $YOMInstance.Kind | Should -Be 'YOMBase'
        $YOMInstance.Metadata.Name | Should -Be 'resource-one'
    }

    It 'should dispatch a typed short envelope without wrapping the envelope as spec' {
        $YOMInstance = InModuleScope @CurrentModule -ScriptBlock {
            [YOMApiDispatcher]::DispatchSpec(
                'YOMBase',
                [ordered]@{
                    apiVersion = 'yom.synedgy.com/v1alpha1'
                    metadata = [ordered]@{
                        Name = 'short-resource'
                    }
                    spec = [ordered]@{}
                }
            )
        }

        $YOMInstance.ApiVersion | Should -Be 'yom.synedgy.com/v1alpha1'
        $YOMInstance.Kind | Should -Be 'YOMBase'
        $YOMInstance.Metadata.Name | Should -Be 'short-resource'
    }

    It 'should continue dispatching a legacy raw spec with a default type' {
        $YOMInstance = InModuleScope @CurrentModule -ScriptBlock {
            [YOMApiDispatcher]::DispatchSpec(
                'YOMBase',
                [ordered]@{
                    LegacyProperty = 'legacy-value'
                }
            )
        }

        $YOMInstance | Should -Not -BeNullOrEmpty
        $YOMInstance.Kind | Should -Be 'YOMBase'
    }

    It 'should default apiVersion when typed short metadata is supplied' {
        $YOMInstance = InModuleScope @CurrentModule -ScriptBlock {
            [YOMApiDispatcher]::DispatchSpec(
                'YOMBase',
                [ordered]@{
                    metadata = [ordered]@{
                        Name = 'metadata-only'
                    }
                    spec = [ordered]@{}
                }
            )
        }

        $YOMInstance.ApiVersion | Should -Be ''
        $YOMInstance.Metadata.Name | Should -Be 'metadata-only'
    }

    It 'should default metadata when typed short apiVersion is supplied' {
        $YOMInstance = InModuleScope @CurrentModule -ScriptBlock {
            [YOMApiDispatcher]::DispatchSpec(
                'YOMBase',
                [ordered]@{
                    apiVersion = 'yom.synedgy.com/v1alpha1'
                    spec = [ordered]@{}
                }
            )
        }

        $YOMInstance.ApiVersion | Should -Be 'yom.synedgy.com/v1alpha1'
        $YOMInstance.Metadata.Count | Should -Be 0
    }

    It 'should reject a definition without spec' {
        {
            InModuleScope @CurrentModule -ScriptBlock {
                [YOMApiDispatcher]::DispatchSpec(
                    [ordered]@{
                        kind = 'YOMBase'
                    }
                )
            }
        } | Should -Throw '*dictionary under the ''spec'' key*'
    }

    It 'should reject a definition with a non-dictionary spec' {
        {
            InModuleScope @CurrentModule -ScriptBlock {
                [YOMApiDispatcher]::DispatchSpec(
                    [ordered]@{
                        kind = 'YOMBase'
                        spec = 'invalid'
                    }
                )
            }
        } | Should -Throw '*dictionary under the ''spec'' key*'
    }

    It 'should reject input that has no kind when no default type is supplied' {
        {
            InModuleScope @CurrentModule -ScriptBlock {
                [YOMApiDispatcher]::DispatchSpec([ordered]@{})
            }
        } | Should -Throw '*define it under the ''kind'' key*'
    }
}
