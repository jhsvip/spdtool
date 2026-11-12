$ErrorActionPreference = 'Stop'
try {
  & 'E:\user\docs\Trae-CN\temp_20261107_02\probe\shot_any.ps1' `
    -Exe 'E:\user\docs\Trae-CN\temp_20261107_02\probe\run\SPDTool.exe' `
    -Out 'E:\user\docs\Trae-CN\temp_20261107_02\probe\shot_main_auto.png' `
    -ArgList '-' -TitleLike 'SPD' -WaitMs 30000
} catch {
  Write-Output ('TYPE=' + $_.Exception.GetType().FullName)
  Write-Output ('MSG=' + $_.Exception.Message)
  Write-Output ('LINE=' + $_.InvocationInfo.ScriptLineNumber)
}
