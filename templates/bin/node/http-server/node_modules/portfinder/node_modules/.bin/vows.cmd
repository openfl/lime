@IF EXIST "%~dp0\node.exe" (
  "%~dp0\node.exe"  "%~dp0\..\vows\bin\vows" %*
) ELSE (
  node  "%~dp0\..\vows\bin\vows" %*
)