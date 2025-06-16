@echo off
rem Define paths without quotes in the variable definitions
set CPPDÉPEND_DIR=C:\java\cppdepend2025.1
set PROJECT_DIR=C:\Users\Admin\Desktop\Dev\structscan
set PROJECT_FILE=%PROJECT_DIR%\structscan.cdproj
set SOLUTION_FILE=%PROJECT_DIR%\structscan.sln

echo Changing directory to CppDepend installation...
cd "%CPPDÉPEND_DIR%"

echo.
echo Running CppDepend analysis... (Assumes CppDepend project file already exists)
rem The CppDepend console expects the project file as the first argument.
rem There is no direct equivalent for creating a project file from the command line like NDepend.
"%CPPDÉPEND_DIR%\CppDepend.Console.exe" "%PROJECT_FILE%" /FullAnalysis
if %errorlevel% neq 0 (
    echo Error during CppDepend analysis. Exiting.
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
echo Running CppDepend analysis and keeping XML report files...
rem The /KeepXmlFilesUsedToBuildReport option is NDepend specific.
rem CppDepend keeps analysis results by default in the output directory.
"%CPPDÉPEND_DIR%\CppDepend.Console.exe" "%PROJECT_FILE%" /FullAnalysis
if %errorlevel% neq 0 (
    echo Error during CppDepend analysis.
    pause
    exit /b %errorlevel%
)

echo.
echo CppDepend analysis completed.
echo HTML report is available at: %PROJECT_DIR%\CppDependOut\CppDependReport.html
echo Detailed analysis results are in: %PROJECT_DIR%\CppDependOut\
echo.
echo Press any key to exit...
pause 