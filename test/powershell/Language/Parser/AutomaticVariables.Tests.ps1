# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

Describe 'Automatic variable $input' -Tags "CI" {
    # $input type in advanced functions
    It '$input Type should be arraylist and object array' {
        function from_begin { [cmdletbinding()]param() begin { Write-Output -NoEnumerate $input } }
        function from_process { [cmdletbinding()]param() process { Write-Output -NoEnumerate $input } }
        function from_end { [cmdletbinding()]param() end { Write-Output -NoEnumerate $input } }

        (from_begin) -is [System.Collections.ArrayList] | Should -BeTrue
        (from_process) -is [System.Collections.ArrayList] | Should -BeTrue
        (from_end) -is [System.Object[]] | Should -BeTrue
    }

    It 'Empty $input really is empty' {
        & { @($input).Count } | Should -Be 0
        & { [cmdletbinding()]param() begin { @($input).Count } } | Should -Be 0
        & { [cmdletbinding()]param() process { @($input).Count } } | Should -Be 0
        & { [cmdletbinding()]param() end { @($input).Count } } | Should -Be 0
    }
}

Describe 'Automatic variable $PSProcessPath' -Tags "CI" {
    BeforeAll {
        $script:psProcessPathFeatureEnabled = $EnabledExperimentalFeatures.Contains('PSProcessPathAutomaticVariable')
        $script:psProcessPathSkipMessage = "The experimental feature 'PSProcessPathAutomaticVariable' must be enabled to use `$PSProcessPath."
    }

    It '$PSProcessPath should return a non-empty string' {
        if (-not $script:psProcessPathFeatureEnabled) {
            Set-ItResult -Skipped -Because $script:psProcessPathSkipMessage
            return
        }
        $PSProcessPath | Should -Not -BeNullOrEmpty
    }

    It '$PSProcessPath should be a string' {
        if (-not $script:psProcessPathFeatureEnabled) {
            Set-ItResult -Skipped -Because $script:psProcessPathSkipMessage
            return
        }
        $PSProcessPath | Should -BeOfType [string]
    }

    It '$PSProcessPath should point to an existing file' {
        if (-not $script:psProcessPathFeatureEnabled) {
            Set-ItResult -Skipped -Because $script:psProcessPathSkipMessage
            return
        }
        Test-Path -LiteralPath $PSProcessPath -PathType Leaf | Should -BeTrue
    }

    It '$PSProcessPath should be a constant variable' {
        if (-not $script:psProcessPathFeatureEnabled) {
            Set-ItResult -Skipped -Because $script:psProcessPathSkipMessage
            return
        }
        $var = Get-Variable -Name PSProcessPath
        $var.Options | Should -Match 'Constant'
    }

    It '$PSProcessPath should be read-only (cannot be overwritten)' {
        if (-not $script:psProcessPathFeatureEnabled) {
            Set-ItResult -Skipped -Because $script:psProcessPathSkipMessage
            return
        }
        { $PSProcessPath = 'something' } | Should -Throw
    }

    It '$PSProcessPath should match the current process path' {
        if (-not $script:psProcessPathFeatureEnabled) {
            Set-ItResult -Skipped -Because $script:psProcessPathSkipMessage
            return
        }
        $PSProcessPath | Should -Be ([System.Environment]::ProcessPath)
    }
}

Describe 'Automatic variable $PSProcessPath - feature disabled' -Tags "CI" {
    BeforeAll {
        $script:psProcessPathFeatureEnabled = $EnabledExperimentalFeatures.Contains('PSProcessPathAutomaticVariable')
    }

    It '$PSProcessPath should not exist when experimental feature is disabled' {
        if ($script:psProcessPathFeatureEnabled) {
            Set-ItResult -Skipped -Because "The experimental feature 'PSProcessPathAutomaticVariable' is enabled; test requires the feature to be disabled."
            return
        }
        { Get-Variable -Name PSProcessPath -ErrorAction Stop } | Should -Throw
    }
}
