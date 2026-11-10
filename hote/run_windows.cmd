@echo off
setlocal
cd /d "%~dp0"
where gcc >nul 2>&1
if errorlevel 1 (
 echo GCC MinGW/MSYS2 must be installed and available in PATH.
 exit /b 2
)
gcc -std=gnu11 -Wall -Wextra -Werror -O0 -g -I../Core/Inc -o test_evq.exe test_evq.c ../Core/Src/evq.c ../Core/Src/evq_test.c
if errorlevel 1 exit /b 2
(ver & gcc --version) > ../preuves/tests_windows.log
test_evq.exe >> ../preuves/tests_windows.log 2>&1
set "LAB3_TEST_RESULT=%ERRORLEVEL%"
type ../preuves/tests_windows.log
exit /b %LAB3_TEST_RESULT%
