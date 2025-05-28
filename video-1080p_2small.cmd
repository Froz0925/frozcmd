@echo off
:: Froz 25.05.2025 + ИИ Qwen
:: Заготовка, требует тестирования !!!

:: === Блок: Настройки кодирования ===

:: Масштабирование видео (scale):
::    1280:720 - масштабировать до конкретного разрешения
::    1280:-1   - сохранить пропорции, ширина=1280, высота автоматическая.
::        Также можно и для высоты: -1:720.
::    если указанный здесь совпадёт с исходным, 
::    или если не задано - размер остаётся без изменений
set "SCALE=1280:720"

:: Поворот видео (Rotation tag).
:: ВАЖНО: Аппаратные кодеки hevc_qsv и hevc_d3d12va НЕ подддерживают поворот - будет ошибка.
:: Кодек hevc_amf может иметь ошибки с поворотом
:: Возможные значения:
::    90 - поворот по часовой стрелке на 90 градусов
::    180 - поворот на 180 градусов
::    270 - поворот против часовой стрелки на 90 градусов
::    если не задано - поворот берётся из файла (rotation tag)
set "ROTATION="

:: Аудио-настройки - по умолчанию копирование аудиодорожки
:: Можно использовать "-c:a libopus -b:a 128k" для уменьшения размера
set "AUDIO_ARGS=-c:a copy"

:: CRF (уровень качества).
:: Рекомендуемые значения по убыванию качества и размера файла:
::    Для HEVC:  24-28
::    Для H.264: 20-23
:: Если не задано - выбирает кодек.
set "CRF="

:: Кодек и параметры кодирования:
:: HEVC (H.265) кодеки:
::    hevc_nvenc   - NVIDIA GPU (рекомендуемый)
::    hevc_amf     - AMD GPU
::    hevc_qsv     - Intel Quick Sync Video
::    hevc_d3d12va - Windows Direct 12 (DXVA2), аппаратная поддержка
::    libx265      - software кодирование HEVC (очень медленно)
:: H.264 кодеки:
::    h264_nvenc   - NVIDIA GPU (рекомендуемый)
::    h264_amf     - AMD GPU
::    h264_qsv     - Intel Quick Sync Video
::    libx264      - software кодирование H.264 (медленный)
set "CODEC=hevc_nvenc"

:: Профиль кодирования.
::    для HEVC: main10 - 10 bit, main - 8 bit.
::    для H.264: автоматически выбирается high, независимо от указанного здесь.
:: Если не задано - выбирает кодек.
:: main10 поддерживают: hevc_nvenc, hevc_amf, libx265
:: main10 может не воспроизводиться в старых проигрывателях и устройствах!
set "PROFILE=main10"

:: Preset для hevc_nvenc (скорость/качество). Возможные значения: p1-p7 (скорость-качество).
:: Если не задано - выбирает кодек (hevc_nvenc обычно p4/p5)
set "PRESET="

:: Допустимые значения: .mkv (универсальнее) или .mp4.
:: Для аппаратных кодеков H.264 - лучше выбрать .mp4.
set "OUTPUT_EXT=.mkv"

:: Приставка к выходному имени файла (можно изменять или оставить пустой)
set "NAME_APPEND=_sm"

:: === Окончание блока настроек ===





:: === Блок: Проверки ===
:: Проверка архитектуры ОС
:: Если переменная ProgramFiles(x86) не определена - система 32-битная (не поддерживается)
if "%ProgramFiles(x86)%"=="" (
    echo Windows 32-bit не поддерживается.
    echo.
    pause
    exit /b
)


:: Проверка наличия входных файлов
if "%~1" == "" (
    echo.
    echo Использование: перетяните иил вставьте видеофайлы на этот файл.
    echo.
    pause
    exit /b
)


:: Переход в папку со скриптом, это важно для корректного вызова bin\ffmpeg.exe и bin\ffprobe.exe
pushd "%~dp0"
:: ВАЖНО - если будет enabledelayedexpansion - она должна быть после PUSHD
:: иначе некорректно обработаются пути с "!".
:: ВАЖНО - не используем комментарии с :: внутри if for else - там пишем rem Текст

:: Проверка наличия необходимых утилит
:: ffmpeg - для конвертации видео
:: ffprobe - для извлечения информации о видеофайле
if not exist "bin\ffmpeg.exe" (
    echo bin\ffmpeg.exe не найден, выходим.
    exit /b
)
if not exist "bin\ffprobe.exe" (
    echo bin\ffprobe.exe не найден, выходим.
    exit /b
)




:: === Начинаем обработку файлов ===
:FILE_LOOP
if "%~1" == "" goto :FILE_LOOP_END


::  === Блок: Подготовка ===
:: Подготовка путей
:: Формируем имя выходного файла и путь к логу
:: Проверяем, существует ли уже обработанный файл - если да, пропускаем
:: Жёстко задаём формат видеоконтейнера MKV, как наиболее беспроблемный в сочетаниях видов видео-аудио дорожек
set "OUTPUT_DIR=%~dp1"
set "OUTPUT_NAME=%~n1%NAME_APPEND%"
set "OUTPUT=%OUTPUT_DIR%OUTPUT_NAME%%OUTPUT_EXT%"
set "OUTPUT=%OUTPUT_DIR%%OUTPUT_NAME%%OUTPUT_EXT%"
set "LOG_DIR=%OUTPUT_DIR%logs\"
set "FFMPEG_LOG=%LOG_DIR%%~n1%NAME_APPEND%_log.txt"

:: Проверяем что конечный файл уже может существовать
if exist "%OUTPUT%" (
    echo Файл %OUTPUT% уже существует, пропускаем.
    shift
    goto :FILE_LOOP
)

:: Создаём папку для логов, если не существует
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" 2>nul
if not exist "%LOG_DIR%" (
    echo Не удалось создать папку для логов: %LOG_DIR%. Выходим.
    pause
    exit /b 1
)

:: Теперь можно выводить сообщения и в консоль и в лог
type nul > "%FFMPEG_LOG%" 2>nul
call :log ---------------------------------------------------------------------
call :log [LOG START: %DATE% %TIME%]
call :log [FILE] Начата обработка файла "%~nx1"...

:: Проверяем что исходный файл существует
if not exist "%~1" (
    call :log [ERROR] Файл "%~1" не найден.
    shift
    goto :FILE_LOOP
)




:: === Блок: COLOR_RANGE и PIX_FMT ===

:: Получаем pix_fmt через ffprobe
set "PIX_FMT="
set "TMP_FILE=%TEMP%\ffprobe_pix_fmt.tmp"
"bin\ffprobe.exe" -v error -select_streams v:0 -show_entries stream=pix_fmt -of default=nw=1 "%~1" > "%TMP_FILE%" 2>nul
if exist "%TMP_FILE%" (
    set /p PIX_FMT= < "%TMP_FILE%"
    del "%TMP_FILE%"
) else (
    set "PIX_FMT="
)

:: Определение цветового пространства (color_range)
set "COLOR_RANGE="

:: Если pix_fmt = yuvj420p - это full-range JPEG, устанавливаем color_range=jpeg
if "%PIX_FMT%" == "yuvj420p" (
    set "COLOR_RANGE=-color_range jpeg"
    call :log [INFO] Найден формат пикселей: %PIX_FMT% - будет использован %COLOR_RANGE%.
    goto :SKIP_COLORRANGE
)
:: Если pix_fmt определён, но не yuvj420p - на случай связки yuv420p + color_range jpeg
:: пытаемся получить color_range из metadata
set "TMP_FILE=%TEMP%\ffprobe_color_range.tmp"
"bin\ffprobe.exe" -v error -select_streams v:0 -show_entries stream=color_range -of default=nw=1 "%~1" > "%TMP_FILE%" 2>nul
if exist "%TMP_FILE%" (
    set /p COLOR_RANGE_RAW= < "%TMP_FILE%"
    del "%TMP_FILE%"
    if /i "%COLOR_RANGE_RAW%" == "jpeg" (
        call :log [INFO] В metadata найден цветовой диапазон jpeg - будет учтён при кодировании.
    )
    set "COLOR_RANGE=-color_range %COLOR_RANGE_RAW%"
)
:: === Отключаем color_range для несовместимых кодеков ===
set "USE_COLOR_RANGE=%COLOR_RANGE%"
set "NO_COLOR_RANGE_CODECS=hevc_qsv hevc_d3d12va h264_qsv h264_d3d12va"
echo.%NO_COLOR_RANGE_CODECS% | findstr /i /c:"%CODEC%" >nul && goto :DISABLE_COLOR_RANGE
:: Если мы здесь - кодек поддерживает color_range
goto :SKIP_COLORRANGE
:DISABLE_COLOR_RANGE
set "USE_COLOR_RANGE="
:SKIP_COLORRANGE






:: === Блок: ROTATION ===
:: Определение поворота из метаданных и формирование фильтра transpose
set "ROTATION_FILTER="

:: Проверяем, задан ли ROTATION вручную
if defined ROTATION goto :APPLY_ROTATION_MANUAL

:: Если нет - пытаемся получить тег rotate из metadata
set "TMP_FILE=%TEMP%\ffprobe_rotation.tmp"
"bin\ffprobe.exe" -v error -show_entries stream_tags=rotate -of default=nw=1 "%~1" > "%TMP_FILE%" 2>nul

if not exist "%TMP_FILE%" goto :NO_ROTATION_TAG
set /p ROTATION_TAG= < "%TMP_FILE%"
del "%TMP_FILE%"

if not defined ROTATION_TAG goto :NO_ROTATION_TAG
set "ROTATION=%ROTATION_TAG%"

:CHECK_ROTATION_SUPPORT
set "UNSUPPORTED_ROTATION_CODECS=hevc_qsv hevc_d3d12va h264_qsv h264_d3d12va"
echo.%UNSUPPORTED_ROTATION_CODECS% | find /i " %CODEC% " >nul && (
    call :log [INFO] Кодек "%CODEC%" НЕ поддерживает поворот - значение игнорируется.
    set "ROTATION="
    set "ROTATION_TAG="
    set "ROTATION_FILTER="
    goto :SKIP_ROTATION
)

:: Формируем фильтр поворота
if "%ROTATION%" == "90" (
    call :log [INFO] В metadata найден поворот на 90 гр. по часовой стрелке - будет учтён кодером.
    set "ROTATION_FILTER=transpose=1"
    goto :ROTATION_APPLIED
)
if "%ROTATION%" == "180" (
    call :log [INFO] В metadata найден поворот на 180 гр. - будет учтён кодером.
    set "ROTATION_FILTER=transpose=2,transpose=2"
    goto :ROTATION_APPLIED
)
if "%ROTATION%" == "270" (
    call :log [INFO] В metadata найден поворот на 90 гр. против часовой стрелки - будет учтён кодером.
    set "ROTATION_FILTER=transpose=2"
    goto :ROTATION_APPLIED
)

:NO_ROTATION_TAG
call :log [INFO] В metadata не найден тег rotate или он пуст.
set "ROTATION="

:ROTATION_APPLIED
:SKIP_ROTATION





:: === Блок: SCALE ===
:: Обработка масштабирования видео (scale)
set "SCALE_EXPR="
set "TARGET_W="
set "TARGET_H="
:: Если SCALE не задан пользователем - пропускаем обработку
if not defined SCALE goto :SKIP_SCALE
:: Проверяем SCALE на формат число:число или -1:число
echo.%SCALE% | findstr /r "^[0-9\-]*:[0-9\-]*$" >nul || (
    call :log [INFO] Неверный формат SCALE: "%SCALE%" - должен быть например 1280:720 или 1280:-1
    goto :SKIP_SCALE
)
:: Разбираем TARGET_W и TARGET_H из SCALE
for /f "tokens=1,2 delims=:" %%w in ("%SCALE%") do (
    set "TARGET_W=%%w"
    set "TARGET_H=%%h"
)
:: Проверяем TARGET_W и TARGET_H на числа или -1
echo.%TARGET_W% | findstr /r "^[0-9\-][0-9]*$" >nul || (
    call :log [ERROR] TARGET_W некорректен: %TARGET_W%
    goto :SKIP_SCALE
)
echo.%TARGET_H% | findstr /r "^[0-9\-][0-9]*$" >nul || (
    call :log [ERROR] TARGET_H некорректен: %TARGET_H%
    goto :SKIP_SCALE
)
:: Если есть поворот на 90 или 270 - меняем местами TARGET_W и TARGET_H
if "%ROTATION%" == "90" (
    set "TMP=%TARGET_W%"
    set "TARGET_W=%TARGET_H%"
    set "TARGET_H=%TMP%"
    goto :AFTER_ROTATION_SWAP
)
if "%ROTATION%" == "270" (
    set "TMP=%TARGET_W%"
    set "TARGET_W=%TARGET_H%"
    set "TARGET_H=%TMP%"
    goto :AFTER_ROTATION_SWAP
)
:AFTER_ROTATION_SWAP

:: Пытаемся получить текущее разрешение через ffprobe (до поворота)
:: Используем временный файл, так как здесь вывод ffprobe может содержать:
::     - пробелы (например, "1920 1080")
::     - специальные символы (например, escape-символы, двоеточия)
::     - пустые строки или ошибки
:: Примеры, которые сломают цикл for /f:
::     - "1920 1080" > при нормализации становится "19201080" (неверно)
::     - "error" > будет считаться как ширина/высота
:: Поэтому безопаснее читать через set /p < file
set "CURRENT_DIM="
set "TMP_FILE=%TEMP%\video_info.tmp"
"bin\ffprobe.exe" -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "%~1" > "%TMP_FILE%" 2>nul
if not exist "%TMP_FILE%" (
    call :log [ERROR] Не удалось получить информацию о размере видео.
    goto :SKIP_SCALE
)
set /p CURRENT_DIM= < "%TMP_FILE%"
del "%TMP_FILE%"
:: Проверяем формат вывода width,height
echo.%CURRENT_DIM% | findstr /r /c:"^[0-9][0-9]*,[0-9][0-9]*$" >nul || (
    call :log [ERROR] Неверный формат вывода ширины/высоты от ffprobe, пропускаем: "%CURRENT_DIM%"
    goto :SKIP_SCALE
)
:: Разбираем значения ширины и высоты из файла
for /f "tokens=1,2 delims=," %%a in ("%CURRENT_DIM%") do (
    set "CURRENT_W=%%a"
    set "CURRENT_H=%%b"
)
:: Если целевой размер совпадает с исходным - не масштабируем
if "%CURRENT_W%" == "%TARGET_W%" if "%CURRENT_H%" == "%TARGET_H%" (
    call :log [INFO] Размер совпадает с целевым. Масштабирование отключено.
    goto :SKIP_SCALE
)
:: Формируем scale по условию
if "%TARGET_H%" == "-1" (
    set "SCALE_EXPR=scale=%TARGET_W%:-2"
    call :log [INFO] Делаем масштабирование по ширине: %SCALE_EXPR%
    goto :SCALE_DONE
)
if "%TARGET_W%" == "-1" (
    set "SCALE_EXPR=scale=-2:%TARGET_H%"
    call :log [INFO] Делаем масштабирование по высоте: %SCALE_EXPR%
    goto :SCALE_DONE
)
:: Если указано точное разрешение - используем force_original_aspect_ratio + pad
set "SCALE_EXPR=scale=%TARGET_W%:%TARGET_H%:force_original_aspect_ratio=decrease,pad=%TARGET_W%:%TARGET_H%:(ow-iw)/2:(oh-ih)/2"
call :log [INFO] Делаем масштабирование с сохранением пропорций: %SCALE_EXPR%
:SCALE_DONE
:SKIP_SCALE





:: === Блок: FPS ===
:: Получение частоты кадров (r_frame_rate) через ffprobe
set "RAW_FPS="
set "FPS="
set "TMP_FILE=%TEMP%\ffprobe_fps.tmp"
"bin\ffprobe.exe" -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=nw=1 "%~1" > "%TMP_FILE%" 2>nul
if not exist "%TMP_FILE%" (
    call :log [INFO] Не удалось получить r_frame_rate из файла.
    goto :SKIP_FPS
)
set /p RAW_FPS= < "%TMP_FILE%"
del "%TMP_FILE%"


:: Проверяем формат вывода FPS на N/A, 0/0, .../0, 0/...
echo.%RAW_FPS% | findstr /r "^[0-9]\+/[0-9]\+$" >nul || (
    call :log [INFO] Неверный формат FPS: %RAW_FPS% - значение игнорируется.
    goto :SKIP_FPS
)
for /f "tokens=1,2 delims=/" %%a in ("%RAW_FPS%") do (
    if "%%a" == "0" (
        call :log [INFO] Числитель FPS равен 0 - значение игнорируется.
        goto :SKIP_FPS
    )
    if "%%b" == "0" (
        call :log [INFO] Знаменатель FPS равен 0 - значение игнорируется.
        goto :SKIP_FPS
    )
)
:: Если всё верно - применяем
set "FPS=fps=%RAW_FPS%,"
call :log [INFO] Найден FPS: %RAW_FPS%.
:SKIP_FPS





:: === Блок: Сборка видефильтра (-vf) ===
:: Объединяем rotate, scale, fps
set "FILTER_LIST="
if defined ROTATION_FILTER set "FILTER_LIST=%FILTER_LIST%%ROTATION_FILTER%,"
if defined SCALE_EXPR set "FILTER_LIST=%FILTER_LIST%%SCALE_EXPR%,"
if defined FPS set "FILTER_LIST=%FILTER_LIST%%FPS%"
:: Убираем завершающую запятую
:: иначе строка -vf будет некорректна (например: "scale=1280:720,fps=30,)"
if not "%FILTER_LIST%" == "" (
    if "%FILTER_LIST:~-1%" == "," set "FILTER_LIST=%FILTER_LIST:~0,-1%"
)
if defined FILTER_LIST set "VF=-vf %FILTER_LIST%"





:: === Блок: Формат пикселей (pix_fmt) ===
set "PIX_FMT_ARGS="
:: Эти кодеки поддерживают p010le
if /i "%CODEC%" == "hevc_nvenc" (
    set "PIX_FMT_ARGS=-pix_fmt p010le"
    goto :PIX_FMT_DONE
)
if /i "%CODEC%" == "libx265" (
    set "PIX_FMT_ARGS=-pix_fmt yuv420p10le"
    goto :PIX_FMT_DONE
)
if /i "%CODEC%" == "libx264" (
    set "PIX_FMT_ARGS=-pix_fmt yuv420p"
    goto :PIX_FMT_DONE
)
:: Эти кодеки НЕ поддерживают p010le
if /i "%CODEC%" == "hevc_qsv" goto :PIX_FMT_DONE
if /i "%CODEC%" == "hevc_d3d12va" goto :PIX_FMT_DONE
if /i "%CODEC%" == "h264_qsv" goto :PIX_FMT_DONE
if /i "%CODEC%" == "h264_d3d12va" goto :PIX_FMT_DONE
:: По умолчанию используем yuv420p для H.264
if /i "%CODEC:~0,5%" == "h264_" (
    set "PIX_FMT_ARGS=-pix_fmt yuv420p"
)
:PIX_FMT_DONE




:: === Блок: Профиль кодирования (profile:v) ===
set "USE_PROFILE=main"
if /i "%CODEC%" == "hevc_qsv" goto :PROFILE_DONE
if /i "%CODEC%" == "hevc_d3d12va" goto :PROFILE_DONE
set "USE_PROFILE=high"
if /i "%CODEC%" == "h264_nvenc" goto :PROFILE_DONE
if /i "%CODEC%" == "h264_amf" goto :PROFILE_DONE
if /i "%CODEC%" == "h264_qsv" goto :PROFILE_DONE
if /i "%CODEC%" == "libx264" goto :PROFILE_DONE
set "USE_PROFILE=main10"
if /i "%PROFILE%" == "main" set "USE_PROFILE=main"
:PROFILE_DONE




:: === Блок: Формирование команды ffmpeg ===
set "FINAL_KEYS=-hide_banner -c:v %CODEC% -profile:v %USE_PROFILE% %VF% %PIX_FMT_ARGS% %USE_COLOR_RANGE% %AUDIO_ARGS% -c:s copy"
:: --- CRF и аналоги по кодекам ---
if not defined CRF goto :SKIP_CRF
if /i "%CODEC%" == "libx265" (
    set "FINAL_KEYS=%FINAL_KEYS% -crf %CRF%"
    goto :SKIP_CRF
)
if /i "%CODEC%" == "hevc_nvenc" (
    set "FINAL_KEYS=%FINAL_KEYS% -cq %CRF%"
    goto :SKIP_CRF
)
if /i "%CODEC%" == "hevc_amf" (
    set "FINAL_KEYS=%FINAL_KEYS% -quality %CRF%"
    goto :SKIP_CRF
)
if /i "%CODEC%" == "hevc_qsv" (
    set "FINAL_KEYS=%FINAL_KEYS% -global_quality %CRF%"
    goto :SKIP_CRF
)
if /i "%CODEC%" == "libx264" (
    set "FINAL_KEYS=%FINAL_KEYS% -crf %CRF%"
    goto :SKIP_CRF
)
if /i "%CODEC%" == "h264_nvenc" (
    set "FINAL_KEYS=%FINAL_KEYS% -cq %CRF%"
    goto :SKIP_CRF
)
if /i "%CODEC%" == "h264_amf" (
    set "FINAL_KEYS=%FINAL_KEYS% -quality %CRF%"
    goto :SKIP_CRF
)
if /i "%CODEC%" == "h264_qsv" (
    set "FINAL_KEYS=%FINAL_KEYS% -global_quality %CRF%"
    goto :SKIP_CRF
)
:SKIP_CRF




: === Блок: Preset и hwaccel ===
:: Для HEVC и H.264
if /i "%CODEC%" == "hevc_nvenc" if defined PRESET set "FINAL_KEYS=%FINAL_KEYS% -preset %PRESET%"
if /i "%CODEC%" == "h264_nvenc" if defined PRESET set "FINAL_KEYS=%FINAL_KEYS% -preset %PRESET%"
if /i "%CODEC%" == "hevc_amf" if defined PRESET set "FINAL_KEYS=%FINAL_KEYS% -quality %PRESET%"
if /i "%CODEC%" == "h264_amf" if defined PRESET set "FINAL_KEYS=%FINAL_KEYS% -quality %PRESET%"
if /i "%CODEC%" == "hevc_qsv" if defined PRESET set "FINAL_KEYS=%FINAL_KEYS% -preset %PRESET%"
if /i "%CODEC%" == "h264_qsv" if defined PRESET set "FINAL_KEYS=%FINAL_KEYS% -preset %PRESET%"
:: HWACCEL для некоторых кодеков
if /i "%CODEC%" == "hevc_d3d12va" set "FINAL_KEYS=-hwaccel d3d12va %FINAL_KEYS%"
if /i "%CODEC%" == "hevc_qsv" set "FINAL_KEYS=-hwaccel qsv %FINAL_KEYS%"
if /i "%CODEC%" == "h264_d3d12va" set "FINAL_KEYS=-hwaccel d3d12va %FINAL_KEYS%"
if /i "%CODEC%" == "h264_qsv" set "FINAL_KEYS=-hwaccel qsv %FINAL_KEYS%"
:: Level и Tune (для H.264)
if /i "%CODEC%" == "libx264" set "FINAL_KEYS=%FINAL_KEYS% -tune film"
if /i "%CODEC:~0,5%" == "h264_" set "FINAL_KEYS=%FINAL_KEYS% -level 4.0"




:: === Блок: Запуск ffmpeg ===
call :log [INFO] Кодек: %CODEC%, Профиль: %USE_PROFILE%, CRF: %CRF%, Preset: %PRESET%
call :log [CMD] %FINAL_KEYS% "%OUTPUT%"
set "CMD_LINE=bin\ffmpeg.exe -i "%~1" %FINAL_KEYS% "%OUTPUT%""
call :log [CMD] %CMD_LINE%
call :log  --------------------------------------------------
"%~dp0%bin\ffmpeg.exe" -i "%~1" %FINAL_KEYS% "%OUTPUT%" 2>> "%FFMPEG_LOG%"
set "FFMPEG_EXIT_CODE=%errorlevel%"
:: Анализ результата выполнения
if %FFMPEG_EXIT_CODE% equ 0 goto :FFMPEG_SUCCESS
    echo [ERROR] FFmpeg завершился с кодом ошибки %FFMPEG_EXIT_CODE% >> "%FFMPEG_LOG%"
    goto :FFMPEG_DONE
:FFMPEG_SUCCESS
    echo [SUCCESS] Обработка успешно завершена >> "%FFMPEG_LOG%"
:FFMPEG_DONE
    echo [LOG END: %DATE% %TIME%] >> "%FFMPEG_LOG%"
:: Переход к следующему файлу
shift
goto :FILE_LOOP
:: Завершение работы
:FILE_LOOP_END
    echo Информация: Все файлы обработаны. Результаты и ошибки см. в логах.
    popd
    exit /b 0




:: ---------------------
:: Подпрограммы для CALL
:: ---------------------
:: Логирование в консоль и в файл
:log
echo:%~1
if exist "%FFMPEG_LOG%" echo:%~1 >> "%FFMPEG_LOG%"
exit /b
