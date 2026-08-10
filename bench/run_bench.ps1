$sections = @(
    @{Id=1; Name="Perl compile"},
    @{Id=2; Name="Perl match"},
    @{Id=3; Name="Emacs compile+match"},
    @{Id=4; Name="POSIX compile+match"},
    @{Id=5; Name="Glob compile+match"},
    @{Id=6; Name="Pcre compile+match"},
    @{Id=7; Name="Str compile+match"},
    @{Id=8; Name="Search all+matches"},
    @{Id=9; Name="Split+Replace"},
    @{Id=10; Name="Large+Caseless"}
)

$mainFile = "D:\CodeWorkspace\forMoonbit\re-mbt\bench\main\main.mbt"
$origContent = Get-Content $mainFile -Raw
$exe = "D:\CodeWorkspace\forMoonbit\re-mbt\_build\native\release\build\bench\main\main.exe"

Write-Output "Section | Name | Best(ms) | Per-iter(us)"
Write-Output "--------|------|---------|------------"

foreach ($sec in $sections) {
    $id = $sec.Id
    $name = $sec.Name
    
    # Modify bench_section
    $modified = $origContent -replace 'let bench_section : Int = \d+', "let bench_section : Int = $id"
    Set-Content -Path $mainFile -Value $modified -NoNewline
    
    # Build
    moon build --target native --release 2>&1 | Out-Null
    
    # Run 3 times, take best
    $bestMs = [double]::MaxValue
    for ($run = 0; $run -lt 3; $run++) {
        $time = Measure-Command { & $exe 2>&1 | Out-Null }
        if ($time.TotalMilliseconds -lt $bestMs) {
            $bestMs = $time.TotalMilliseconds
        }
    }
    
    $ms = [math]::Round($bestMs, 1)
    $perIter = [math]::Round($bestMs / 5000 * 1000, 2)
    
    Write-Output "$id | $name | $ms | $perIter"
}

# Restore original
Set-Content -Path $mainFile -Value $origContent -NoNewline
Write-Output ""
Write-Output "Benchmark complete. Original file restored."
