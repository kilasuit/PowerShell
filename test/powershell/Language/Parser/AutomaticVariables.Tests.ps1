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

Describe 'Automatic variable $pp' -Tags "CI" {
    It '$pp should return a non-empty string' {
        $pp | Should -Not -BeNullOrEmpty
    }

    It '$pp should be a string' {
        $pp | Should -BeOfType [string]
    }

    It '$pp should point to an existing file' {
        Test-Path -LiteralPath $pp -PathType Leaf | Should -BeTrue
    }

    It '$pp should be a constant variable' {
        $var = Get-Variable -Name pp
        $var.Options | Should -Match 'Constant'
    }

    It '$pp should be read-only (cannot be overwritten)' {
        { $pp = 'something' } | Should -Throw
    }

    It '$pp should match the current process path' {
        $pp | Should -Be ([System.Environment]::ProcessPath)
    }
}
