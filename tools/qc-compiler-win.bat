@ECHO OFF
cd ../source
echo.
echo ====================
echo  compiling FTE CCQC
echo ====================
echo.
fteqcc-cli-win.exe -srcfile csprogs.src
echo.
echo ====================
echo  compiling FTE SSQC
echo ====================
echo.
fteqcc-cli-win.exe -srcfile ssprogs.src
echo.
echo ====================
echo   compiling PSP QC
echo ====================
echo.
fteqcc-cli-win.exe -srcfile pspprogs.src
echo.
echo ====================
echo  compiling NX-QS QC
echo ====================
echo.
fteqcc-cli-win.exe -srcfile nxprogs.src
pause
