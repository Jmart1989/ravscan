@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

:: ========================================
::      RAVSCAN
:: ========================================
set "VERSION=1.0.0"
set "SCRIPT_DIR=%~dp0"
set "DATA_DIR=%SCRIPT_DIR%data"
set "LOG_DIR=%SCRIPT_DIR%logs"
set "LOG_FILE=%LOG_DIR%\ravscan_%DATE:/=_%_%TIME::=_%.log"

:: -- Formato da data/hora para o log --
for /f "tokens=1-3 delims=/" %%a in ("%DATE%") do (
    set "LOG_DATE=%%c%%a%%b"
)
set "LOG_DATE=%LOG_DATE: =0%"
set "LOG_TIME=%TIME::=%"
set "LOG_TIME=%LOG_TIME:.=%"
set "LOG_TIME=%LOG_TIME: =0%"
set "LOG_FILE=%LOG_DIR%\ravscan_%LOG_DATE%_%LOG_TIME%.log"

:: -- Criar diretórios necessários --
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%" >nul 2>&1
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1

:: -- Configurações iniciais --
set "MODE=interactive"
set "AUTO_REMOVE=0"
set "DEBUG=0"
set "SILENT=0"
set "LOG_ENABLED=1"
set "SHOW_ALL=1"
set "COLOR_ENABLED=1"
set "SCAN_DEPTH=3"

:: -- Inicializar arquivos de dados --
call :initialize_data_files

:: -- Processar argumentos --
:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="--remove" set "AUTO_REMOVE=1" & shift & goto parse_args
if /i "%~1"=="-r" set "AUTO_REMOVE=1" & shift & goto parse_args
if /i "%~1"=="--debug" set "DEBUG=1" & shift & goto parse_args
if /i "%~1"=="--silent" set "SILENT=1" & shift & goto parse_args
if /i "%~1"=="--log" set "LOG_ENABLED=1" & shift & goto parse_args
if /i "%~1"=="--no-log" set "LOG_ENABLED=0" & shift & goto parse_args
if /i "%~1"=="--all" set "SHOW_ALL=1" & shift & goto parse_args
if /i "%~1"=="--minimal" set "SHOW_ALL=0" & shift & goto parse_args
if /i "%~1"=="--no-color" set "COLOR_ENABLED=0" & shift & goto parse_args
if /i "%~1"=="--color" set "COLOR_ENABLED=1" & shift & goto parse_args
if /i "%~1"=="scan" set "MODE=scan" & shift & goto parse_args
if /i "%~1"=="quick" set "MODE=quick" & shift & goto parse_args
if /i "%~1"=="stats" set "MODE=stats" & shift & goto parse_args
if /i "%~1"=="help" set "MODE=help" & shift & goto parse_args
if /i "%~1"=="version" set "MODE=version" & shift & goto parse_args
if /i "%~1"=="menu" set "MODE=interactive" & shift & goto parse_args
shift
goto parse_args

:args_done

:: -- Iniciar logging se habilitado --
if "!LOG_ENABLED!"=="1" (
    echo [%DATE% %TIME%] RAVSCAN v%VERSION% iniciado > "!LOG_FILE!"
    echo [%DATE% %TIME%] Modo: !MODE! >> "!LOG_FILE!"
    echo [%DATE% %TIME%] Auto-remove: !AUTO_REMOVE! >> "!LOG_FILE!"
)

:: -- Executar modo selecionado --
if "!MODE!"=="version" goto :show_version
if "!MODE!"=="help" goto :show_help
if "!MODE!"=="stats" goto :show_stats
if "!MODE!"=="quick" goto :quick_scan
if "!MODE!"=="scan" goto :full_scan
if "!MODE!"=="interactive" goto :interactive_menu

goto :interactive_menu

:: ========================================
::      MENU INTERATIVO
:: ========================================

:interactive_menu
call :clear_screen
call :show_banner
echo.
call :print_center "MENU PRINCIPAL - v%VERSION%" "36"
echo.
call :print_box "Selecione uma opcao:" "36"
echo.
call :print_option "1" "Verificacao Completa do Sistema" "Scan completo de processos, arquivos e conexoes"
call :print_option "2" "Verificacao Rapida" "Scan apenas de processos em execucao"
call :print_option "3" "Estatisticas e Relatorios" "Mostra dados das listas e historico"
call :print_option "4" "Configuracoes" "Configurar opcoes do scanner"
call :print_option "5" "Sobre / Ajuda" "Informacoes e instrucoes de uso"
call :print_option "0" "Sair" "Encerrar aplicacao"
echo.
call :print_line "36"
set /p "CHOICE=   [~] Selecione uma opcao [0-5]: "

if "!CHOICE!"=="0" goto :exit_script
if "!CHOICE!"=="1" goto :full_scan
if "!CHOICE!"=="2" goto :quick_scan
if "!CHOICE!"=="3" goto :show_stats
if "!CHOICE!"=="4" goto :config_menu
if "!CHOICE!"=="5" goto :show_help

goto :interactive_menu

:config_menu
call :clear_screen
call :show_banner
echo.
call :print_center "CONFIGURACOES DO SISTEMA" "36"
echo.
call :print_box "Opcoes atuais de configuracao:" "36"
echo.
call :print_config "Remocao Automatica" "!AUTO_REMOVE!" "Remove ameacas automaticamente"
call :print_config "Modo Debug" "!DEBUG!" "Exibe informacoes tecnicas detalhadas"
call :print_config "Sistema de Log" "!LOG_ENABLED!" "Registra atividades em arquivo"
call :print_config "Mostrar Tudo" "!SHOW_ALL!" "Exibe todos os resultados"
call :print_config "Cores e Efeitos" "!COLOR_ENABLED!" "Interface colorida e visual"
echo.
call :print_line "36"
echo.
echo   [1] Alternar Remocao Automatica
echo   [2] Alternar Modo Debug
echo   [3] Alternar Sistema de Log
echo   [4] Alternar Mostrar Tudo
echo   [5] Alternar Cores e Efeitos
echo   [6] Restaurar Padroes
echo   [7] Voltar ao Menu Principal
echo.
call :print_line "36"
set /p "CONFIG_CHOICE=   [~] Selecione uma opcao [1-7]: "

if "!CONFIG_CHOICE!"=="1" (
    if "!AUTO_REMOVE!"=="0" (set "AUTO_REMOVE=1") else (set "AUTO_REMOVE=0")
    goto :config_menu
)
if "!CONFIG_CHOICE!"=="2" (
    if "!DEBUG!"=="0" (set "DEBUG=1") else (set "DEBUG=0")
    goto :config_menu
)
if "!CONFIG_CHOICE!"=="3" (
    if "!LOG_ENABLED!"=="0" (set "LOG_ENABLED=1") else (set "LOG_ENABLED=0")
    goto :config_menu
)
if "!CONFIG_CHOICE!"=="4" (
    if "!SHOW_ALL!"=="0" (set "SHOW_ALL=1") else (set "SHOW_ALL=0")
    goto :config_menu
)
if "!CONFIG_CHOICE!"=="5" (
    if "!COLOR_ENABLED!"=="0" (set "COLOR_ENABLED=1") else (set "COLOR_ENABLED=0")
    goto :config_menu
)
if "!CONFIG_CHOICE!"=="6" (
    set "AUTO_REMOVE=0"
    set "DEBUG=0"
    set "LOG_ENABLED=1"
    set "SHOW_ALL=1"
    set "COLOR_ENABLED=1"
    goto :config_menu
)
if "!CONFIG_CHOICE!"=="7" goto :interactive_menu
goto :config_menu

:: ========================================
::      FUNÇÕES PRINCIPAIS DE SCAN
:: ========================================

:full_scan
call :clear_screen
call :show_banner
echo.
call :print_center "VERIFICACAO COMPLETA DO SISTEMA" "32"
echo.
call :print_box "Iniciando scanner completo..." "32"

set /a "TOTAL_FOUND=0"
set /a "PROCESS_FOUND=0"
set /a "FILE_FOUND=0"
set /a "CONNECTION_FOUND=0"
set /a "PERSISTENCE_FOUND=0"
set /a "ITEMS_REMOVED=0"

:: 1. Verificar processos maliciosos
call :scan_section "PROCESSOS MALICIOSOS" "1" "4" "36"
call :read_process_list

if "!PROCESS_COUNT!"=="0" (
    call :show_warning "Nenhum processo na lista de monitoramento"
) else (
    call :show_info "Verificando !PROCESS_COUNT! processos..."
    for /f "tokens=1* delims=:" %%a in ('echo !PROCESS_LIST!') do (
        if not "%%a"=="" (
            set "CURRENT_PROCESS=%%a"
            call :show_debug "Analisando processo: !CURRENT_PROCESS!"
            call :check_process "!CURRENT_PROCESS!"
            if !PROCESS_RUNNING! equ 1 (
                call :show_threat "PROCESSO MALICIOSO" "!CURRENT_PROCESS!" "Em execucao - PID: !PROCESS_PID!"
                set /a "TOTAL_FOUND+=1"
                set /a "PROCESS_FOUND+=1"
                
                if "!LOG_ENABLED!"=="1" (
                    echo [%DATE% %TIME%] PROCESSO_ENCONTRADO: !CURRENT_PROCESS! - PID: !PROCESS_PID! >> "!LOG_FILE!"
                )
                
                call :kill_process "!CURRENT_PROCESS!"
                if !ERRORLEVEL! equ 0 (
                    call :show_success_item "Processo finalizado: !CURRENT_PROCESS! (PID: !PROCESS_PID!)"
                    set /a "ITEMS_REMOVED+=1"
                    if "!LOG_ENABLED!"=="1" (
                        echo [%DATE% %TIME%] PROCESSO_FINALIZADO: !CURRENT_PROCESS! - PID: !PROCESS_PID! >> "!LOG_FILE!"
                    )
                ) else (
                    call :show_error "Falha ao finalizar processo: !CURRENT_PROCESS!"
                )
            ) else (
                if "!SHOW_ALL!"=="1" call :show_clean "Processo limpo: !CURRENT_PROCESS!" "Nao esta em execucao"
            )
        )
    )
    call :show_success "Verificacao de processos concluida - Encontrados: !PROCESS_FOUND!"
)

:: 2. Verificar arquivos maliciosos
call :scan_section "ARQUIVOS MALICIOSOS" "2" "4" "36"
call :read_file_list

if "!FILE_COUNT!"=="0" (
    call :show_warning "Nenhum arquivo na lista de monitoramento"
) else (
    call :show_info "Buscando !FILE_COUNT! padroes de arquivos..."
    for /f "tokens=1* delims=:" %%a in ('echo !FILE_LIST!') do (
        if not "%%a"=="" (
            set "CURRENT_PATTERN=%%a"
            call :show_debug "Procurando por: !CURRENT_PATTERN!"
            call :find_files "!CURRENT_PATTERN!"
            if !FILES_FOUND! gtr 0 (
                call :show_threat "ARQUIVO MALICIOSO" "!CURRENT_PATTERN!" "!FILES_FOUND! instancia(s) encontrada(s)"
                set /a "TOTAL_FOUND+=!FILES_FOUND!"
                set /a "FILE_FOUND+=!FILES_FOUND!"
                
                if "!AUTO_REMOVE!"=="1" (
                    call :remove_found_files
                    set /a "ITEMS_REMOVED+=!FILES_FOUND!"
                )
            ) else (
                if "!SHOW_ALL!"=="1" call :show_clean "Arquivo nao encontrado: !CURRENT_PATTERN!" "Padrao limpo"
            )
        )
    )
    call :show_success "Verificacao de arquivos concluida - Encontrados: !FILE_FOUND!"
)

:: 3. Verificar conexões de rede
call :scan_section "CONEXOES DE REDE" "3" "4" "36"
call :read_ip_list

if "!IP_COUNT!"=="0" (
    call :show_warning "Nenhum IP na lista de monitoramento"
) else (
    call :show_info "Monitorando !IP_COUNT! enderecos IP..."
    for /f "tokens=1* delims=:" %%a in ('echo !IP_LIST!') do (
        if not "%%a"=="" (
            set "CURRENT_IP=%%a"
            call :show_debug "Verificando conexoes para: !CURRENT_IP!"
            call :check_ip_connection "!CURRENT_IP!"
            if !IP_CONNECTED! equ 1 (
                call :show_critical "CONEXAO ATIVA DETECTADA" "IP: !CURRENT_IP!" "ALERTA CRITICO"
                set /a "TOTAL_FOUND+=1"
                set /a "CONNECTION_FOUND+=1"
                if "!LOG_ENABLED!"=="1" (
                    echo [%DATE% %TIME%] CONEXAO_SUSPEITA: !CURRENT_IP! >> "!LOG_FILE!"
                )
            ) else (
                if "!SHOW_ALL!"=="1" call :show_clean "Sem conexao ativa para: !CURRENT_IP!" "Conexao limpa"
            )
        )
    )
    call :show_success "Verificacao de conexoes concluida - Encontradas: !CONNECTION_FOUND!"
)

:: 4. Verificar persistência
call :scan_section "MECANISMOS DE PERSISTENCIA" "4" "4" "36"
call :check_persistence
set /a "PERSISTENCE_FOUND=!PERSISTENCE_COUNT!"

:: Relatório final
call :generate_report

if "!MODE!"=="interactive" (
    echo.
    call :pause_and_continue
    goto :interactive_menu
)
goto :exit_script

:quick_scan
call :clear_screen
call :show_banner
echo.
call :print_center "VERIFICACAO RAPIDA - PROCESSOS" "33"
echo.
call :print_box "Analisando processos em execucao..." "33"

call :read_process_list
set /a "FOUND=0"
set /a "KILLED=0"

if "!PROCESS_COUNT!"=="0" (
    call :show_warning "Nenhum processo na lista de monitoramento"
) else (
    call :show_info "Verificando !PROCESS_COUNT! processos rapidamente..."
    for /f "tokens=1* delims=:" %%a in ('echo !PROCESS_LIST!') do (
        if not "%%a"=="" (
            set "CURRENT_PROCESS=%%a"
            call :show_debug "Processo: !CURRENT_PROCESS!"
            call :check_process "!CURRENT_PROCESS!"
            if !PROCESS_RUNNING! equ 1 (
                call :show_threat "PROCESSO MALICIOSO" "!CURRENT_PROCESS!" "Em execucao - PID: !PROCESS_PID!"
                set /a "FOUND+=1"
                
                call :kill_process "!CURRENT_PROCESS!"
                if !ERRORLEVEL! equ 0 (
                    call :show_success_item "Processo finalizado: !CURRENT_PROCESS! (PID: !PROCESS_PID!)"
                    set /a "KILLED+=1"
                ) else (
                    call :show_error "Falha ao finalizar processo: !CURRENT_PROCESS!"
                )
            ) else (
                if "!SHOW_ALL!"=="1" call :show_clean "Processo limpo: !CURRENT_PROCESS!" "Nao esta em execucao"
            )
        )
    )
    call :show_success "Verificacao rapida concluida"
)

echo.
call :print_box "RESUMO DA VERIFICACAO RAPIDA" "36"
echo.
call :print_stat "Processos verificados:" "!PROCESS_COUNT!" "36"
call :print_stat "Processos suspeitos:" "!FOUND!" "33"
call :print_stat "Processos finalizados:" "!KILLED!" "32"

if "!FOUND!"=="0" (
    call :show_success "Nenhum processo malicioso encontrado!"
) else (
    if "!KILLED!"=="!FOUND!" (
        call :show_success "Todos os processos maliciosos foram finalizados!"
    ) else (
        call :show_warning "Apenas !KILLED! de !FOUND! processos foram finalizados"
    )
)

if "!MODE!"=="interactive" (
    echo.
    call :pause_and_continue
    goto :interactive_menu
)
goto :exit_script

:: ========================================
::      FUNÇÕES UTILITÁRIAS
:: ========================================

:read_process_list
set "PROCESS_LIST="
set /a "PROCESS_COUNT=0"
if exist "%DATA_DIR%\processos.txt" (
    for /f "usebackq tokens=*" %%i in ("%DATA_DIR%\processos.txt") do (
        set "line=%%i"
        set "line=!line: =!"
        if not "!line!"=="" if not "!line:~0,1!"=="#" (
            set "PROCESS_LIST=!PROCESS_LIST!:!line!"
            set /a "PROCESS_COUNT+=1"
        )
    )
)
goto :eof

:read_file_list
set "FILE_LIST="
set /a "FILE_COUNT=0"
if exist "%DATA_DIR%\arquivos.txt" (
    for /f "usebackq tokens=*" %%i in ("%DATA_DIR%\arquivos.txt") do (
        set "line=%%i"
        set "line=!line: =!"
        if not "!line!"=="" if not "!line:~0,1!"=="#" (
            set "FILE_LIST=!FILE_LIST!:!line!"
            set /a "FILE_COUNT+=1"
        )
    )
)
goto :eof

:read_ip_list
set "IP_LIST="
set /a "IP_COUNT=0"
if exist "%DATA_DIR%\ips.txt" (
    for /f "usebackq tokens=*" %%i in ("%DATA_DIR%\ips.txt") do (
        set "line=%%i"
        set "line=!line: =!"
        if not "!line!"=="" if not "!line:~0,1!"=="#" (
            set "IP_LIST=!IP_LIST!:!line!"
            set /a "IP_COUNT+=1"
        )
    )
)
goto :eof

:check_process
set "PROCESS_RUNNING=0"
set "PROCESS_PID=0"
for /f "tokens=2" %%p in ('tasklist /fi "imagename eq %~1" 2^>nul ^| find /i "%~1"') do (
    set "PROCESS_RUNNING=1"
    set "PROCESS_PID=%%p"
)
goto :eof

:kill_process
taskkill /f /im "%~1" >nul 2>&1
goto :eof

:find_files
set "PATTERN=%~1"
set /a "FILES_FOUND=0"
set "FOUND_FILES="
call :show_debug "Buscando padrao: !PATTERN!"

:: Locais de busca
set "SCAN_LOCATIONS=%USERPROFILE%\Desktop %USERPROFILE%\Downloads %TEMP% %APPDATA% %PROGRAMDATA% C:\Windows\Temp"

for %%D in (!SCAN_LOCATIONS!) do (
    if exist "%%D" (
        for /f "delims=" %%F in ('dir "%%D\!PATTERN!" /b /s /a-d 2^>nul') do (
            set /a "FILES_FOUND+=1"
            set "FOUND_FILES=!FOUND_FILES!%%F:"
            call :show_debug "Encontrado: %%F"
        )
    )
)
goto :eof

:remove_found_files
set /a "REMOVED_COUNT=0"
for /f "tokens=1* delims=:" %%A in ('echo !FOUND_FILES!') do (
    if not "%%A"=="" (
        call :show_debug "Removendo arquivo: %%A"
        del /f /q "%%A" >nul 2>&1
        if !ERRORLEVEL! equ 0 (
            call :show_success_item "Arquivo removido: %%A"
            set /a "REMOVED_COUNT+=1"
            if "!LOG_ENABLED!"=="1" (
                echo [%DATE% %TIME%] ARQUIVO_REMOVIDO: %%A >> "!LOG_FILE!"
            )
        ) else (
            call :show_error "Falha ao remover: %%A"
        )
    )
)
goto :eof

:check_ip_connection
set "IP_CONNECTED=0"
for /f "tokens=1-5" %%a in ('netstat -ano ^| findstr /R /C:"[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"') do (
    echo %%a %%b %%c %%d | findstr /C:"%~1" >nul && set "IP_CONNECTED=1"
)
goto :eof

:check_persistence
set /a "PERSISTENCE_COUNT=0"
set "PERSISTENCE_FOUND="
call :show_info "Verificando mecanismos de persistencia..."

:: Locais comuns de persistência
set "PERSISTENCE_LOCATIONS=%USERPROFILE%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup %APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup %PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\StartUp"

call :read_file_list
for %%D in (!PERSISTENCE_LOCATIONS!) do (
    if exist "%%D" (
        for /f "tokens=1* delims=:" %%F in ('echo !FILE_LIST!') do (
            if not "%%F"=="" (
                for /f "delims=" %%A in ('dir "%%D\%%F" /b 2^>nul') do (
                    set /a "PERSISTENCE_COUNT+=1"
                    call :show_threat "PERSISTENCIA" "%%D\%%A" "Mecanismo de inicializacao automatica"
                    set "PERSISTENCE_FOUND=!PERSISTENCE_FOUND!%%D\%%A:"
                )
            )
        )
    )
)

:: Verificar também no registro
call :check_registry_persistence
goto :eof

:check_registry_persistence
call :show_debug "Verificando registro para persistencia..."
:: Esta função pode ser expandida para verificar Run keys no registro
goto :eof

:generate_report
echo.
call :print_box "RELATORIO FINAL DE VERIFICACAO" "36"
echo.
call :print_stat "Processos verificados:" "!PROCESS_COUNT!" "36"
call :print_stat "Processos maliciosos:" "!PROCESS_FOUND!" "31"
call :print_stat "Arquivos verificados:" "!FILE_COUNT!" "36"
call :print_stat "Arquivos maliciosos:" "!FILE_FOUND!" "31"
call :print_stat "IPs verificados:" "!IP_COUNT!" "36"
call :print_stat "Conexoes maliciosas:" "!CONNECTION_FOUND!" "31"
call :print_stat "Mecanismos de persistencia:" "!PERSISTENCE_FOUND!" "31"
echo.
call :print_line "36"

if !TOTAL_FOUND! equ 0 (
    call :show_success "SISTEMA LIMPO - Nenhuma ameaca detectada!"
) else (
    call :show_critical "ALERTA DE SEGURANCA" "!TOTAL_FOUND! ameacas detectadas!" "CRITICO"
    echo.
    call :print_box "ACOES REALIZADAS:" "33"
    echo.
    if "!AUTO_REMOVE!"=="1" (
        if !ITEMS_REMOVED! gtr 0 (
            call :show_success "!ITEMS_REMOVED! itens foram removidos automaticamente"
        ) else (
            call :show_warning "Nenhum item pode ser removido automaticamente"
        )
    ) else (
        call :show_warning "Modo de remocao automatica desativado"
        echo   • Use '--remove' para remocao automatica de ameacas
    )
    echo.
    call :print_box "ACOES RECOMENDADAS:" "31"
    echo.
    echo   • Desconecte-se da internet imediatamente
    echo   • Execute verificacao com antivirus
    echo   • Altere suas senhas importantes
    echo   • Monitore extratos bancarios
    echo   • Backup de arquivos importantes
)

if "!LOG_ENABLED!"=="1" (
    call :show_info "Log completo salvo em: !LOG_FILE!"
)
goto :eof

:show_stats
call :clear_screen
call :show_banner
echo.
call :print_center "ESTATISTICAS E RELATORIOS" "36"
echo.
call :print_box "Dados das listas de monitoramento" "36"
echo.

call :read_process_list
call :print_stat "Processos na lista:" "!PROCESS_COUNT!" "36"
if "!SHOW_ALL!"=="1" if "!PROCESS_COUNT!" gtr 0 (
    echo    Lista de processos:
    for /f "tokens=1* delims=:" %%a in ('echo !PROCESS_LIST!') do (
        if not "%%a"=="" echo      - %%a
    )
    echo.
)

call :read_file_list
call :print_stat "Arquivos na lista:" "!FILE_COUNT!" "36"
if "!SHOW_ALL!"=="1" if "!FILE_COUNT!" gtr 0 (
    echo    Lista de arquivos:
    for /f "tokens=1* delims=:" %%a in ('echo !FILE_LIST!') do (
        if not "%%a"=="" echo      - %%a
    )
    echo.
)

call :read_ip_list
call :print_stat "IPs na lista:" "!IP_COUNT!" "36"
if "!SHOW_ALL!"=="1" if "!IP_COUNT!" gtr 0 (
    echo    Lista de IPs:
    for /f "tokens=1* delims=:" %%a in ('echo !IP_LIST!') do (
        if not "%%a"=="" echo      - %%a
    )
    echo.
)

:: Mostrar informações do sistema
echo.
call :print_box "INFORMACOES DO SISTEMA" "33"
echo.
for /f "tokens=1-2" %%a in ('systeminfo ^| findstr /C:"Nome do sistema"') do echo    Sistema: %%b
for /f "tokens=1-2" %%a in ('systeminfo ^| findstr /C:"Nome do host"') do echo    Computador: %%b
for /f "tokens=*" %%a in ('echo %USERNAME%') do echo    Usuario: %%a
for /f "tokens=*" %%a in ('echo %DATE% %TIME%') do echo    Data/Hora: %%a

if "!MODE!"=="interactive" (
    echo.
    call :pause_and_continue
    goto :interactive_menu
)
goto :exit_script

:show_version
call :clear_screen
call :show_banner
echo.
call :print_center "INFORMACOES DA VERSAO" "32"
echo.
call :print_box "RAVSCAN Professional v%VERSION%" "32"
echo.
echo    Desenvolvido para deteccao de malwares brasileiros
echo    Foco em ameacas como Sorvetepotel e similares
echo.
echo    Caracteristicas:
echo      • Scanner baseado em listas personalizaveis
echo      • Interface profissional com sistema de cores
echo      • Sistema de logging integrado
echo      • Remocao automatica opcional
echo      • Verificacao de persistencia
echo.
if "!MODE!"=="interactive" (
    call :pause_and_continue
    goto :interactive_menu
)
goto :exit_script

:show_help
call :clear_screen
call :show_banner
echo.
call :print_center "AJUDA E INSTRUCOES" "36"
echo.
call :print_box "Como usar RAVSCAN" "36"
echo.
echo    [MODO INTERATIVO]
echo      ravscan.cmd          - Menu principal com numeros
echo      ravscan.cmd menu     - Menu principal com numeros
echo.
echo    [MODO COMANDO DIRETO]
echo      ravscan.cmd scan     - Verificacao completa
echo      ravscan.cmd quick    - Verificacao rapida
echo      ravscan.cmd stats    - Estatisticas
echo      ravscan.cmd help     - Ajuda
echo      ravscan.cmd version  - Versao
echo.
echo    OPCOES AVANCADAS:
echo      --remove, -r     - Remove ameacas automaticamente
echo      --debug          - Modo detalhado
echo      --log            - Ativa logging
echo      --no-log         - Desativa logging
echo      --all            - Mostra todos os resultados
echo      --minimal        - Mostra apenas ameacas
echo      --no-color       - Interface sem cores
echo      --color          - Interface com cores
echo.
echo    EXEMPLOS:
echo      ravscan.cmd scan --remove --log
echo      ravscan.cmd quick --all
echo      ravscan.cmd stats --minimal
echo.
call :print_box "IMPORTANTE: Edite os arquivos na pasta data para personalizar" "33"
echo.
if "!MODE!"=="interactive" (
    call :pause_and_continue
    goto :interactive_menu
)
goto :exit_script

:: ========================================
::      FUNÇÕES DE INTERFACE COM CORES
:: ========================================

:clear_screen
cls
goto :eof

:show_banner
echo.
echo              ██████╗  █████╗ ██╗   ██╗███████╗ ██████╗ █████╗ ███╗   ██╗
echo              ██╔══██╗██╔══██╗██║   ██║██╔════╝██╔════╝██╔══██╗████╗  ██║
echo              ██████╔╝███████║██║   ██║███████╗██║     ███████║██╔██╗ ██║
echo              ██╔══██╗██╔══██║██║   ██║╚════██║██║     ██╔══██║██║╚██╗██║
echo              ██║  ██║██║  ██║╚██████╔╝███████║╚██████╗██║  ██║██║ ╚████║
echo              ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝
echo.
goto :eof

:print_center
set "text=%~1"
set "color=%~2"
set /a "width=80"
set /a "len=0"
for /f "delims=" %%i in ('cmd /u /c echo %text%^|find /v ""') do set /a "len+=1"
set /a "padding=(width-len)/2"
set "spaces="
for /l %%i in (1,1,!padding!) do set "spaces=!spaces! "
if "!COLOR_ENABLED!"=="1" (
    if "!color!"=="31" echo !spaces![91m!text![0m
    if "!color!"=="32" echo !spaces![92m!text![0m
    if "!color!"=="33" echo !spaces![93m!text![0m
    if "!color!"=="34" echo !spaces![94m!text![0m
    if "!color!"=="35" echo !spaces![95m!text![0m
    if "!color!"=="36" echo !spaces![96m!text![0m
    if "!color!"=="" echo !spaces!!text!
) else (
    echo !spaces!!text!
)
goto :eof

:print_box
set "text=%~1"
set "color=%~2"
set "line="
set /a "length=70"
for /l %%i in (1,1,!length!) do set "line=!line!═"
if "!COLOR_ENABLED!"=="1" (
    if "!color!"=="31" (
        echo ┌!line!┐
        echo │   [91m!text![0m
        echo └!line!┘
    ) else if "!color!"=="32" (
        echo ┌!line!┐
        echo │   [92m!text![0m
        echo └!line!┘
    ) else if "!color!"=="33" (
        echo ┌!line!┐
        echo │   [93m!text![0m
        echo └!line!┘
    ) else if "!color!"=="36" (
        echo ┌!line!┐
        echo │   [96m!text![0m
        echo └!line!┘
    ) else (
        echo ┌!line!┐
        echo │   !text!
        echo └!line!┘
    )
) else (
    echo ┌!line!┐
    echo │   !text!
    echo └!line!┘
)
goto :eof

:print_line
set "color=%~1"
set "line="
for /l %%i in (1,1,78) do set "line=!line!─"
if "!COLOR_ENABLED!"=="1" (
    if "!color!"=="31" echo [91m!line![0m
    if "!color!"=="32" echo [92m!line![0m
    if "!color!"=="33" echo [93m!line![0m
    if "!color!"=="36" echo [96m!line![0m
    if "!color!"=="" echo !line!
) else (
    echo !line!
)
goto :eof

:print_option
set "num=%~1"
set "title=%~2"
set "desc=%~3"
if "!COLOR_ENABLED!"=="1" (
    echo    [93m[!num!][0m [97m!title![0m
    echo        [90m!desc![0m
) else (
    echo    [!num!] !title!
    echo        !desc!
)
echo.
goto :eof

:print_config
set "name=%~1"
set "value=%~2"
set "desc=%~3"
if "!value!"=="1" (
    if "!COLOR_ENABLED!"=="1" (
        echo    [92m!name!: [ATIVADO][0m  - !desc!
    ) else (
        echo    !name!: [ATIVADO]  - !desc!
    )
) else (
    if "!COLOR_ENABLED!"=="1" (
        echo    [91m!name!: [DESATIVADO][0m - !desc!
    ) else (
        echo    !name!: [DESATIVADO] - !desc!
    )
)
goto :eof

:print_stat
set "label=%~1"
set "value=%~2"
set "color=%~3"
if "!COLOR_ENABLED!"=="1" (
    if "!color!"=="31" echo    !label! [91m!value![0m
    if "!color!"=="32" echo    !label! [92m!value![0m
    if "!color!"=="33" echo    !label! [93m!value![0m
    if "!color!"=="36" echo    !label! [96m!value![0m
    if "!color!"=="" echo    !label! !value!
) else (
    echo    !label! !value!
)
goto :eof

:scan_section
set "title=%~1"
set "current=%~2"
set "total=%~3"
set "color=%~4"
echo.
call :print_box "[!current!/!total!] !title!" "!color!"
goto :eof

:show_threat
set "type=%~1"
set "target=%~2"
set "info=%~3"
if "!COLOR_ENABLED!"=="1" (
    echo    [91m🔴 [AMEAÇA] !type![0m
    echo        [97mAlvo:[0m [91m!target![0m
    echo        [97mInfo:[0m [93m!info![0m
) else (
    echo    🔴 [AMEAÇA] !type!
    echo        Alvo: !target!
    echo        Info: !info!
)
echo.
goto :eof

:show_critical
set "type=%~1"
set "target=%~2"
set "info=%~3"
if "!COLOR_ENABLED!"=="1" (
    echo    [91m🚨🚨🚨 [CRÍTICO] !type![0m
    echo        [97m!target![0m
    echo        [91m!info![0m
) else (
    echo    🚨🚨🚨 [CRÍTICO] !type!
    echo        !target!
    echo        !info!
)
echo.
goto :eof

:show_clean
set "type=%~1"
set "target=%~2"
if "!SHOW_ALL!"=="1" (
    if "!COLOR_ENABLED!"=="1" (
        echo    [92m🟢 [LIMPO] !type![0m
        echo        [92m!target![0m
    ) else (
        echo    🟢 [LIMPO] !type!
        echo        !target!
    )
    echo.
)
goto :eof

:show_success_item
set "message=%~1"
if "!COLOR_ENABLED!"=="1" (
    echo    [92m   ✅ !message![0m
) else (
    echo    ✅ !message!
)
goto :eof

:show_success
set "message=%~1"
if "!COLOR_ENABLED!"=="1" (
    echo    [92m✅ [SUCESSO] !message![0m
) else (
    echo    ✅ [SUCESSO] !message!
)
goto :eof

:show_warning
set "message=%~1"
if "!COLOR_ENABLED!"=="1" (
    echo    [93m⚠️  [AVISO] !message![0m
) else (
    echo    ⚠️  [AVISO] !message!
)
goto :eof

:show_info
set "message=%~1"
if "!COLOR_ENABLED!"=="1" (
    echo    [96mℹ️  [INFO] !message![0m
) else (
    echo    ℹ️  [INFO] !message!
)
goto :eof

:show_debug
set "message=%~1"
if "!DEBUG!"=="1" (
    if "!COLOR_ENABLED!"=="1" (
        echo    [90m   🔧 !message![0m
    ) else (
        echo    🔧 !message!
    )
)
goto :eof

:show_error
set "message=%~1"
if "!COLOR_ENABLED!"=="1" (
    echo    [91m❌ [ERRO] !message![0m
) else (
    echo    ❌ [ERRO] !message!
)
goto :eof

:pause_and_continue
echo.
set /p "=   Pressione qualquer tecla para continuar..." < nul > nul
pause > nul
echo.
goto :eof

:exit_script
if "!LOG_ENABLED!"=="1" (
    echo [%DATE% %TIME%] RAVSCAN finalizado >> "!LOG_FILE!"
)
endlocal
exit /b 0

:: ========================================
::      INICIALIZAÇÃO DE ARQUIVOS
:: ========================================

:initialize_data_files
if not exist "%DATA_DIR%\processos.txt" (
    echo # Lista de processos maliciosos conhecidos > "%DATA_DIR%\processos.txt"
    echo # Adicione um processo por linha >> "%DATA_DIR%\processos.txt"
    echo # Linhas começando com # são comentários >> "%DATA_DIR%\processos.txt"
    echo. >> "%DATA_DIR%\processos.txt"
    echo HealthApp-0d97b7.bat >> "%DATA_DIR%\processos.txt"
    echo malware.exe >> "%DATA_DIR%\processos.txt"
    echo virus.bat >> "%DATA_DIR%\processos.txt"
)

if not exist "%DATA_DIR%\arquivos.txt" (
    echo # Lista de arquivos maliciosos conhecidos > "%DATA_DIR%\arquivos.txt"
    echo # Adicione um padrao de arquivo por linha >> "%DATA_DIR%\arquivos.txt"
    echo # Linhas começando com # são comentários >> "%DATA_DIR%\arquivos.txt"
    echo. >> "%DATA_DIR%\arquivos.txt"
    echo ComprovanteSantander-*.lnk >> "%DATA_DIR%\arquivos.txt"
    echo HealthApp-*.bat >> "%DATA_DIR%\arquivos.txt"
    echo DOC-*.lnk >> "%DATA_DIR%\arquivos.txt"
    echo *.scr >> "%DATA_DIR%\arquivos.txt"
)

if not exist "%DATA_DIR%\ips.txt" (
    echo # Lista de IPs maliciosos conhecidos > "%DATA_DIR%\ips.txt"
    echo # Adicione um IP por linha >> "%DATA_DIR%\ips.txt"
    echo # Linhas começando com # são comentários >> "%DATA_DIR%\ips.txt"
    echo. >> "%DATA_DIR%\ips.txt"
    echo 109.176.30.141 >> "%DATA_DIR%\ips.txt"
    echo 165.154.254.44 >> "%DATA_DIR%\ips.txt"
    echo 23.227.203.148 >> "%DATA_DIR%\ips.txt"
    echo 77.111.101.169 >> "%DATA_DIR%\ips.txt"
    echo expansiveuser[.]com >> "%DATA_DIR%\ips.txt"
    echo sorvetenopote[.]com >> "%DATA_DIR%\ips.txt"
    echo imobiliariaricardoparanhos[.]com >> "%DATA_DIR%\ips.txt"
    echo zapgrande[.]com >> "%DATA_DIR%\ips.txt"
    echo casadecampoamazonas[.]com >> "%DATA_DIR%\ips.txt"
    echo expansivebot[.]com >> "%DATA_DIR%\ips.txt"
)
goto :eof