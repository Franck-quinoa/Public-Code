@echo off
robocopy /LOG:"%temp%\robocopy.log" "%source_path%" "%destination_path%" /B /copy:attrs /progress /quiet /y /r /TEE

if %ERRORLEVEL% neq 0 (
    echo [Robocopy Error] > "%temp%\copied_success.txt"
) else (
    echo All files copied successfully > "%temp%\copied_success.txt"
)

echo Copy completed. Check %temp%\copied_success.txt for details.