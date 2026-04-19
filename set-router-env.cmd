@echo off
echo =======================================================
echo Saving Copilot Router global configurations...
echo =======================================================

setx OPENAI_BASE_URL "http://localhost:3099/v1"
setx OPENAI_API_KEY "copilot-router-local-key"
setx OPENAI_MODEL "copilot-router-Network"

echo.
echo [Success!] Persistent variables injected into Windows.
echo You can close this file and delete it if you want. 
echo Close any old CMD(s) and open again to take effect!
pause
