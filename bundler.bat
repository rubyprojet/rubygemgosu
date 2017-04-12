@ECHO OFF
IF NOT "%~f0" == "~f0" GOTO :WinNT
GOTO :EOF
:WinNT
@"C:\Users\emachnic\GitRepos\railsinstaller-windows\stage\Ruby2.2.0\bin\ruby.exe" "%~dpn0" %*
