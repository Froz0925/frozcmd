@echo off
set "VERS=Froz video recode script v27.06.2025"
:: Цель скрипта: перекодирование видеофайлов с телефонов/фотоаппаратов
:: в уменьшенный размер для видеоархива без существенной потери качества.


:: === Блок: Настройки ===

:: Новая высота видео (опционально). Примеры: 720, 480
:: Если не задано - остаётся без изменений.
:: Нет особого смысла понижать 1080 до 720 - размер увеличивается незначительно
set "SCALE="

:: Поворот видео (Rotation tag).
:: ВАЖНО: Аппаратные кодеки hevc_qsv hevc_d3d12va h264_qsv h264_d3d12va
:: НЕ подддерживают поворот - ключ будет проигнорирован!.
:: Кодек hevc_amf может иметь ошибки с поворотом!
:: Возможные значения:
::    90 - поворот по часовой стрелке на 90 градусов
::    180 - поворот на 180 градусов
::    270 - поворот против часовой стрелки на 90 градусов
::    Если не задано - поворот берётся из файла (rotation tag)
set "ROTATION="

:: Кодек и параметры кодирования:
:: HEVC (H.265) кодеки:
::    hevc_nvenc   - NVIDIA GPU (рекомендуемый, требуется Nvidia GeForce GTX 950 и выше и драйвер 570+)
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

:: Preset для hevc_nvenc (скорость/качество). Возможные значения: p1-p7 (скорость-качество).
:: Если не задано - по умолчанию hevc_nvenc выбирает p4 (~CRF20, на 720p ~2,5 Мбит/с)
set "PRESET="

:: Профиль кодирования.
::    для HEVC: main10 - 10 bit, main - 8 bit.
::    для H.264: автоматически выбирается high, независимо от указанного здесь.
:: Если не задано - выбирает кодек.
:: main10 поддерживают: hevc_nvenc, hevc_amf, libx265
:: main10 может не воспроизводиться в старых проигрывателях и устройствах!
set "PROFILE=main10"

:: CRF - "уровень качества". Если не задано - выбирает кодек.
:: Рекомендуемые значения по убыванию качества и размера файла: 20-24
:: hevc_nvenc автоматом ставит нормальный уровень, примерно равный CRF20.
:: Для libx265/264 лучше принудительно ставить CRF20 иначе он выберет низкое качество CRF28
:: CRF20 в 720p это ~2,5 мбит/с
set "CRF="

:: Аудио-настройки - по умолчанию копирование аудиодорожки
:: Можно использовать "-c:a libopus -b:a 128k" для уменьшения размера
set "AUDIO_ARGS=-c:a copy"

:: Костыль - установить в 1 на редкий случай если входное видео -
:: Full Range JPEG, но не YUVJ420P.
set "FORCE_FULL_RANGE="

:: FPS - установка целевой частоты кадров (необязательно)
:: Примеры: 24, 25, 30, 50, 60, 24000/1001 (~23.976), 30000/1001 (~29.97) и т.п.
:: Если не задано - частота кадров берётся из исходника (FPS CFR или VFR).
:: Пример: set "FPS=30000/1001"
set "FPS="

:: Допустимые значения: mkv (универсальнее) или mp4.
:: Для аппаратных кодеков H.264 - лучше выбрать mp4.
set "OUTPUT_EXT=mkv"

:: Приставка к выходному имени файла (можно изменять или оставить пустой)
set "NAME_APPEND=_sm"

:: === Окончание блока настроек ===





:: === Блок: Проверки ===
echo.
echo.%VERS%
echo.------------------------------------
:: Проверка наличия входных файлов
if "%~1" == "" (
    echo.Использование: Отредактируйте SET в начале скрипта.
    echo.Затем перетяните или вставьте видеофайлы на этот файл.
    echo.Выходим.
    pause & exit /b
)
:: Проверка наличия утилит
set "FFM=%~dp0bin\ffmpeg.exe"
set "FFP=%~dp0bin\ffprobe.exe"
set "MI=%~dp0bin\mediainfo.exe"
set "MKVP=%~dp0bin\mkvpropedit.exe"
if not exist "%FFM%" echo.%FFM% не найден, выходим.& pause & exit /b
if not exist "%FFP%" echo.%FFP% не найден, выходим.& pause & exit /b
if not exist "%MI%" echo.%MI% не найден, выходим.& pause & exit /b
if not exist "%MKVP%" echo.%MKVP% не найден, выходим.& pause & exit /b





:: === Блок: Старт ===
:FILE_LOOP
:: Записываем имя файла в переменные чтобы %1 не сломалось в процессе
set "FNF=%~1"
set "FNN=%~n1"
set "FNWE=%~nx1"

:: Если больше нет файлов - выходим
if "%FNF%" == "" goto FILE_LOOP_END

:: Временное имя OEM-лога
set "td=%date:~0,2%"
set "tm=%date:~3,2%"
set "ty=%date:~6,4%"
set "thh=%time:~0,2%"
if not "%thh:~0,1%"==" " goto thh_ok
set "thh=0%thh:~1,1%"
:thh_ok
set "tmm=%time:~3,2%"
set "tss=%time:~6,2%"
set "TYMDHMS=%ty%-%tm%-%td%_%thh%-%tmm%-%tss%"

:: Имена и папка логов
set "OUTPUT_DIR=%~dp1"
set "OUTPUT_NAME=%FNN%%NAME_APPEND%"
set "OUTPUT=%OUTPUT_DIR%%OUTPUT_NAME%.%OUTPUT_EXT%"
set "LOGE=%TYMDHMS%oem"
set "LOG=%OUTPUT_DIR%logs\%LOGE%"
set "LOGU=%TYMDHMS%utf"
set "LOGN=%FNN%%NAME_APPEND%-log.txt"

:: Совместить логи в один файл не получится, т.к. ffmpeg выводит лог в UTF-8, а cmd в OEM
set "FFMPEG_LOG_NAME=%OUTPUT_NAME%-log_ffmpeg.txt"
set "FFMPEG_LOG=%OUTPUT_DIR%logs\%FFMPEG_LOG_NAME%"
if not exist "%OUTPUT_DIR%logs" md "%OUTPUT_DIR%logs"

:: Проверяем что конечный файл уже существует и ненулевого размера
if not exist "%OUTPUT%" goto DONE_SIZE_CHK
for %%F in ("%OUTPUT%") do set SIZE=%%~zF
if %SIZE% EQU 0 (
    del "%OUTPUT%"
    goto DONE_SIZE_CHK
)
echo.%OUTPUT_NAME% уже существует, пропускаем.
goto NEXT
:DONE_SIZE_CHK
title Обработка %FNWE%...
echo.%DATE% %TIME:~0,8% Начата обработка %FNWE%...
echo.[INFO] %DATE% %TIME:~0,8% Начата обработка %FNWE%...>"%LOG%"








:: === Блок: ВРЕМЯ ===
:: Получаем длительность видео. Ключ :nk=1 отбросит текст "duration="
set "TMP_FILE=%TEMP%\ffprobe_time.tmp"
"%FFP%" -v error -show_entries format=duration -of default=nw=1:nk=1 "%FNF%" > "%TMP_FILE%" 2>nul
set /p LENGTH_SECONDS= <"%TMP_FILE%"
del "%TMP_FILE%"
if not defined LENGTH_SECONDS (
    echo Не удалось извлечь длительность видео.
    goto DONE_LENGTH
)

:: Оставляем только целые секунды
for /f "tokens=1 delims=." %%a in ("%LENGTH_SECONDS%") do set "LENGTH_SECONDS=%%a"

:: Добавляем +1, чтобы округлить вверх
set /a LENGTH_SECONDS+=1

:: Рассчитываем время кодирования исходя из X.X секунд на секунду видео для кодеков на CPU i3-2120:
:: 0.3 - *nvenc, libx264. 5.0 - libx265
:: Для вставки в формулу - умножаем время на 10
if /i "%CODEC:~5%" == "nvenc" set /a "ENCODE_SECONDS=(LENGTH_SECONDS * 3) / 10"
if /i "%CODEC%" == "libx265" set /a "ENCODE_SECONDS=(LENGTH_SECONDS * 50) / 10"

:: Переводим в формат минуты:секунды
set /a "MINUTES=ENCODE_SECONDS / 60"
set /a "SECONDS=ENCODE_SECONDS %% 60"
if %SECONDS% LSS 10 set "SECONDS=0%SECONDS%"
echo.Примерное время кодирования: %MINUTES% минут %SECONDS% секунд.
:DONE_LENGTH






:: === Блок: COLOR RANGE ===
set "PIX_FMT="
:: Если задан Force full range
set "COLOR_RANGE="
if defined FORCE_FULL_RANGE (
    set "COLOR_RANGE=1"
    echo.[INFO] Задан Force color range>>"%LOG%"
    goto COLOR_RANGE_DONE
)
:: Определение full range через ffprobe. Ключ :nk=1 отбросит текст "pix_fmt="
set "TMP_FILE=%TEMP%\ffprobe_pix_fmt.tmp"
"%FFP%" -v error -select_streams v:0 -show_entries stream=pix_fmt -of default=nw=1:nk=1 "%FNF%" > "%TMP_FILE%" 2>nul
if not exist "%TMP_FILE%" (
    echo.[ERROR] Не получилось создать временный файл %TMP_FILE%>>"%LOG%"
    goto COLOR_RANGE_DONE
)
set /p PIX_FMT= <"%TMP_FILE%"
del "%TMP_FILE%"
if not defined PIX_FMT (
    echo.[ERROR] FFProbe не смог определить формат пикселей>>"%LOG%"
    goto COLOR_RANGE_DONE
)
echo.[INFO] Формат пикселей исходника: %PIX_FMT%>>"%LOG%"
for /f "tokens=1" %%a in ("%PIX_FMT%") do set "PIX_FMT=%%a"
:: Автоопределение full range по pix_fmt
if /i "%PIX_FMT%" == "yuvj420p" (
    set "COLOR_RANGE=1"
)

:: Если OUTPUT_EXT = mp4 - меняем на mkv
if not "%OUTPUT_EXT%" == "mp4" goto COLOR_RANGE_DONE
echo.[INFO] Для записи metadata full color с помощью mkvpropedit - меняем расширение c mp4 на mkv>>"%LOG%"
set "OUTPUT_EXT=mkv"
set "OUTPUT=%OUTPUT_DIR%%OUTPUT_NAME%.%OUTPUT_EXT%"
:COLOR_RANGE_DONE






:: === Блок: CURRENT SIZE ===
:: Получаем исходные размеры видео для поворота и масштабирования через ffprobe
:: Используем временный файл, так как здесь вывод ffprobe может содержать:
::     - пробелы (например, "1920 1080")
::     - специальные символы (например, escape-символы, двоеточия)
::     - пустые строки или ошибки
:: Не используем for /f. Примеры, которые сломают цикл for /f:
::     - "1920 1080" > при нормализации становится "19201080" (неверно)
::     - "error" > будет считаться как ширина/высота
:: Поэтому безопаснее читать через set /p < file
set "CURRENT_DIM="
set "TMP_FILE=%TEMP%\video_info.tmp"
"%FFP%" -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "%FNF%" > "%TMP_FILE%" 2>nul
if not exist "%TMP_FILE%" goto SKIP_CURRENT_DIM
:: Извлекаем первую непустую строку (goto 'выход' нужен для прерывания цикла)
for /f "tokens=1,2 delims=," %%a in ('type "%TMP_FILE%"') do (
    set "CURRENT_W=%%a"
    set "CURRENT_H=%%b"
)
del "%TMP_FILE%"
if not defined CURRENT_W (
    echo.ОШИБКА: FFProbe не смог определить ширину/высоту>>"%LOG%"
    goto SKIP_CURRENT_DIM
)
echo.[INFO] Разрешение исходника: %CURRENT_W%x%CURRENT_H%>>"%LOG%"
:SKIP_CURRENT_DIM




:: === Блок: ROTATION ===
:: Блок должен быть до блока SCALE
set "ROTATION_FILTER="
set "ROTATION_METADATA="

:: Если ROTATION не задан - пытаемся извлечь тег Rotate из файла
if not defined ROTATION goto NO_USER_ROTATION

:: Если задано значение отличное от 0 - используем его
echo.[INFO] Задан USER ROTATION=%ROTATION%>>"%LOG%"
goto APPLY_ROTATION

:NO_USER_ROTATION
set "EXT=%~x1"
if /i "%EXT%" == ".mp4" goto GET_ROTATE
if /i "%EXT%" == ".mov" goto GET_ROTATE
echo.[WARNING] Формат %EXT% не поддерживает тег Rotate - извлечение пропущено.>>"%LOG%"
echo.[WARNING] Если видео повёрнуто - принудительно задайте set ROTATION.>>"%LOG%"
goto NO_ROTATION_TAG

:GET_ROTATE
set "ROTATION_TAG="
set "TMP_FILE=%TEMP%\ffprobe_rotation.tmp"
"%FFP%" -v error -show_entries stream_tags=rotate -of default=nw=1:nk=1 "%FNF%" > "%TMP_FILE%" 2>nul
if not exist "%TMP_FILE%" goto NO_ROTATION_TAG
set /p ROTATION_TAG= < "%TMP_FILE%"
del "%TMP_FILE%"
if not defined ROTATION_TAG goto NO_ROTATION_TAG

:: Удаляем пробелы
set "ROTATION_TAG=%ROTATION_TAG: =%"
echo.[INFO] В metadata найден тег Rotate: "%ROTATION_TAG%">>"%LOG%"

:: Устанавливаем ROTATION только если она ещё не задана
set "ROTATION=%ROTATION_TAG%"

:: Проверяем, поддерживает ли кодек поворот
:APPLY_ROTATION
set "UNSUPPORTED_ROTATION_CODECS= hevc_qsv hevc_d3d12va h264_qsv h264_d3d12va "
echo.%UNSUPPORTED_ROTATION_CODECS% | findstr /i /c:" %CODEC% " >nul && goto SAVE_ROTATION_METADATA

:SET_TRANSPOSE
:: Формируем фильтр поворота
if "%ROTATION%" == "90" (
    set "ROTATION_FILTER=transpose=1"
    echo.[INFO] Применён поворот на 90 градусов по часовой стрелке>>"%LOG%"
    goto ROTATION_DONE
)
if "%ROTATION%" == "180" (
    set "ROTATION_FILTER=transpose=2,transpose=2"
    echo.[INFO] Применён поворот на 180 градусов>>"%LOG%"
    goto ROTATION_DONE
)
if "%ROTATION%" == "270" (
    set "ROTATION_FILTER=transpose=2"
    echo.[INFO] Применён поворот на 90 градусов против часовой стрелки>>"%LOG%"
    goto ROTATION_DONE
)

:: Сюда попадаем, если поворот напрямую невозможен, но можно сохранить как metadata
:SAVE_ROTATION_METADATA

:: Если ранее был установлен full color range и кодек который не умеет поворот видео - имеем проблему:
:: MP4 нужен для записи тега Rotate, MKV нужен для записи metadata color range. Поэтому ошибка и выход.
if defined COLOR_RANGE (
    echo.[ERROR] Для %CODEC% не получится совместить запись тега Rotate и тегов Color Range в одном контейнере.
    echo.[ERROR] Так как тег Color Range важнее, а повернуть можно кодеком - измените кодек.>>"%LOG%"
    echo.Внимание: Найдены Full Color Range и тег Rotate.
    echo.Для %CODEC% не получится совместить запись тега Rotate и тегов Color Range в одном контейнере.
    echo.Так как тег Color Range важнее, а повернуть можно кодеком - измените кодек. Пропускаем файл.
    goto NEXT
)

:: Если OUTPUT_EXT = mkv - меняем на mp4
if not "%OUTPUT_EXT%" == "mkv" goto ROT_EXT_OK
echo.[INFO] Меняем расширение на mp4 для записи тега Rotate>>"%LOG%"
set "OUTPUT_EXT=mp4"
set "OUTPUT=%OUTPUT_DIR%%OUTPUT_NAME%.%OUTPUT_EXT%"
:ROT_EXT_OK

:: Сохраняем как metadata
set "ROTATION_METADATA=-metadata:s:v:0 rotate=%ROTATION%"
echo.[INFO] Так как поворот кодеком невозможен - тег поворота будет сохранён в файле MP4>>"%LOG%"
goto ROTATION_DONE

:: Сюда попадаем, если поворот не определён или некорректен
:NO_ROTATION_TAG
echo.[INFO] В metadata не найден тег rotate или он некорректен. При необходимости задайте set ROTATION принудительно>>"%LOG%"

:ROTATION_DONE







:: === Блок: SCALE (должен быть после ROTATION) ===
:: На будущее - можно перейти на более современный zscale, но он есть не во всех сборках:
:: zscale=width=1280:height=720.
:: или zscale=width='if(lte(iw*9/16,ih*4/3),1280,-2)':height=720
:: но тут могут быть проблемы с экранированием в cmd
:: Полная строка -vf желательно такая:
:: zscale=width=1280:height=720:flags=bitexact+full_chroma_int:rangein=limited:range=full

:: Обработка масштабирования видео (Scale) с учётом Rotation
set "SCALE_EXPR="
:: Если SET SCALE не задан - пропускаем формирование scale_expr
if not defined SCALE (
    echo.[INFO] Высота не задана, масштабирование отключено>>"%LOG%"
    goto SKIP_SCALE
)
set "TARGET_H=%SCALE%"
:: Учитываем поворот: при 90/270 меняем ось масштабирования
if "%ROTATION%"=="90" (
    set "SCALE_EXPR=scale=%SCALE%:-2"
    echo.[INFO] Задан поворот на 90 градусов по часовой стрелке - масштабируем по ширине>>"%LOG%"
    goto SKIP_SCALE
)
if "%ROTATION%"=="270" (
    set "SCALE_EXPR=scale=%SCALE%:-2"
    echo.[INFO] Задан поворот на 90 градусов против часовой стрелки - масштабируем по ширине>>"%LOG%"
    goto SKIP_SCALE
)
:: По умолчанию масштабируем по высоте
set "SCALE_EXPR=scale=-2:%SCALE%"
:SKIP_SCALE






:: === HEIGHT_CHECK ===
:: Проверка совпадения высоты с user set SCALE чтобы не делать перекодирование 1к1 в -vf
set "SRC_H="
set "SKIP_SCALE_FILTER="
:: Если SCALE не задан - пропускаем проверку
if not defined SCALE goto SKIP_HEIGHT_CHECK

:: Получаем исходную высоту через ffprobe, ключ :nk=1 отбросит текст "height="
set "TMP_FILE=%TEMP%\ffprobe_height.tmp"
"%FFP%" -v error -show_entries stream^=height -of default=nw=1:nk=1 "%FNF%" > "%TMP_FILE%" 2>nul
if not exist "%TMP_FILE%" (
    echo.[WARNING] Не удалось получить высоту видео из файла>>"%LOG%"
    goto SKIP_HEIGHT_CHECK
)
set /p SRC_H= < "%TMP_FILE%"
del "%TMP_FILE%"

:: Удаляем пробелы
set "SRC_H=%SRC_H: =%"

:: Проверяем, задан ли ROTATION не равно 0 (принудительный поворот)
set "FORCE_ROTATE="
if not defined ROTATION goto CHECK_SRC_HEIGHT
if "%ROTATION%" == "0" goto CHECK_SRC_HEIGHT
set "FORCE_ROTATE=1"

:CHECK_SRC_HEIGHT
:: Проверяем совпадение высоты
if "%SRC_H%" == "%SCALE%" goto HANDLE_SKIP_SCALE

:: Высота отличается - масштабируем
echo.[INFO] Видео будет масштабировано. Исходная высота: %SRC_H%, целевая: %SCALE%>>"%LOG%"
goto SKIP_HEIGHT_CHECK

:HANDLE_SKIP_SCALE
:: Высота совпадает, проверяем необходимость поворота
if defined FORCE_ROTATE goto SKIP_HEIGHT_CHECK
if defined ROTATION_METADATA goto SKIP_HEIGHT_CHECK

:: Ни поворота, ни метаданных нет - можно пропустить scale
echo.[INFO] Высота %SCALE% уже соответствует файлу. Масштабирование пропущено>>"%LOG%"
set "SKIP_SCALE_FILTER=1"
:SKIP_HEIGHT_CHECK





:: === Блок FPS ===
if defined FPS (
    echo.[INFO] FPS задан принудительно: %FPS%, пропускаем его извлечение.>>"%LOG%"
    goto FPS_DONE
)
:: Получение частоты кадров через ffprobe
set "TMP_FILE=%TEMP%\ffprobe_fps.tmp"
"%FFP%" -v error -select_streams v:0 -show_entries stream=r_frame_rate,avg_frame_rate -of default=nw=1 "%FNF%" > "%TMP_FILE%" 2>nul
if not exist "%TMP_FILE%" (
    echo.[WARNING] Не удалось получить FPS - файл не создан>>"%LOG%"
    goto FPS_DONE
)
:: Извлечение r_frame_rate
for /f "tokens=2 delims==" %%a in ('find "r_frame_rate" "%TMP_FILE%"') do set "R_FPS=%%a"
:: Извлечение avg_frame_rate
for /f "tokens=2 delims==" %%a in ('find "avg_frame_rate" "%TMP_FILE%"') do set "A_FPS=%%a"
del "%TMP_FILE%"
if not defined R_FPS (
    echo.[WARNING] Не удалось найти r_frame_rate>>"%LOG%"
    goto FPS_DONE
)
if not defined A_FPS (
    echo.[WARNING] Не удалось найти avg_frame_rate>>"%LOG%"
    goto FPS_DONE
)

:: Сравниваем значения как строки
if "%R_FPS%" == "%A_FPS%" goto FPS_DONE
echo.[INFO] Обнаружен FPS VFR. Извлекаем max frame rate из mediainfo>>"%LOG%"

:: Получаем Max FPS из MediaInfo
set "FPS="
set "MAX_FPS="
"%MI%" --Inform="Video;%%FrameRate_Maximum%%" "%FNF%" > "%TMP_FILE%" 2>nul
if not exist "%TMP_FILE%" (
    echo.[WARNING] Не удалось получить FPS - файл не создан>>"%LOG%"
    goto FPS_DONE
)
set /p MAX_FPS= < "%TMP_FILE%"
del "%TMP_FILE%"
if not defined MAX_FPS (
    echo.[WARNING] Не удалось извлечь max frame rate из mediainfo>>"%LOG%"
    goto FPS_DONE
)

echo.[INFO] Извлечен max frame rate: %MAX_FPS%>>"%LOG%"

:: Оставляем только целые значения FPS
for /f "tokens=1 delims=." %%m in ("%MAX_FPS%") do set "MAX_FPS=%%m"

:: Принудительно устанавливаем ближайший FPS CFR
set "FPS=25"
if %MAX_FPS% GTR 25 set "FPS=30"
:: 35 - специально для файлов с VFR ~31.4 fps
if %MAX_FPS% GTR 35 set "FPS=50"
if %MAX_FPS% GTR 50 set "FPS=60"
echo.[INFO] По диапазонам установлен FPS CFR: %FPS%>>"%LOG%"
:FPS_DONE






:: === Блок: PROFILE ===
:: Профиль кодирования (profile:v)
set "USE_PROFILE=main"
if /i "%CODEC%" == "hevc_qsv" goto PROFILE_DONE
if /i "%CODEC%" == "hevc_d3d12va" goto PROFILE_DONE
set "USE_PROFILE=high"
if /i "%CODEC:~0,5%" == "h264_" goto PROFILE_DONE
if /i "%CODEC%" == "libx264" goto PROFILE_DONE
set "USE_PROFILE=main10"
if /i "%PROFILE%" == "main" set "USE_PROFILE=main"
:PROFILE_DONE
echo.[INFO] Установлен профиль кодирования: %USE_PROFILE%>>"%LOG%"





:: === Блок: PIX_FMT_ARGS ===
set "PIX_FMT_ARGS=-pix_fmt p010le"

:: Если не main10 - сразу устанавливаем 8 бит
if /i not "%USE_PROFILE%" == "main10" goto SET_PIXFMT8

:: Проверяем, поддерживает ли текущий кодек main10
if /i "%CODEC%" == "libx264" goto NO_MAIN10
if /i "%CODEC:~0,5%" == "h264_" goto NO_MAIN10

:: Для libx265 используем yuv420p10le
if /i "%CODEC%" == "libx265" set "PIX_FMT_ARGS=-pix_fmt yuv420p10le"
goto DONE_PIXFMT

:NO_MAIN10
echo.[WARNING] Кодек %CODEC% не поддерживает профиль main10. Параметр проигнорирован.>>"%LOG%"

:SET_PIXFMT8
set "PIX_FMT_ARGS=-pix_fmt yuv420p"

:DONE_PIXFMT
echo.[INFO] Для кодека %CODEC% с профилем %USE_PROFILE% добавляем флаг: %PIX_FMT_ARGS%>>"%LOG%"







:: === Блок: CRF ===
set "FINAL_CRF="
if not defined CRF goto SKIP_CRF
if /i "%CODEC%" == "hevc_nvenc" set "FINAL_CRF=-cq %CRF%"
if /i "%CODEC%" == "hevc_amf"   set "FINAL_CRF=-quality %CRF%"
if /i "%CODEC%" == "hevc_qsv"   set "FINAL_CRF=-global_quality %CRF%"
if /i "%CODEC%" == "libx265"    set "FINAL_CRF=-crf %CRF%"
if /i "%CODEC%" == "h264_nvenc" set "FINAL_CRF=-cq %CRF%"
if /i "%CODEC%" == "h264_amf"   set "FINAL_CRF=-quality %CRF%"
if /i "%CODEC%" == "h264_qsv"   set "FINAL_CRF=-global_quality %CRF%"
if /i "%CODEC%" == "libx264"    set "FINAL_CRF=-crf %CRF%"
echo.[INFO] CRF установлен: %CRF%>>"%LOG%"
:SKIP_CRF






:: === Блок: VF ===
:: Этот блок должен быть после блоков ROTATION, SCALE
set "FILTER_LIST="
:: Сначала scale, чтобы уменьшить размер перед поворотом, если не пропущен
if not "%SKIP_SCALE_FILTER%" == "1" if defined SCALE_EXPR set "FILTER_LIST=%FILTER_LIST%%SCALE_EXPR%,"

:: Затем rotate
if defined ROTATION_FILTER set "FILTER_LIST=%FILTER_LIST%%ROTATION_FILTER%,"

:: FPS
if defined FPS set "FILTER_LIST=%FILTER_LIST%fps=%FPS%,"

:: Удаляем завершающую запятую
if defined FILTER_LIST if "%FILTER_LIST:~-1%" == "," set "FILTER_LIST=%FILTER_LIST:~0,-1%"

:: Формируем флаг -vf
set "VF="
if defined FILTER_LIST set "VF=-vf "%FILTER_LIST%""

:: Логируем результат. Внимание - в -vf есть кавычки !
if defined VF echo.[INFO] Видеофильтр: %VF%>>"%LOG%"





:: === Блок: FINALKEYS ===
:: Порядок ключей должен быть такой, особенно для аппаратных кодеков:
:: -hide_banner -c:v codec [-profile:v] [-preset] [-vf] [-pix_fmt] [-crf] [-tune] [-level] [-r FPS] [-metadata rotate] -c:a -c:s [-metadata lng]
set "FINAL_KEYS=-hide_banner"

:: Кодек и профиль
set "FINAL_KEYS=%FINAL_KEYS% -c:v %CODEC% -profile:v %USE_PROFILE%"

:: Preset и quality
if not defined PRESET goto SKIP_PRESET
if /i "%CODEC%" == "hevc_nvenc" set "FINAL_KEYS=%FINAL_KEYS% -preset %PRESET%"
if /i "%CODEC%" == "h264_nvenc" set "FINAL_KEYS=%FINAL_KEYS% -preset %PRESET%"
if /i "%CODEC%" == "hevc_amf"   set "FINAL_KEYS=%FINAL_KEYS% -quality %PRESET%"
if /i "%CODEC%" == "h264_amf"   set "FINAL_KEYS=%FINAL_KEYS% -quality %PRESET%"
if /i "%CODEC%" == "hevc_qsv"   set "FINAL_KEYS=%FINAL_KEYS% -preset %PRESET%"
if /i "%CODEC%" == "h264_qsv"   set "FINAL_KEYS=%FINAL_KEYS% -preset %PRESET%"
echo.[INFO] Установлен preset %PRESET%>>"%LOG%"
:SKIP_PRESET

:: Видеофильтр -vf
if defined VF set "FINAL_KEYS=%FINAL_KEYS% %VF%"

:: Формат пикселей (8 bit yuv420p или 10 bit yuv420p10le)
if defined PIX_FMT_ARGS set "FINAL_KEYS=%FINAL_KEYS% %PIX_FMT_ARGS%"

:: CRF/CQ
if defined FINAL_CRF set "FINAL_KEYS=%FINAL_KEYS% %FINAL_CRF%"

:: Tune и Level
if /i "%CODEC%" == "libx264" set "FINAL_KEYS=%FINAL_KEYS% -tune film"
if /i "%CODEC:~0,5%" == "h264_" set "FINAL_KEYS=%FINAL_KEYS% -level 4.0"

:: FPS
rem if defined FPS set "FINAL_KEYS=%FINAL_KEYS% -r %FPS%"

:: Metadata (тег Rotate если не поворачиваем видео из-за неподдерживаемого аппаратного кодека)
if defined ROTATION_METADATA set "FINAL_KEYS=%FINAL_KEYS% %ROTATION_METADATA%"

:: Аудио и субтитры
set "FINAL_KEYS=%FINAL_KEYS% %AUDIO_ARGS% -c:s copy"

:: Меняем язык дорожек на русский кроме видео (для MKV - добавит позже mkvpropedit)
set "FINAL_KEYS=%FINAL_KEYS% -metadata language=rus -metadata:s:a:0 language=rus -metadata:s:s:0 language=rus"






:: === Блок: FFMPEG ===
set "CMD_LINE="%FFM%" -i "%FNF%" %FINAL_KEYS% "%OUTPUT%""
echo.[CMD] Строка кодирования: %CMD_LINE%>>"%LOG%"
%CMD_LINE% 2>"%FFMPEG_LOG%"

:: Если full-range добавляем metadata через mkvpropedit
if not defined COLOR_RANGE goto SKIPMKVPROP
echo.[INFO] Full color range: добавляем в MKV дополнительные теги c помощью mkvpropedit>>"%LOG%"
echo.[INFO] В MKV меняем язык видеодорожки на русский>>"%LOG%"
:: Заодним ставим языки дорожек - Русский
"%MKVP%" "%OUTPUT%" --edit track:v1 --set "language=rus" --set "colour-range=1" --set "color-matrix-coefficients=1">nul
goto DONEMKVPROP
:SKIPMKVPROP
:: Если OUTPUT_EXT=mkv - ставим языки дорожек - Русский
if not "%OUTPUT_EXT%" == "mkv" goto DONEMKVPROP
echo.[INFO] В MKV меняем язык видеодорожки на русский>>"%LOG%"
"%MKVP%" "%OUTPUT%" --edit track:v1 --set "language=rus">nul
:DONEMKVPROP





:: Временно конвертируем UTF8-лог FFmpeg в OEM для поиска ошибок через findstr
set "VT=%temp%\tmp.vbs"
pushd "%OUTPUT_DIR%logs"
set "TMPFLUTF=$flogutf"
set "TMPFLOEM=$flogoem"
if exist "%TMPFLUTF%" del "%TMPFLUTF%"
if exist "%TMPFLOEM%" del "%TMPFLOEM%"
copy "%FFMPEG_LOG_NAME%" "%TMPFLUTF%">nul
echo.With CreateObject("ADODB.Stream"^)>"%VT%"
echo..Type=2:.Charset="UTF-8":.Open:.LoadFromFile "%TMPFLUTF%">>"%VT%"
echo.s=.ReadText:.Close>>"%VT%"
echo..Type=2:.Charset="cp866":.Open:.WriteText s>>"%VT%"
echo..SaveToFile "%TMPFLOEM%",2:.Close>>"%VT%"
echo.End With>>"%VT%"
cscript //nologo "%VT%"
del "%TMPFLUTF%"
findstr /i "error failed" "%TMPFLOEM%">nul
if %ERRORLEVEL% EQU 0 (
    echo.FFmpeg завершился с ошибкой - см. "%FFMPEG_LOG_NAME%"
    echo.[ERROR] FFmpeg завершился с ошибкой - см. "%FFMPEG_LOG_NAME%">>"%LOG%"
)
del "%TMPFLOEM%"
popd
del "%VT%"

:: Завершили обработку файла
echo.%DATE% %TIME:~0,8% Обработка %FNWE% завершена.
echo.Создан "%OUTPUT_NAME%.%OUTPUT_EXT%".
echo.Cм. логи в папке "%OUTPUT_DIR%logs".
echo.---
echo.[INFO] %DATE% %TIME:~0,8% Создан %OUTPUT_NAME%.%OUTPUT_EXT%>>"%LOG%"

:: Конвертируем OEM-лог в UTF-8:
:: %LOGE% - входной OEM-лог, %LOGU% - выходной UTF-8-лог. Должно быть без кириллицы в путях.
:: Переходим в папку Logs
set "VT=%temp%\tmp.vbs"
pushd "%OUTPUT_DIR%logs"
echo.With CreateObject("ADODB.Stream"^)>"%VT%"
echo..Type=2:.Charset="cp866":.Open:.LoadFromFile "%LOGE%">>"%VT%"
echo.s=.ReadText:.Close>>"%VT%"
echo..Type=2:.Charset="UTF-8":.Open:.WriteText s>>"%VT%"
echo..SaveToFile "%LOGU%",2:.Close>>"%VT%"
echo.End With>>"%VT%"
cscript //nologo "%VT%"
del "%LOGE%"
if exist "%LOGN%" del "%LOGN%"
ren "%LOGU%" "%LOGN%"
popd
del "%VT%"

:: Переход к следующему файлу
:NEXT
shift
goto FILE_LOOP

:: Завершение работы скрипта
:FILE_LOOP_END
echo.Все файлы обработаны.
set ev="%temp%\$%~n0$.vbs"
set emsg="Пакетный файл '%~nx0' закончил работу."
chcp 1251 >nul
echo MsgBox %emsg%,,"%~nx0">%ev%
chcp 866 >nul
%ev% & del %ev%
pause
exit