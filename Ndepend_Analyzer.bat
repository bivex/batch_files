@echo off
rem Define paths without quotes in the variable definitions
set NDEPEND_DIR=C:\java\NDepend_2025.1.3.9765
set PROJECT_DIR=%NDEPEND_DIR%\JsonRequest
set PROJECT_FILE=%PROJECT_DIR%\newproject.ndproj
set SOLUTION_FILE=%PROJECT_DIR%\JsonRequest.sln

echo Changing directory to NDepend installation...
cd "%NDEPEND_DIR%"

echo.
echo Recreating NDepend project file (no filters)...
rem The "|" after the solution file ensures no project filters are applied.
rem Quotes are now placed directly around the variables when used in the command.
"%NDEPEND_DIR%\NDepend.Console.exe" /CreateProject "%PROJECT_FILE%" "%SOLUTION_FILE%|"
if %errorlevel% neq 0 (
    echo Error recreating NDepend project. Exiting.
    pause
    exit /b %errorlevel%
)

echo.
echo Building Visual Studio solution...
rem You might need to adjust the path to msbuild.exe if it's not in your PATH.
rem For example: "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\msbuild.exe"
msbuild "%SOLUTION_FILE%" /p:Configuration=Debug
if %errorlevel% neq 0 (
    echo Error building Visual Studio solution. Exiting.
    pause
    exit /b %errorlevel%
)

echo.
echo Running NDepend analysis and keeping XML report files...
rem The /KeepXmlFilesUsedToBuildReport option keeps the detailed XML analysis result.
"%NDEPEND_DIR%\NDepend.Console.exe" "%PROJECT_FILE%" /KeepXmlFilesUsedToBuildReport
if %errorlevel% neq 0 (
    echo Error during NDepend analysis.
    pause
    exit /b %errorlevel%
)

echo.
echo NDepend analysis completed.
echo HTML report is available at: %PROJECT_DIR%\NDependOut\NDependReport.html
echo Detailed XML analysis results are in: %PROJECT_DIR%\NDependOut\
echo.
echo Press any key to exit...
pause
