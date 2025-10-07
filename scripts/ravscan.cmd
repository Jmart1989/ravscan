@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

:: Habilitar suporte a cores ANSI no Windows 10+
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
if "%version%" geq "10.0" (
    reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1
)

:: Definir caractere ESC para cores ANSI
for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"

:: ========================================
::      RAVSCAN - Scanner de Segurança
:: ========================================
:: Versão: 1.0.0
:: Descrição: Scanner especializado em detecção de malwares brasileiros
:: Foco: Campanha SORVEPOTEL e similares
:: ========================================

set "VERSION=1.0.1"
set "SCRIPT_DIR=%~dp0"
set "DATA_DIR=%SCRIPT_DIR%data"
set "LOG_DIR=%SCRIPT_DIR%logs"
set "TEMP_DIR=%TEMP%\ravscan_temp"

:: -- Criar diretórios necessários --
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%" >nul 2>&1
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%" >nul 2>&1

:: -- Formato da data/hora para o log --
for /f "tokens=1-3 delims=/" %%a in ("%DATE%") do (
    set "LOG_DATE=%%c%%a%%b"
)
set "LOG_DATE=%LOG_DATE: =0%"
set "LOG_TIME=%TIME::=%"
set "LOG_TIME=%LOG_TIME:.=%"
set "LOG_TIME=%LOG_TIME: =0%"
set "LOG_FILE=%LOG_DIR%\ravscan_%LOG_DATE%_%LOG_TIME%.log"

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
set /a "REGISTRY_FOUND=0"
set /a "ITEMS_REMOVED=0"

:: 1. Verificar processos maliciosos
call :scan_section "PROCESSOS MALICIOSOS" "1" "6" "36"
call :read_process_list

if "!PROCESS_COUNT!"=="0" (
    call :show_warning "Nenhum processo na lista de monitoramento"
    if "!LOG_ENABLED!"=="1" (
        echo [%DATE% %TIME%] ✅ PROCESSOS: Nenhum processo na lista de monitoramento >> "!LOG_FILE!"
    )
) else (
    call :show_info "Verificando !PROCESS_COUNT! processos..."
    if "!LOG_ENABLED!"=="1" (
        echo [%DATE% %TIME%] 🔍 PROCESSOS: Verificando !PROCESS_COUNT! processos... >> "!LOG_FILE!"
    )
    
    set /a "CURRENT_ITEM=0"
    echo !PROCESS_LIST! > "%TEMP_DIR%\process_list.tmp"
    for /f "tokens=* delims=" %%P in ('type "%TEMP_DIR%\process_list.tmp"') do (
        set "TEMP_LINE=%%P"
        call :process_line_by_pipe "!TEMP_LINE!" process
    )
    del "%TEMP_DIR%\process_list.tmp" >nul 2>&1
    
    call :show_success "Verificacao de processos concluida - Encontrados: !PROCESS_FOUND!"
)

:: 2. Verificar arquivos maliciosos
call :scan_section "ARQUIVOS MALICIOSOS" "2" "6" "36"
call :read_file_list

if "!FILE_COUNT!"=="0" (
    call :show_warning "Nenhum arquivo na lista de monitoramento"
    if "!LOG_ENABLED!"=="1" (
        echo [%DATE% %TIME%] ✅ ARQUIVOS: Nenhum arquivo na lista de monitoramento >> "!LOG_FILE!"
    )
) else (
    call :show_info "Buscando !FILE_COUNT! padroes de arquivos..."
    if "!LOG_ENABLED!"=="1" (
        echo [%DATE% %TIME%] 🔍 ARQUIVOS: Buscando !FILE_COUNT! padroes... >> "!LOG_FILE!"
    )
    
    set /a "CURRENT_ITEM=0"
    echo !FILE_LIST! > "%TEMP_DIR%\file_list.tmp"
    for /f "tokens=* delims=" %%F in ('type "%TEMP_DIR%\file_list.tmp"') do (
        set "TEMP_LINE=%%F"
        call :file_line_by_pipe "!TEMP_LINE!" file
    )
    del "%TEMP_DIR%\file_list.tmp" >nul 2>&1
    
    call :show_success "Verificacao de arquivos concluida - Encontrados: !FILE_FOUND!"
)

:: 3. Verificar conexões de rede - SEÇÃO CRÍTICA CORRIGIDA
call :scan_section "CONEXOES DE REDE" "3" "6" "36"

call :read_ip_list
call :read_domain_list

set /a "TOTAL_TARGETS=IP_COUNT+DOMAIN_COUNT"

if "!TOTAL_TARGETS!"=="0" (
    call :show_warning "Nenhum IP/dominio na lista de monitoramento"
    if "!LOG_ENABLED!"=="1" (
        echo [%DATE% %TIME%] ✅ CONEXOES: Nenhum alvo na lista de monitoramento >> "!LOG_FILE!"
    )
) else (
    call :show_info "Verificando !TOTAL_TARGETS! alvos de rede..."
    if "!LOG_ENABLED!"=="1" (
        echo [%DATE% %TIME%] 🔍 CONEXOES: Verificando !TOTAL_TARGETS! alvos >> "!LOG_FILE!"
    )
    
    set /a "CURRENT_ITEM=0"
    if "!IP_COUNT!" gtr 0 (
        echo !IP_LIST! > "%TEMP_DIR%\ip_list.tmp"
        for /f "tokens=* delims=" %%I in ('type "%TEMP_DIR%\ip_list.tmp"') do (
            set "TEMP_LINE=%%I"
            call :network_line_by_pipe "!TEMP_LINE!" ip
        )
        del "%TEMP_DIR%\ip_list.tmp" >nul 2>&1
    )
    
    if "!DOMAIN_COUNT!" gtr 0 (
        echo !DOMAIN_LIST! > "%TEMP_DIR%\domain_list.tmp"
        for /f "tokens=* delims=" %%D in ('type "%TEMP_DIR%\domain_list.tmp"') do (
            set "TEMP_LINE=%%D"
            call :network_line_by_pipe "!TEMP_LINE!" domain
        )
        del "%TEMP_DIR%\domain_list.tmp" >nul 2>&1
    )
    
    call :show_success "Verificacao de rede concluida - Suspeitos: !CONNECTION_FOUND!"
)

:: 4. Verificar persistência
call :scan_section "MECANISMOS DE PERSISTENCIA" "4" "6" "36"
call :check_persistence
set /a "PERSISTENCE_FOUND=!PERSISTENCE_COUNT!"

:: 5. Verificar caminhos suspeitos
call :scan_section "CAMINHOS SUSPEITOS" "5" "6" "36"
call :check_suspicious_paths
set /a "PATH_FOUND=!SUSPICIOUS_PATH_COUNT!"

:: 6. Verificar registro
call :scan_section "REGISTRO DO WINDOWS" "6" "6" "36"
call :check_registry
set /a "REGISTRY_FOUND=!REGISTRY_COUNT!"

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
    if "!LOG_ENABLED!"=="1" (
        echo [%DATE% %TIME%] ✅ VERIFICACAO_RAPIDA: Nenhum processo na lista >> "!LOG_FILE!"
    )
) else (
    call :show_info "Verificando !PROCESS_COUNT! processos rapidamente..."
    if "!LOG_ENABLED!"=="1" (
        echo [%DATE% %TIME%] 🔍 VERIFICACAO_RAPIDA: Verificando !PROCESS_COUNT! processos >> "!LOG_FILE!"
    )
    
    echo !PROCESS_LIST! > "%TEMP_DIR%\quick_process_list.tmp"
    for /f "tokens=* delims=" %%P in ('type "%TEMP_DIR%\quick_process_list.tmp"') do (
        set "TEMP_LINE=%%P"
        call :quick_process_line "!TEMP_LINE!"
    )
    del "%TEMP_DIR%\quick_process_list.tmp" >nul 2>&1
    
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
    if "!LOG_ENABLED!"=="1" (
        echo [%DATE% %TIME%] ✅ VERIFICACAO_RAPIDA_RESULTADO: Nenhum processo malicioso encontrado >> "!LOG_FILE!"
    )
) else (
    if "!KILLED!"=="!FOUND!" (
        call :show_success "Todos os processos maliciosos foram finalizados!"
        if "!LOG_ENABLED!"=="1" (
            echo [%DATE% %TIME%] ✅ VERIFICACAO_RAPIDA_RESULTADO: Todos os !FOUND! processos finalizados >> "!LOG_FILE!"
        )
    ) else (
        call :show_warning "Apenas !KILLED! de !FOUND! processos foram finalizados"
        if "!LOG_ENABLED!"=="1" (
            echo [%DATE% %TIME%] ⚠️  VERIFICACAO_RAPIDA_RESULTADO: Apenas !KILLED! de !FOUND! processos finalizados >> "!LOG_FILE!"
        )
    )
)

if "!MODE!"=="interactive" (
    echo.
    call :pause_and_continue
    goto :interactive_menu
)
goto :exit_script

:: ========================================
::      FUNÇÕES AUXILIARES DE PARSING SEGURO
:: ========================================

:process_line_by_pipe
set "INPUT_LINE=%~1"
set "TYPE=%~2"
if "!INPUT_LINE!"=="" goto :eof
if "!INPUT_LINE!"=="|" goto :eof

:parse_pipe_loop
if "!INPUT_LINE!"=="" goto :eof
for /f "tokens=1* delims=|" %%A in ("!INPUT_LINE!") do (
    set "CURRENT_ITEM=%%A"
    set "INPUT_LINE=%%B"
)
if not "!CURRENT_ITEM!"=="" if not "!CURRENT_ITEM!"=="|" (
    set /a "CURRENT_ITEM+=1"
    call :show_debug "[!CURRENT_ITEM!/!PROCESS_COUNT!] Analisando !TYPE!: !CURRENT_ITEM!"
    call :check_process "!CURRENT_ITEM!"
    if !PROCESS_RUNNING! equ 1 (
        call :show_threat "PROCESSO MALICIOSO" "!CURRENT_ITEM!" "Em execucao - PID: !PROCESS_PID!"
        set /a "TOTAL_FOUND+=1"
        set /a "PROCESS_FOUND+=1"
        
        if "!LOG_ENABLED!"=="1" (
            echo [%DATE% %TIME%] ⚠️  PROCESSO_ENCONTRADO: !CURRENT_ITEM! - PID: !PROCESS_PID! >> "!LOG_FILE!"
        )
        
        call :kill_process "!CURRENT_ITEM!"
        if !ERRORLEVEL! equ 0 (
            call :show_success_item "Processo finalizado: !CURRENT_ITEM! (PID: !PROCESS_PID!)"
            set /a "ITEMS_REMOVED+=1"
            if "!LOG_ENABLED!"=="1" (
                echo [%DATE% %TIME%] ✅ PROCESSO_FINALIZADO: !CURRENT_ITEM! - PID: !PROCESS_PID! >> "!LOG_FILE!"
            )
        ) else (
            call :show_error "Falha ao finalizar processo: !CURRENT_ITEM!"
            if "!LOG_ENABLED!"=="1" (
                echo [%DATE% %TIME%] ❌ ERRO_PROCESSO: Falha ao finalizar !CURRENT_ITEM! >> "!LOG_FILE!"
            )
        )
    ) else (
        if "!SHOW_ALL!"=="1" call :show_clean "Processo limpo: !CURRENT_ITEM!" "Nao esta em execucao"
        if "!LOG_ENABLED!"=="1" (
            echo [%DATE% %TIME%] ✅ PROCESSO_LIMPO: !CURRENT_ITEM! - Nao esta em execucao >> "!LOG_FILE!"
        )
    )
)
if not "!INPUT_LINE!"=="" goto :parse_pipe_loop
goto :eof

:file_line_by_pipe
set "INPUT_LINE=%~1"
set "TYPE=%~2"
if "!INPUT_LINE!"=="" goto :eof
if "!INPUT_LINE!"=="|" goto :eof

:parse_file_pipe_loop
if "!INPUT_LINE!"=="" goto :eof
for /f "tokens=1* delims=|" %%A in ("!INPUT_LINE!") do (
    set "CURRENT_PATTERN=%%A"
    set "INPUT_LINE=%%B"
)
if not "!CURRENT_PATTERN!"=="" if not "!CURRENT_PATTERN!"=="|" (
    set /a "CURRENT_ITEM+=1"
    call :show_debug "[!CURRENT_ITEM!/!FILE_COUNT!] Procurando por: !CURRENT_PATTERN!"
    call :find_files "!CURRENT_PATTERN!"
    if !FILES_FOUND! gtr 0 (
        call :show_threat "ARQUIVO MALICIOSO" "!CURRENT_PATTERN!" "!FILES_FOUND! instancia(s) encontrada(s)"
        set /a "TOTAL_FOUND+=!FILES_FOUND!"
        set /a "FILE_FOUND+=!FILES_FOUND!"
        
        if "!LOG_ENABLED!"=="1" (
            echo [%DATE% %TIME%] ⚠️  ARQUIVO_ENCONTRADO: !CURRENT_PATTERN! - !FILES_FOUND! instancias >> "!LOG_FILE!"
        )
        
        if "!AUTO_REMOVE!"=="1" (
            call :remove_found_files
            set /a "ITEMS_REMOVED+=!FILES_FOUND!"
        )
    ) else (
        if "!SHOW_ALL!"=="1" call :show_clean "Arquivo nao encontrado: !CURRENT_PATTERN!" "Padrao limpo"
        if "!LOG_ENABLED!"=="1" (
            echo [%DATE% %TIME%] ✅ ARQUIVO_LIMPO: !CURRENT_PATTERN! - Nao encontrado >> "!LOG_FILE!"
        )
    )
)
if not "!INPUT_LINE!"=="" goto :parse_file_pipe_loop
goto :eof

:network_line_by_pipe
set "INPUT_LINE=%~1"
set "TYPE=%~2"
if "!INPUT_LINE!"=="" goto :eof
if "!INPUT_LINE!"=="|" goto :eof

:parse_network_pipe_loop
if "!INPUT_LINE!"=="" goto :eof
for /f "tokens=1* delims=|" %%A in ("!INPUT_LINE!") do (
    set "CURRENT_TARGET=%%A"
    set "INPUT_LINE=%%B"
)
if not "!CURRENT_TARGET!"=="" if not "!CURRENT_TARGET!"=="|" (
    set /a "CURRENT_ITEM+=1"
    call :show_debug "[!CURRENT_ITEM!/!TOTAL_TARGETS!] Processando !TYPE!: !CURRENT_TARGET!"
    call :check_network_target_safe "!CURRENT_TARGET!" "!TYPE!"
)
if not "!INPUT_LINE!"=="" goto :parse_network_pipe_loop
goto :eof

:check_network_target_safe
set "TARGET=%~1"
set "TARGET_TYPE=%~2"
set "IP_CONNECTED=0"
set "CONNECTION_INFO="

if "!TARGET!"=="" goto :eof

call :show_debug "Verificando registros de rede para: !TARGET!"

set "CLEAN_TARGET=!TARGET!"
set "CLEAN_TARGET=!CLEAN_TARGET:[.]=.!"
set "CLEAN_TARGET=!CLEAN_TARGET: =!"
set "CLEAN_TARGET=!CLEAN_TARGET:[=!"
set "CLEAN_TARGET=!CLEAN_TARGET:]=!"

call :show_debug "Alvo convertido para: !CLEAN_TARGET!"

if exist "%WINDIR%\System32\drivers\etc\hosts" (
    findstr /i /c:"!CLEAN_TARGET!" "%WINDIR%\System32\drivers\etc\hosts" >nul 2>&1
    if !ERRORLEVEL! equ 0 (
        set "IP_CONNECTED=1"
        set "CONNECTION_INFO=Encontrado no arquivo HOSTS"
        goto :network_check_done
    )
)

ipconfig /displaydns 2>nul | findstr /i /c:"!CLEAN_TARGET!" >nul 2>&1
if !ERRORLEVEL! equ 0 (
    set "IP_CONNECTED=1"
    set "CONNECTION_INFO=Encontrado no cache DNS"
    goto :network_check_done
)

echo "!CLEAN_TARGET!" | findstr /R /C:"^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" >nul 2>&1
if !ERRORLEVEL! equ 0 (
    call :show_debug "Verificando conexoes ativas para IP: !CLEAN_TARGET!"
    netstat -ano 2>nul | findstr /c:"!CLEAN_TARGET!" >nul 2>&1
    if !ERRORLEVEL! equ 0 (
        set "IP_CONNECTED=1"
        set "CONNECTION_INFO=Conexao ativa encontrada"
        goto :network_check_done
    )
)

if "!IP_CONNECTED!"=="0" (
    ping -n 1 -w 1000 "!CLEAN_TARGET!" >nul 2>&1
    if !ERRORLEVEL! equ 0 (
        set "IP_CONNECTED=1"
        set "CONNECTION_INFO=Dominio resolve para IP ativo"
    )
)

:network_check_done
if !IP_CONNECTED! equ 1 (
    call :show_threat "CONEXAO SUSPEITA" "!TARGET_TYPE!: !TARGET!" "!CONNECTION_INFO!"
    set /a "TOTAL_FOUND+=1"
    set /a "CONNECTION_FOUND+=1"
    if "!LOG_ENABLED!"=="1" (
        echo [%DATE% %TIME%] ⚠️  CONEXAO_SUSPEITA: !TARGET! - !CONNECTION_INFO! >> "!LOG_FILE!"
    )
) else (
    if "!SHOW_ALL!"=="1" (
        call :show_clean "Sem registros" "!TARGET_TYPE!: !TARGET!"
    )
    if "!LOG_ENABLED!"=="1" (
        echo [%DATE% %TIME%] ✅ CONEXAO_LIMPA: !TARGET! >> "!LOG_FILE!"
    )
)
goto :eof

:quick_process_line
set "INPUT_LINE=%~1"
if "!INPUT_LINE!"=="" goto :eof
if "!INPUT_LINE!"=="|" goto :eof

:parse_quick_pipe_loop
if "!INPUT_LINE!"=="" goto :eof
for /f "tokens=1* delims=|" %%A in ("!INPUT_LINE!") do (
    set "CURRENT_PROCESS=%%A"
    set "INPUT_LINE=%%B"
)
if not "!CURRENT_PROCESS!"=="" if not "!CURRENT_PROCESS!"=="|" (
    call :show_debug "Processo: !CURRENT_PROCESS!"
    call :check_process "!CURRENT_PROCESS!"
    if !PROCESS_RUNNING! equ 1 (
        call :show_threat "PROCESSO MALICIOSO" "!CURRENT_PROCESS!" "Em execucao - PID: !PROCESS_PID!"
        set /a "FOUND+=1"
        
        if "!LOG_ENABLED!"=="1" (
            echo [%DATE% %TIME%] ⚠️  VERIFICACAO_RAPIDA_ENCONTRADO: !CURRENT_PROCESS! - PID: !PROCESS_PID! >> "!LOG_FILE!"
        )
        
        call :kill_process "!CURRENT_PROCESS!"
        if !ERRORLEVEL! equ 0 (
            call :show_success_item "Processo finalizado: !CURRENT_PROCESS! (PID: !PROCESS_PID!)"
            set /a "KILLED+=1"
            if "!LOG_ENABLED!"=="1" (
                echo [%DATE% %TIME%] ✅ VERIFICACAO_RAPIDA_FINALIZADO: !CURRENT_PROCESS! - PID: !PROCESS_PID! >> "!LOG_FILE!"
            )
        ) else (
            call :show_error "Falha ao finalizar processo: !CURRENT_PROCESS!"
            if "!LOG_ENABLED!"=="1" (
                echo [%DATE% %TIME%] ❌ VERIFICACAO_RAPIDA_ERRO: Falha ao finalizar !CURRENT_PROCESS! >> "!LOG_FILE!"
            )
        )
    ) else (
        if "!SHOW_ALL!"=="1" call :show_clean "Processo limpo: !CURRENT_PROCESS!" "Nao esta em execucao"
        if "!LOG_ENABLED!"=="1" (
            echo [%DATE% %TIME%] ✅ VERIFICACAO_RAPIDA_LIMPO: !CURRENT_PROCESS! - Nao esta em execucao >> "!LOG_FILE!"
        )
    )
)
if not "!INPUT_LINE!"=="" goto :parse_quick_pipe_loop
goto :eof

:: ========================================
::      FUNÇÕES UTILITÁRIAS
:: ========================================

:read_process_list
set "PROCESS_LIST="
set /a "PROCESS_COUNT=0"
if exist "%DATA_DIR%\processos.txt" (
    for /f "usebackq delims=" %%i in ("%DATA_DIR%\processos.txt") do (
        set "line=%%i"
        set "line=!line: =!"
        if not "!line!"=="" if not "!line:~0,1!"=="#" (
            if not "!line!"=="=" (
                set "PROCESS_LIST=!PROCESS_LIST!|!line!"
                set /a "PROCESS_COUNT+=1"
            )
        )
    )
)
goto :eof

:read_file_list
set "FILE_LIST="
set /a "FILE_COUNT=0"
if exist "%DATA_DIR%\arquivos.txt" (
    for /f "usebackq delims=" %%i in ("%DATA_DIR%\arquivos.txt") do (
        set "line=%%i"
        set "line=!line: =!"
        if not "!line!"=="" if not "!line:~0,1!"=="#" (
            if not "!line!"=="=" (
                set "FILE_LIST=!FILE_LIST!|!line!"
                set /a "FILE_COUNT+=1"
            )
        )
    )
)
goto :eof

:read_ip_list
set "IP_LIST="
set /a "IP_COUNT=0"
if exist "%DATA_DIR%\ips.txt" (
    for /f "usebackq delims=" %%i in ("%DATA_DIR%\ips.txt") do (
        set "line=%%i"
        set "line=!line: =!"
        if not "!line!"=="" if not "!line:~0,1!"=="#" (
            if not "!line!"=="=" (
                set "IP_LIST=!IP_LIST!|!line!"
                set /a "IP_COUNT+=1"
            )
        )
    )
)
goto :eof

:read_domain_list
set "DOMAIN_LIST="
set /a "DOMAIN_COUNT=0"
if exist "%DATA_DIR%\dominios.txt" (
    for /f "usebackq delims=" %%i in ("%DATA_DIR%\dominios.txt") do (
        set "line=%%i"
        set "line=!line: =!"
        if not "!line!"=="" if not "!line:~0,1!"=="#" (
            if not "!line!"=="=" (
                set "DOMAIN_LIST=!DOMAIN_LIST!|!line!"
                set /a "DOMAIN_COUNT+=1"
            )
        )
    )
)
goto :eof

:read_path_list
set "PATH_LIST="
set /a "PATH_COUNT=0"
if exist "%DATA_DIR%\caminhos.txt" (
    for /f "usebackq delims=" %%i in ("%DATA_DIR%\caminhos.txt") do (
        set "line=%%i"
        set "line=!line: =!"
        if not "!line!"=="" if not "!line:~0,1!"=="#" (
            if not "!line!"=="=" (
                set "PATH_LIST=!PATH_LIST!|!line!"
                set /a "PATH_COUNT+=1"
            )
        )
    )
)
goto :eof

:read_registry_list
set "REGISTRY_LIST="
set /a "REGISTRY_COUNT_READ=0"
if exist "%DATA_DIR%\reg.txt" (
    for /f "usebackq delims=" %%i in ("%DATA_DIR%\reg.txt") do (
        set "line=%%i"
        set "line=!line: =!"
        if not "!line!"=="" if not "!line:~0,1!"=="#" (
            if not "!line!"=="=" (
                set "REGISTRY_LIST=!REGISTRY_LIST!|!line!"
                set /a "REGISTRY_COUNT_READ+=1"
            )
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

call :read_path_list
if "!PATH_COUNT!"=="0" (
    set "SCAN_LOCATIONS=%USERPROFILE%\Desktop %USERPROFILE%\Downloads %USERPROFILE%\Documents %TEMP% %APPDATA% %PROGRAMDATA% C:\Windows\Temp"
) else (
    set "SCAN_LOCATIONS="
    echo !PATH_LIST! > "%TEMP_DIR%\path_list.tmp"
    for /f "tokens=* delims=" %%L in ('type "%TEMP_DIR%\path_list.tmp"') do (
        set "TEMP_PATH_LINE=%%L"
        call :build_scan_locations "!TEMP_PATH_LINE!"
    )
    del "%TEMP_DIR%\path_list.tmp" >nul 2>&1
)

for %%D in (!SCAN_LOCATIONS!) do (
    if exist %%~D (
        for /f "delims=" %%F in ('dir "%%~D\!PATTERN!" /b /s /a-d 2^>nul') do (
            set /a "FILES_FOUND+=1"
            set "FOUND_FILES=!FOUND_FILES!%%F|"
            call :show_debug "Encontrado: %%F"
        )
    )
)
goto :eof

:build_scan_locations
set "INPUT_PATH_LINE=%~1"
if "!INPUT_PATH_LINE!"=="" goto :eof

:parse_path_loop
if "!INPUT_PATH_LINE!"=="" goto :eof
for /f "tokens=1* delims=|" %%A in ("!INPUT_PATH_LINE!") do (
    set "CURRENT_PATH=%%A"
    set "INPUT_PATH_LINE=%%B"
)
if not "!CURRENT_PATH!"=="" if not "!CURRENT_PATH!"=="|" (
    set "SCAN_LOCATIONS=!SCAN_LOCATIONS! "!CURRENT_PATH!""
)
if not "!INPUT_PATH_LINE!"=="" goto :parse_path_loop
goto :eof

:remove_found_files
set /a "REMOVED_COUNT=0"
echo !FOUND_FILES! > "%TEMP_DIR%\remove_files.tmp"
for /f "tokens=* delims=" %%R in ('type "%TEMP_DIR%\remove_files.tmp"') do (
    set "TEMP_REMOVE_LINE=%%R"
    call :remove_file_by_pipe "!TEMP_REMOVE_LINE!"
)
del "%TEMP_DIR%\remove_files.tmp" >nul 2>&1
goto :eof

:remove_file_by_pipe
set "INPUT_REMOVE_LINE=%~1"
if "!INPUT_REMOVE_LINE!"=="" goto :eof

:parse_remove_loop
if "!INPUT_REMOVE_LINE!"=="" goto :eof
for /f "tokens=1* delims=|" %%A in ("!INPUT_REMOVE_LINE!") do (
    set "CURRENT_FILE=%%A"
    set "INPUT_REMOVE_LINE=%%B"
)
if not "!CURRENT_FILE!"=="" if not "!CURRENT_FILE!"=="|" (
    call :show_debug "Removendo arquivo: !CURRENT_FILE!"
    del /f /q "!CURRENT_FILE!" >nul 2>&1
    if !ERRORLEVEL! equ 0 (
        call :show_success_item "Arquivo removido: !CURRENT_FILE!"
        set /a "REMOVED_COUNT+=1"
        if "!LOG_ENABLED!"=="1" (
            echo [%DATE% %TIME%] ✅ ARQUIVO_REMOVIDO: !CURRENT_FILE! >> "!LOG_FILE!"
        )
    ) else (
        call :show_error "Falha ao remover: !CURRENT_FILE!"
        if "!LOG_ENABLED!"=="1" (
            echo [%DATE% %TIME%] ❌ ERRO_ARQUIVO: Falha ao remover !CURRENT_FILE! >> "!LOG_FILE!"
        )
    )
)
if not "!INPUT_REMOVE_LINE!"=="" goto :parse_remove_loop
goto :eof

:check_persistence
set /a "PERSISTENCE_COUNT=0"
set "PERSISTENCE_FOUND="
call :show_info "Verificando mecanismos de persistencia..."
if "!LOG_ENABLED!"=="1" (
    echo [%DATE% %TIME%] 🔍 PERSISTENCIA: Verificando mecanismos de persistencia... >> "!LOG_FILE!"
)

set "PERSISTENCE_LOCATIONS="%USERPROFILE%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup" "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup" "%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\StartUp" "%USERPROFILE%\AppData\Roaming\Microsoft\Windows\Recent""

call :read_file_list
for %%D in (!PERSISTENCE_LOCATIONS!) do (
    if exist %%~D (
        echo !FILE_LIST! > "%TEMP_DIR%\persist_file_list.tmp"
        for /f "tokens=* delims=" %%L in ('type "%TEMP_DIR%\persist_file_list.tmp"') do (
            set "TEMP_PERSIST_LINE=%%L"
            call :check_persist_location "%%~D" "!TEMP_PERSIST_LINE!"
        )
        del "%TEMP_DIR%\persist_file_list.tmp" >nul 2>&1
    )
)

call :show_info "Verificando arquivos ZIP em locais suspeitos..."
if "!LOG_ENABLED!"=="1" (
    echo [%DATE% %TIME%] 🔍 PERSISTENCIA: Verificando arquivos ZIP suspeitos... >> "!LOG_FILE!"
)

call :read_path_list
if "!PATH_COUNT!" gtr 0 (
    echo !PATH_LIST! > "%TEMP_DIR%\zip_path_list.tmp"
    for /f "tokens=* delims=" %%L in ('type "%TEMP_DIR%\zip_path_list.tmp"') do (
        set "TEMP_ZIP_LINE=%%L"
        call :check_zip_in_paths "!TEMP_ZIP_LINE!"
    )
    del "%TEMP_DIR%\zip_path_list.tmp" >nul 2>&1
)

goto :eof

:check_persist_location
set "LOCATION=%~1"
set "FILE_LINE=%~2"
if "!FILE_LINE!"=="" goto :eof

:parse_persist_loop
if "!FILE_LINE!"=="" goto :eof
for /f "tokens=1* delims=|" %%A in ("!FILE_LINE!") do (
    set "CURRENT_FILE=%%A"
    set "FILE_LINE=%%B"
)
if not "!CURRENT_FILE!"=="" if not "!CURRENT_FILE!"=="|" (
    for /f "delims=" %%A in ('dir "!LOCATION!\!CURRENT_FILE!" /b 2^>nul') do (
        set /a "PERSISTENCE_COUNT+=1"
        call :show_threat "PERSISTENCIA" "!LOCATION!\%%A" "Mecanismo de inicializacao automatica"
        set "PERSISTENCE_FOUND=!PERSISTENCE_FOUND!!LOCATION!\%%A|"
        if "!LOG_ENABLED!"=="1" (
            echo [%DATE% %TIME%] ⚠️  PERSISTENCIA_ENCONTRADA: !LOCATION!\%%A >> "!LOG_FILE!"
        )
    )
)
if not "!FILE_LINE!"=="" goto :parse_persist_loop
goto :eof

:check_zip_in_paths
set "PATH_LINE=%~1"
if "!PATH_LINE!"=="" goto :eof

:parse_zip_path_loop
if "!PATH_LINE!"=="" goto :eof
for /f "tokens=1* delims=|" %%A in ("!PATH_LINE!") do (
    set "CURRENT_ZIP_PATH=%%A"
    set "PATH_LINE=%%B"
)
if not "!CURRENT_ZIP_PATH!"=="" if not "!CURRENT_ZIP_PATH!"=="|" (
    for /f "delims=" %%X in ("!CURRENT_ZIP_PATH!") do set "EXPANDED_ZIP_PATH=%%~X"
    if exist "!EXPANDED_ZIP_PATH!" (
        for /f "delims=" %%A in ('dir "!EXPANDED_ZIP_PATH!\*SORVEPOTEL*.zip" "!EXPANDED_ZIP_PATH!\*COMPROVANTE*.zip" "!EXPANDED_ZIP_PATH!\*SANTANDER*.zip" /b 2^>nul') do (
            set /a "PERSISTENCE_COUNT+=1"
            call :show_threat "ARQUIVO ZIP SUSPEITO" "!EXPANDED_ZIP_PATH!\%%A" "Possivel campanha SORVEPOTEL"
            set "PERSISTENCE_FOUND=!PERSISTENCE_FOUND!!EXPANDED_ZIP_PATH!\%%A|"
            if "!LOG_ENABLED!"=="1" (
                echo [%DATE% %TIME%] ⚠️  PERSISTENCIA_ZIP: !EXPANDED_ZIP_PATH!\%%A - Possivel campanha SORVEPOTEL >> "!LOG_FILE!"
            )
        )
    )
)
if not "!PATH_LINE!"=="" goto :parse_zip_path_loop
goto :eof

:check_suspicious_paths
set /a "SUSPICIOUS_PATH_COUNT=0"
set "SUSPICIOUS_PATHS_FOUND="
call :show_info "Verificando caminhos suspeitos..."
if "!LOG_ENABLED!"=="1" (
    echo [%DATE% %TIME%] 🔍 CAMINHOS: Verificando caminhos suspeitos... >> "!LOG_FILE!"
)

call :read_path_list
if "!PATH_COUNT!"=="0" (
    call :show_warning "Nenhum caminho na lista de monitoramento"
    if "!LOG_ENABLED!"=="1" (
        echo [%DATE% %TIME%] ✅ CAMINHOS: Nenhum caminho na lista de monitoramento >> "!LOG_FILE!"
    )
) else (
    call :read_file_list
    echo !PATH_LIST! > "%TEMP_DIR%\suspicious_path_list.tmp"
    for /f "tokens=* delims=" %%L in ('type "%TEMP_DIR%\suspicious_path_list.tmp"') do (
        set "TEMP_SUSP_LINE=%%L"
        call :check_suspicious_path_line "!TEMP_SUSP_LINE!"
    )
    del "%TEMP_DIR%\suspicious_path_list.tmp" >nul 2>&1
)
goto :eof

:check_suspicious_path_line
set "PATH_LINE=%~1"
if "!PATH_LINE!"=="" goto :eof

:parse_susp_path_loop
if "!PATH_LINE!"=="" goto :eof
for /f "tokens=1* delims=|" %%A in ("!PATH_LINE!") do (
    set "CURRENT_PATH=%%A"
    set "PATH_LINE=%%B"
)
if not "!CURRENT_PATH!"=="" if not "!CURRENT_PATH!"=="|" (
    for /f "delims=" %%X in ("!CURRENT_PATH!") do set "EXPANDED_PATH=%%~X"
    
    if exist "!EXPANDED_PATH!" (
        call :show_debug "Verificando caminho: !EXPANDED_PATH!"
        echo !FILE_LIST! > "%TEMP_DIR%\file_pattern_list.tmp"
        for /f "tokens=* delims=" %%F in ('type "%TEMP_DIR%\file_pattern_list.tmp"') do (
            set "TEMP_FILE_LINE=%%F"
            call :check_files_in_path "!EXPANDED_PATH!" "!TEMP_FILE_LINE!"
        )
        del "%TEMP_DIR%\file_pattern_list.tmp" >nul 2>&1
    ) else (
        if "!SHOW_ALL!"=="1" call :show_clean "Caminho nao existe: !EXPANDED_PATH!" "Caminho limpo"
        if "!LOG_ENABLED!"=="1" (
            echo [%DATE% %TIME%] ✅ CAMINHO_LIMPO: !EXPANDED_PATH! - Nao existe >> "!LOG_FILE!"
        )
    )
)
if not "!PATH_LINE!"=="" goto :parse_susp_path_loop
goto :eof

:check_files_in_path
set "CHECK_PATH=%~1"
set "FILE_PATTERN_LINE=%~2"
if "!FILE_PATTERN_LINE!"=="" goto :eof

:parse_file_pattern_loop
if "!FILE_PATTERN_LINE!"=="" goto :eof
for /f "tokens=1* delims=|" %%A in ("!FILE_PATTERN_LINE!") do (
    set "CURRENT_FILE_PATTERN=%%A"
    set "FILE_PATTERN_LINE=%%B"
)
if not "!CURRENT_FILE_PATTERN!"=="" if not "!CURRENT_FILE_PATTERN!"=="|" (
    for /f "delims=" %%A in ('dir "!CHECK_PATH!\!CURRENT_FILE_PATTERN!" /b /s 2^>nul') do (
        set /a "SUSPICIOUS_PATH_COUNT+=1"
        call :show_threat "CAMINHO SUSPEITO" "%%A" "Arquivo malicioso em local monitorado"
        set "SUSPICIOUS_PATHS_FOUND=!SUSPICIOUS_PATHS_FOUND!%%A|"
        if "!LOG_ENABLED!"=="1" (
            echo [%DATE% %TIME%] ⚠️  CAMINHO_SUSPEITO: %%A >> "!LOG_FILE!"
        )
        
        if "!AUTO_REMOVE!"=="1" (
            call :show_debug "Removendo arquivo suspeito: %%A"
            del /f /q "%%A" >nul 2>&1
            if !ERRORLEVEL! equ 0 (
                call :show_success_item "Arquivo removido: %%A"
                set /a "ITEMS_REMOVED+=1"
                if "!LOG_ENABLED!"=="1" (
                    echo [%DATE% %TIME%] ✅ CAMINHO_REMOVIDO: %%A >> "!LOG_FILE!"
                )
            ) else (
                call :show_error "Falha ao remover: %%A"
                if "!LOG_ENABLED!"=="1" (
                    echo [%DATE% %TIME%] ❌ ERRO_CAMINHO: Falha ao remover %%A >> "!LOG_FILE!"
                )
            )
        )
    )
)
if not "!FILE_PATTERN_LINE!"=="" goto :parse_file_pattern_loop
goto :eof

:check_registry
set /a "REGISTRY_COUNT=0"
set "REGISTRY_FOUND="
call :show_info "Verificando registro do Windows..."
if "!LOG_ENABLED!"=="1" (
    echo [%DATE% %TIME%] 🔍 REGISTRO: Verificando chaves do registro... >> "!LOG_FILE!"
)

call :read_registry_list
if "!REGISTRY_COUNT_READ!"=="0" (
    call :show_warning "Nenhuma chave de registro na lista de monitoramento"
    if "!LOG_ENABLED!"=="1" (
        echo [%DATE% %TIME%] ✅ REGISTRO: Nenhuma chave na lista de monitoramento >> "!LOG_FILE!"
    )
) else (
    echo !REGISTRY_LIST! > "%TEMP_DIR%\registry_list.tmp"
    for /f "tokens=* delims=" %%L in ('type "%TEMP_DIR%\registry_list.tmp"') do (
        set "TEMP_REG_LINE=%%L"
        call :check_registry_line "!TEMP_REG_LINE!"
    )
    del "%TEMP_DIR%\registry_list.tmp" >nul 2>&1
)
goto :eof

:check_registry_line
set "REGISTRY_LINE=%~1"
if "!REGISTRY_LINE!"=="" goto :eof

:parse_registry_loop
if "!REGISTRY_LINE!"=="" goto :eof
for /f "tokens=1* delims=|" %%A in ("!REGISTRY_LINE!") do (
    set "CURRENT_REGISTRY=%%A"
    set "REGISTRY_LINE=%%B"
)
if not "!CURRENT_REGISTRY!"=="" if not "!CURRENT_REGISTRY!"=="|" (
    call :show_debug "Verificando chave: !CURRENT_REGISTRY!"
    
    echo "!CURRENT_REGISTRY!" | findstr /i "SORVEPOTEL" >nul
    if !ERRORLEVEL! equ 0 (
        reg query "!CURRENT_REGISTRY!" >nul 2>&1
        if !ERRORLEVEL! equ 0 (
            set /a "REGISTRY_COUNT+=1"
            call :show_threat "CHAVE DE REGISTRO MALICIOSA" "!CURRENT_REGISTRY!" "Chave especifica do malware encontrada"
            set "REGISTRY_FOUND=!REGISTRY_FOUND!!CURRENT_REGISTRY!|"
            if "!LOG_ENABLED!"=="1" (
                echo [%DATE% %TIME%] ⚠️  REGISTRO_ENCONTRADO: !CURRENT_REGISTRY! >> "!LOG_FILE!"
            )
        ) else (
            if "!SHOW_ALL!"=="1" call :show_clean "Chave de registro limpa: !CURRENT_REGISTRY!" "Chave nao encontrada"
        )
    ) else (
        call :check_registry_values "!CURRENT_REGISTRY!"
    )
)
if not "!REGISTRY_LINE!"=="" goto :parse_registry_loop
goto :eof

:check_registry_values
set "REG_KEY=%~1"
reg query "!REG_KEY!" >nul 2>&1
if !ERRORLEVEL! equ 0 (
    for /f "tokens=2*" %%A in ('reg query "!REG_KEY!" 2^>nul ^| findstr /i "HealthApp.*\.bat malware.*\.exe virus.*\.bat"') do (
        set /a "REGISTRY_COUNT+=1"
        call :show_threat "VALOR SUSPEITO NO REGISTRO" "!REG_KEY!" "Valor: %%A %%B"
        set "REGISTRY_FOUND=!REGISTRY_FOUND!!REG_KEY!|"
        if "!LOG_ENABLED!"=="1" (
            echo [%DATE% %TIME%] ⚠️  REGISTRO_VALOR_SUSPEITO: !REG_KEY! - %%A %%B >> "!LOG_FILE!"
        )
    )
)
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
call :print_stat "Caminhos suspeitos:" "!PATH_FOUND!" "33"
call :print_stat "Chaves de registro:" "!REGISTRY_FOUND!" "35"
echo.
call :print_line "36"

set /a "TOTAL_FOUND=!PROCESS_FOUND!+!FILE_FOUND!+!CONNECTION_FOUND!+!PERSISTENCE_FOUND!+!PATH_FOUND!+!REGISTRY_FOUND!"

if !TOTAL_FOUND! equ 0 (
    call :show_success "SISTEMA LIMPO - Nenhuma ameaca detectada!"
    if "!LOG_ENABLED!"=="1" (
        echo [%DATE% %TIME%] ✅ RELATORIO_FINAL: Sistema limpo - Nenhuma ameaca detectada >> "!LOG_FILE!"
    )
) else (
    call :show_critical "ALERTA DE SEGURANCA" "!TOTAL_FOUND! ameacas detectadas!" "CRITICO"
    if "!LOG_ENABLED!"=="1" (
        echo [%DATE% %TIME%] 🚨 RELATORIO_FINAL: !TOTAL_FOUND! ameacas detectadas >> "!LOG_FILE!"
    )
    echo.
    call :print_box "ACOES REALIZADAS:" "33"
    echo.
    if "!AUTO_REMOVE!"=="1" (
        if !ITEMS_REMOVED! gtr 0 (
            call :show_success "!ITEMS_REMOVED! itens foram removidos automaticamente"
            if "!LOG_ENABLED!"=="1" (
                echo [%DATE% %TIME%] ✅ ACOES: !ITEMS_REMOVED! itens removidos automaticamente >> "!LOG_FILE!"
            )
        ) else (
            call :show_warning "Nenhum item pode ser removido automaticamente"
            if "!LOG_ENABLED!"=="1" (
                echo [%DATE% %TIME%] ⚠️  ACOES: Nenhum item removido automaticamente >> "!LOG_FILE!"
            )
        )
    ) else (
        call :show_warning "Modo de remocao automatica desativado"
        if "!LOG_ENABLED!"=="1" (
            echo [%DATE% %TIME%] ⚠️  ACOES: Modo de remocao automatica desativado >> "!LOG_FILE!"
        )
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

call :read_file_list
call :print_stat "Arquivos na lista:" "!FILE_COUNT!" "36"

call :read_ip_list
call :read_domain_list
set /a "TOTAL_NETWORK=IP_COUNT+DOMAIN_COUNT"
call :print_stat "Alvos de rede na lista:" "!TOTAL_NETWORK! (!IP_COUNT! IPs + !DOMAIN_COUNT! dominios)" "36"

call :read_path_list
call :print_stat "Caminhos na lista:" "!PATH_COUNT!" "36"

call :read_registry_list
call :print_stat "Chaves de registro:" "!REGISTRY_COUNT_READ!" "36"

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
echo    Foco especifico na campanha SORVEPOTEL e similares
echo    Baseado em pesquisa Trend Micro sobre malware do WhatsApp
echo.
echo    Caracteristicas:
echo      • Scanner especializado em SORVEPOTEL
echo      • Deteccao de arquivos ZIP, LNK e BAT maliciosos
echo      • Monitoramento de dominios C^&C
echo      • Interface profissional com sistema de cores ANSI
echo      • Sistema de logging integrado com emojis
echo      • Parsing seguro de listas (v1.0.1)
echo      • Feedback detalhado de progresso
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
::      FUNÇÕES DE INTERFACE COM CORES ANSI CORRIGIDAS
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
    if "!color!"=="31" echo !spaces!%ESC%[91m!text!%ESC%[0m
    if "!color!"=="32" echo !spaces!%ESC%[92m!text!%ESC%[0m
    if "!color!"=="33" echo !spaces!%ESC%[93m!text!%ESC%[0m
    if "!color!"=="34" echo !spaces!%ESC%[94m!text!%ESC%[0m
    if "!color!"=="35" echo !spaces!%ESC%[95m!text!%ESC%[0m
    if "!color!"=="36" echo !spaces!%ESC%[96m!text!%ESC%[0m
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
        echo │   %ESC%[91m!text!%ESC%[0m
        echo └!line!┘
    ) else if "!color!"=="32" (
        echo ┌!line!┐
        echo │   %ESC%[92m!text!%ESC%[0m
        echo └!line!┘
    ) else if "!color!"=="33" (
        echo ┌!line!┐
        echo │   %ESC%[93m!text!%ESC%[0m
        echo └!line!┘
    ) else if "!color!"=="36" (
        echo ┌!line!┐
        echo │   %ESC%[96m!text!%ESC%[0m
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
    if "!color!"=="31" echo %ESC%[91m!line!%ESC%[0m
    if "!color!"=="32" echo %ESC%[92m!line!%ESC%[0m
    if "!color!"=="33" echo %ESC%[93m!line!%ESC%[0m
    if "!color!"=="36" echo %ESC%[96m!line!%ESC%[0m
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
    echo    %ESC%[93m[!num!]%ESC%[0m %ESC%[97m!title!%ESC%[0m
    echo        %ESC%[90m!desc!%ESC%[0m
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
        echo    %ESC%[92m!name!: [ATIVADO]%ESC%[0m  - !desc!
    ) else (
        echo    !name!: [ATIVADO]  - !desc!
    )
) else (
    if "!COLOR_ENABLED!"=="1" (
        echo    %ESC%[91m!name!: [DESATIVADO]%ESC%[0m - !desc!
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
    if "!color!"=="31" echo    !label! %ESC%[91m!value!%ESC%[0m
    if "!color!"=="32" echo    !label! %ESC%[92m!value!%ESC%[0m
    if "!color!"=="33" echo    !label! %ESC%[93m!value!%ESC%[0m
    if "!color!"=="36" echo    !label! %ESC%[96m!value!%ESC%[0m
    if "!color!"=="35" echo    !label! %ESC%[95m!value!%ESC%[0m
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
    echo    %ESC%[91m🔴 [AMEAÇA] !type!%ESC%[0m
    echo        %ESC%[97mAlvo:%ESC%[0m %ESC%[91m!target!%ESC%[0m
    echo        %ESC%[97mInfo:%ESC%[0m %ESC%[93m!info!%ESC%[0m
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
    echo    %ESC%[91m🚨🚨🚨 [CRÍTICO] !type!%ESC%[0m
    echo        %ESC%[97m!target!%ESC%[0m
    echo        %ESC%[91m!info!%ESC%[0m
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
        echo    %ESC%[92m🟢 [LIMPO] !type!%ESC%[0m
        echo        %ESC%[92m!target!%ESC%[0m
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
    echo    %ESC%[92m   ✅ !message!%ESC%[0m
) else (
    echo    ✅ !message!
)
goto :eof

:show_success
set "message=%~1"
if "!COLOR_ENABLED!"=="1" (
    echo    %ESC%[92m✅ [SUCESSO] !message!%ESC%[0m
) else (
    echo    ✅ [SUCESSO] !message!
)
goto :eof

:show_warning
set "message=%~1"
if "!COLOR_ENABLED!"=="1" (
    echo    %ESC%[93m⚠️  [AVISO] !message!%ESC%[0m
) else (
    echo    ⚠️  [AVISO] !message!
)
goto :eof

:show_info
set "message=%~1"
if "!COLOR_ENABLED!"=="1" (
    echo    %ESC%[96mℹ️  [INFO] !message!%ESC%[0m
) else (
    echo    ℹ️  [INFO] !message!
)
goto :eof

:show_debug
set "message=%~1"
if "!DEBUG!"=="1" (
    if "!COLOR_ENABLED!"=="1" (
        echo    %ESC%[90m   🔧 !message!%ESC%[0m
    ) else (
        echo    🔧 !message!
    )
)
goto :eof

:show_error
set "message=%~1"
if "!COLOR_ENABLED!"=="1" (
    echo    %ESC%[91m❌ [ERRO] !message!%ESC%[0m
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
    echo [%DATE% %TIME%] ✅ RAVSCAN finalizado >> "!LOG_FILE!"
)
if exist "%TEMP_DIR%" rd /s /q "%TEMP_DIR%" >nul 2>&1
endlocal
exit /b 0

:: ========================================
::      INICIALIZAÇÃO DE ARQUIVOS
:: ========================================

:initialize_data_files
if not exist "%DATA_DIR%\processos.txt" (
    echo # Processos maliciosos conhecidos - Campanha SORVEPOTEL > "%DATA_DIR%\processos.txt"
    echo # Baseado em pesquisa Trend Micro >> "%DATA_DIR%\processos.txt"
    echo. >> "%DATA_DIR%\processos.txt"
    echo # Arquivos executáveis e scripts de payload >> "%DATA_DIR%\processos.txt"
    echo HealthApp-0d97b7.bat >> "%DATA_DIR%\processos.txt"
)

if not exist "%DATA_DIR%\arquivos.txt" (
    echo # Padrões de arquivos maliciosos - Campanha SORVEPOTEL > "%DATA_DIR%\arquivos.txt"
    echo # Baseado em pesquisa Trend Micro >> "%DATA_DIR%\arquivos.txt"
    echo. >> "%DATA_DIR%\arquivos.txt"
    echo # Arquivos ZIP maliciosos >> "%DATA_DIR%\arquivos.txt"
    echo RES-*.zip >> "%DATA_DIR%\arquivos.txt"
    echo ORCAMENTO_*.zip >> "%DATA_DIR%\arquivos.txt"
    echo COMPROVANTE_*.zip >> "%DATA_DIR%\arquivos.txt"
    echo ComprovanteSantander-*.zip >> "%DATA_DIR%\arquivos.txt"
    echo NEW-*-PED_*.zip >> "%DATA_DIR%\arquivos.txt"
    echo. >> "%DATA_DIR%\arquivos.txt"
    echo # Atalhos Windows LNK maliciosos >> "%DATA_DIR%\arquivos.txt"
    echo ComprovanteSantander-*.lnk >> "%DATA_DIR%\arquivos.txt"
    echo HealthApp-*.bat >> "%DATA_DIR%\arquivos.txt"
    echo DOC-*.lnk >> "%DATA_DIR%\arquivos.txt"
    echo. >> "%DATA_DIR%\arquivos.txt"
    echo # Scripts de persistencia >> "%DATA_DIR%\arquivos.txt"
    echo HealthApp-0d97b7.bat >> "%DATA_DIR%\arquivos.txt"
)

if not exist "%DATA_DIR%\ips.txt" (
    echo # Lista de IPs maliciosos - Campanha SORVEPOTEL > "%DATA_DIR%\ips.txt"
    echo # Baseado em pesquisa Trend Micro >> "%DATA_DIR%\ips.txt"
    echo # Apenas endereços IP para verificacao de rede >> "%DATA_DIR%\ips.txt"
    echo. >> "%DATA_DIR%\ips.txt"
    echo # Enderecos IP maliciosos >> "%DATA_DIR%\ips.txt"
    echo 109.176.30.141 >> "%DATA_DIR%\ips.txt"
    echo 165.154.254.44 >> "%DATA_DIR%\ips.txt"
    echo 23.227.203.148 >> "%DATA_DIR%\ips.txt"
    echo 77.111.101.169 >> "%DATA_DIR%\ips.txt"
)

if not exist "%DATA_DIR%\dominios.txt" (
    echo # Lista de dominios maliciosos - Campanha SORVEPOTEL > "%DATA_DIR%\dominios.txt"
    echo # Baseado em pesquisa Trend Micro >> "%DATA_DIR%\dominios.txt"
    echo # FORMATO COM [.] para prevenir acionamentos acidentais >> "%DATA_DIR%\dominios.txt"
    echo # O scanner converte internamente para verificacao >> "%DATA_DIR%\dominios.txt"
    echo. >> "%DATA_DIR%\dominios.txt"
    echo # Dominios C^&C ^(FORMATO [.] para seguranca^) >> "%DATA_DIR%\dominios.txt"
    echo sorvetenopoate[.]com >> "%DATA_DIR%\dominios.txt"
    echo sorvetenoopote[.]com >> "%DATA_DIR%\dominios.txt"
    echo etenopote[.]com >> "%DATA_DIR%\dominios.txt"
    echo expahnsiveuser[.]com >> "%DATA_DIR%\dominios.txt"
    echo sorv[.]etenopote[.]com >> "%DATA_DIR%\dominios.txt"
    echo sorvetenopotel[.]com >> "%DATA_DIR%\dominios.txt"
    echo cliente[.]rte[.]com[.]br >> "%DATA_DIR%\dominios.txt"
)

if not exist "%DATA_DIR%\caminhos.txt" (
    echo # Locais de verificacao para campanha SORVEPOTEL > "%DATA_DIR%\caminhos.txt"
    echo # Baseado em analise comportamental do malware >> "%DATA_DIR%\caminhos.txt"
    echo. >> "%DATA_DIR%\caminhos.txt"
    echo # Diretorios de usuario >> "%DATA_DIR%\caminhos.txt"
    echo %%USERPROFILE%%\Desktop >> "%DATA_DIR%\caminhos.txt"
    echo %%USERPROFILE%%\Downloads >> "%DATA_DIR%\caminhos.txt"
    echo %%USERPROFILE%%\Documents >> "%DATA_DIR%\caminhos.txt"
    echo %%USERPROFILE%%\AppData\Local\Temp >> "%DATA_DIR%\caminhos.txt"
    echo %%USERPROFILE%%\AppData\Roaming >> "%DATA_DIR%\caminhos.txt"
    echo %%USERPROFILE%%\AppData\Local >> "%DATA_DIR%\caminhos.txt"
    echo. >> "%DATA_DIR%\caminhos.txt"
    echo # Diretorios do sistema >> "%DATA_DIR%\caminhos.txt"
    echo %%TEMP%% >> "%DATA_DIR%\caminhos.txt"
    echo %%APPDATA%% >> "%DATA_DIR%\caminhos.txt"
    echo %%PROGRAMDATA%% >> "%DATA_DIR%\caminhos.txt"
    echo %%WINDIR%%\Temp >> "%DATA_DIR%\caminhos.txt"
    echo. >> "%DATA_DIR%\caminhos.txt"
    echo # Locais de persistencia >> "%DATA_DIR%\caminhos.txt"
    echo %%APPDATA%%\Microsoft\Windows\Start Menu\Programs\Startup >> "%DATA_DIR%\caminhos.txt"
    echo %%USERPROFILE%%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup >> "%DATA_DIR%\caminhos.txt"
    echo %%PROGRAMDATA%%\Microsoft\Windows\Start Menu\Programs\Startup >> "%DATA_DIR%\caminhos.txt"
)

if not exist "%DATA_DIR%\reg.txt" (
    echo # Chaves de registro suspeitas - Campanha SORVEPOTEL > "%DATA_DIR%\reg.txt"
    echo # APENAS chaves especificamente relacionadas ao malware >> "%DATA_DIR%\reg.txt"
    echo # Nao incluir chaves legítimas do Windows >> "%DATA_DIR%\reg.txt"
    echo. >> "%DATA_DIR%\reg.txt"
    echo # Chaves especificas do malware SORVEPOTEL >> "%DATA_DIR%\reg.txt"
    echo HKEY_CURRENT_USER\Software\SORVEPOTEL >> "%DATA_DIR%\reg.txt"
    echo HKEY_LOCAL_MACHINE\SOFTWARE\SORVEPOTEL >> "%DATA_DIR%\reg.txt"
    echo HKEY_CURRENT_USER\Software\sorvetenopote >> "%DATA_DIR%\reg.txt"
    echo HKEY_LOCAL_MACHINE\SOFTWARE\sorvetenopote >> "%DATA_DIR%\reg.txt"
    echo. >> "%DATA_DIR%\reg.txt"
    echo # Chaves modificadas por malware ^(COM CAUTELA^) >> "%DATA_DIR%\reg.txt"
    echo HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\RunOnce >> "%DATA_DIR%\reg.txt"
    echo HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce >> "%DATA_DIR%\reg.txt"
)
goto :eof
