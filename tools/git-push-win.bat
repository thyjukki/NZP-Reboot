@echo off
REM get UTC times:
for /f %%a in ('wmic Path Win32_UTCTime get Year^,Month^,Day^,Hour^,Minute^,Second /Format:List ^| findstr "="') do (set %%a)
Set Second=0%Second%
Set Second=%Second:~-2%
Set Minute=0%Minute%
Set Minute=%Minute:~-2%
Set Hour=0%Hour%
Set Hour=%Hour:~-2%
Set Day=0%Day%
Set Day=%Day:~-2%
Set Month=0%Month%
Set Month=%Month:~-2%
set UTCTIME=%Hour%-%Minute%
set UTCDATE=%Year%-%Month%-%Day%
set relevant_shit=%UTCDATE%-%UTCTIME%

echo %relevant_shit% >> ..\pc\nzp\build_date.txt

set /p commit_msg=Commit Message: 
set /p branch_to_push=Branch to push to: 

cd ..\

git add --all
git commit -m "%commit_msg%
git push origin %branch_to_push%
pause