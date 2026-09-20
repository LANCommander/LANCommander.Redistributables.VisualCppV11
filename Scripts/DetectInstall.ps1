# Reports whether the selected Visual C++ v11 Redistributable (2012) runtimes are
# already present, and at least as new as the build this package carries.
#
# Working directory: {InstallDir}\.lancommander\{RedistributableId}\
#
# Fast by construction: two registry reads per architecture and no network. The
# engine gives this script ten seconds.

$ErrorActionPreference = 'Stop'

# The registry stores a v-prefixed version -- "v11.0.61030.00" for this build --
# while the manifest carries the installer's file version, "11.0.61030.0". Those
# are the same build written two ways. Neither the prefix nor the component count
# is consistent across versions, and a three-part [version] has Revision -1 which
# sorts below 0, so both sides are reduced to major.minor.build before comparison.
# Compared raw, "11.0.61030.00" and "11.0.61030.0" would not match and detection
# would never succeed.
function Get-RuntimeVersion {
    param([string] $Value)

    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }

    $match = [regex]::Match($Value, '(\d+)\.(\d+)\.(\d+)')

    if (-not $match.Success) { return $null }

    return [version]::new([int] $match.Groups[1].Value, [int] $match.Groups[2].Value, [int] $match.Groups[3].Value)
}

# Anything unexpected means "not installed" rather than an error. A detection
# script that throws inside its timeout tells the operator nothing useful, and
# attempting an install that turns out to be redundant is harmless -- the installer
# itself reports 1638 and the Install script treats that as success.
$Return = $false

try {
    # The cmdlet writes a non-terminating error when the game manifest has no entry
    # for this redistributable. Both is the right answer in that case -- it is never
    # wrong, only occasionally more than necessary -- so the lookup is not allowed to
    # fail the script.
    $options = Get-RedistributableOptions -Path $InstallDirectory -Id $GameManifest.Id `
        -Name 'Visual C++ v11 Redistributable (2012)' -ErrorAction SilentlyContinue

    $architecture = if ($options -and $options.Architecture) { ([string] $options.Architecture).ToLowerInvariant() } else { 'both' }

    if ($architecture -eq 'auto') {
        $executable = $GameManifest.Actions |
            Where-Object { $_.IsPrimaryAction } |
            Select-Object -First 1 -ExpandProperty Path

        if ($executable) { $executable = $executable.Replace('{InstallDir}', $InstallDirectory) }

        # Unreadable executable falls back to both rather than guessing. A wrong
        # guess here silently skips the runtime the game actually needs.
        $architecture = 'both'

        if ($executable -and (Test-Path -LiteralPath $executable)) {
            $stream = [System.IO.File]::OpenRead($executable)

            try {
                $reader = [System.IO.BinaryReader]::new($stream)
                $stream.Position = 0x3C
                $stream.Position = $reader.ReadInt32() + 4
                $machine = $reader.ReadUInt16()

                # 0x8664 x64, 0xAA64 ARM64 -- both map to x64, but not for v14's
                # reason. The v14 x64 package carries ARM64 binaries; the 2012 one
                # does not, and Microsoft never shipped an ARM64 build of this
                # runtime at all. x64 is simply the closest thing that exists, and
                # ARM64 Windows runs it under emulation. 0x014C is x86, and is
                # also what a managed AnyCPU executable reports even though it runs
                # 64-bit; those games should be set to Both explicitly.
                $architecture = if ($machine -eq 0x8664 -or $machine -eq 0xAA64) { 'x64' } else { 'x86' }
            }
            finally {
                $stream.Dispose()
            }
        }
    }

    $required = switch ($architecture) {
        'x86' { @('x86') }
        'x64' { @('x64') }
        default { @('x86', 'x64') }
    }

    # Null when the manifest carries no version, which degrades this to a presence
    # check rather than failing detection outright.
    $wanted = Get-RuntimeVersion -Value $RedistributableManifest.Version

    $satisfied = $true

    foreach ($arch in $required) {
        # Which root a runtime is visible under is not predictable, so both are
        # probed. Registry redirection puts a 32-bit component under WOW6432Node and
        # a 64-bit one under the native path, and which of those the host PowerShell
        # can see depends on its own bitness. On top of that the versions are not
        # consistent with each other: v14 mirrors x64 into both roots, while 2012
        # writes BOTH architectures under WOW6432Node and leaves the native path
        # absent entirely. Probing one root only would silently never detect 2012.
        $entry = $null

        foreach ($root in @(
            'HKLM:\SOFTWARE\Microsoft\VisualStudio\11.0\VC\Runtimes',
            'HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\11.0\VC\Runtimes'
        )) {
            $candidate = Get-ItemProperty -Path (Join-Path $root $arch) -ErrorAction SilentlyContinue

            if ($candidate -and $candidate.Installed -eq 1) { $entry = $candidate; break }
        }

        if (-not $entry) {
            Write-Host "Visual C++ v11 Redistributable (2012) ($arch) is not installed"
            $satisfied = $false
            break
        }

        $installed = Get-RuntimeVersion -Value ([string] $entry.Version)

        if ($wanted -and (-not $installed -or $installed -lt $wanted)) {
            Write-Host "Visual C++ v11 Redistributable (2012) ($arch) is $($entry.Version), older than the packaged $($RedistributableManifest.Version)"
            $satisfied = $false
            break
        }
    }

    $Return = $satisfied
}
catch {
    Write-Host "Visual C++ v11 Redistributable (2012) detection failed, assuming not installed: $($_.Exception.Message)"
    $Return = $false
}
