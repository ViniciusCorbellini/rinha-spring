:: _win_run-test-launcher.bat
:: Versão final com gestão de PID e caminhos de log absolutos.
@echo off
chcp 65001 > nul
setlocal

:: --- Configuração ---
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /format:list') do set DATETIME=%%I
set TIMESTAMP=%DATETIME:~0,8%-%DATETIME:~8,6%
set MAIN_LOG_FILE=%~dp0__%TIMESTAMP%-gatling_logs.txt
set STATS_LOG_FILE=%~dp0__%TIMESTAMP%-docker-stats_logs.txt
set WINDOW_TITLE=Teste_Rinha_Backend-%TIMESTAMP%

echo.
echo ====================================================================
echo               INICIANDO TESTE DE CARGA E MONITORAMENTO
echo ====================================================================
echo.
echo Logs do processo principal serao salvos em: %MAIN_LOG_FILE%
echo Logs do Docker Stats serao salvos em:     %STATS_LOG_FILE%
echo.
echo UMA NOVA JANELA SERA ABERTA PARA EXECUTAR O TESTE.
echo PARA INTERROMPER TUDO, APENAS FECHE A NOVA JANELA.
echo.

if exist stop-logging.flg del stop-logging.flg

:: --- Inicia a Lógica Principal ---
echo Iniciando a janela de teste (via PowerShell)...
start "%WINDOW_TITLE%" powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0_win_run-test-main-logic.ps1" -FinalLogFile "%MAIN_LOG_FILE%"

echo Aguardando a janela de teste ser criada para capturar o seu PID...
set PID=
:find_pid_loop
    for /f "tokens=2 delims=," %%a in ('tasklist /v /fi "WINDOWTITLE eq %WINDOW_TITLE%" /fo csv /nh') do set PID=%%~a
    if defined PID (
        echo Janela de teste encontrada com PID: %PID%
        goto :pid_found
    )
    timeout /t 1 /nobreak > nul
    goto :find_pid_loop

:pid_found
    if not defined PID (
        echo ERRO: Nao foi possivel encontrar o PID da janela de teste. Abortando.
        exit /b 1
    )

:: --- Inicia o Logger, passando o PID ---
echo Iniciando o logger do Docker Stats em segundo plano...
start /B powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0_win_run-test-stats-logger.ps1" -LogFile "%STATS_LOG_FILE%" -ProcessId %PID%

:: --- Monitoriza Ativamente o Processo de Teste ---
echo O teste esta a correr. Este terminal esta a monitorizar.
:wait_for_process_end
    tasklist /fi "PID eq %PID%" | find "%PID%" > nul
    if errorlevel 1 (
        echo Janela de teste foi fechada.
        goto :cleanup_and_exit
    )
    timeout /t 5 /nobreak > nul
    goto :wait_for_process_end

:cleanup_and_exit
echo Finalizando o logger...
echo stop > stop-logging.flg
timeout /t 3 > nul
del stop-logging.flg

echo Processo concluido. Verifique os arquivos de log gerados.
endlocal