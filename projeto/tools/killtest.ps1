# Stop only the RetroArch instances started by the test harness (their command line has test\base.cfg)
Get-CimInstance Win32_Process -Filter "Name='retroarch.exe'" | Where-Object { $_.CommandLine -like '*base.cfg*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -Confirm:$false }
