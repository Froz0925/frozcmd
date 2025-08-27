@echo off
set "DO=Video recode script"
set "VRS=Froz %DO% v27.08.2025"
:: Цель скрипта: перекодирование видеофайлов с телефонов/фотоаппаратов
:: в уменьшенный размер для видеоархива без существенной потери качества.


:: === Блок: Настройки ===

:: Высота кадра (опц.). Пример: 720. Но 1080->720 слабо влияет на размер файла
set "SCALE="

:: Поворот: 90 (по чс), 180, 270 (90 против чс). Если пусто - возьмёт из тега.
:: *qsv и *d3d12va - не поддерживают поворот! *amf - может глючить.
set "ROTATION="

:: Энкодер:
:: HEVC (H.265):
::    hevc_nvenc   - NVIDIA GPU - рекомендуемый. Требуется GeForce GTX 950 и выше + драйвер 570+
::    hevc_amf     - AMD GPU
::    hevc_qsv     - Intel Quick Sync Video
::    hevc_d3d12va - Windows Direct 12 (DXVA2), аппаратная поддержка
::    libx265      - software кодирование HEVC (очень медленно - CPU)
:: H.264: h264_nvenc (рекомендуемый), h264_amf, h264_qsv, libx264 (медленный - CPU)
set "CODEC=hevc_nvenc"

:: Пресет для кодека hevc_nvenc. Значения: p1 -> p7 (скорость -> качество).
:: По умолчанию hevc_nvenc выбирает p4 (~CRF20, на 720p ~2,5 Мбит/с)
set "PRESET="

:: Профиль кодирования: только для HEVC: main10 (10 bit) или main (8 bit).
:: H.264 - всегда будет применён high, независимо от указанного здесь.
:: Если не задано - выбирает кодек.
:: Поддержка main10 кодеками HEVC: nvenc, amf, libx265. Может не работать на старых устройствах!
set "PROFILE=main10"

:: CRF: уровень качества (рек. 20-24). Если не задан - кодек выбирает сам.
:: Для libx265/264: лучше указать CRF20, иначе будет CRF28 (низкое качество).
:: hevc_nvenc по умолчанию выбирает ~CRF20. Это ~2.5 Мбит/с для 720p.
set "CRF="

:: Аудио: -c:a copy (по умолчанию). Для уменьшения размера: -c:a libopus -b:a 128k
:: Раскомментируйте нужный вариант, а другой закомментируйте через ::
set "AUDIO_ARGS=-c:a copy"
::set "AUDIO_ARGS=-c:a libopus -b:a 128k"

:: 1 - принудительно full range, если видео Full Range JPEG, но не YUVJ420P. Крайне редко.
set "FORCE_FULL_RANGE="

:: FPS - установка целевой частоты кадров (необязательно)
:: Примеры: 24, 25, 30, 50, 60, 24000/1001 (~23.976), 30000/1001 (~29.97) и т.п.
:: Если не задано - частота кадров берётся из исходника (FPS CFR или VFR).
:: Пример: set "FPS=30000/1001"


:: Целевая частота кадров (опц.). Если пусто - берётся из исходника.
:: Пример: 24, 25, 30, 50, 60, 24000/1001 (~23.976), 30000/1001 (~29.97)
set "FPS="

:: Контейнер: mkv (универсальнее) или mp4. Для аппаратных кодеков H.264 - лучше mp4.
set "OUTPUT_EXT=mkv"

:: Суффикс к имени файла на выходе
set "NAME_APPEND=_sm"

:: Оценка времени кодирования для вашего GPU/CPU.
:: Как рассчитать: (секунд_кодирования / секунд_видео) x 100. Пример: 0.3 -> ставим 30.
:: Помогает скрипту более точно показать примерное время.
:: Старые значения для сравнения: GTX 1050 и i3-2120: SPEED_NVENC=30, SPEED_LIBX265=500
set "SPEED_NVENC=10"
set "SPEED_AMF=20"
set "SPEED_QSV=20"
set "SPEED_LIBX264=50"
set "SPEED_LIBX265=100"
:: === Окончание блока настроек ===





:: === Блок: Проверки ===
title %DO%
echo(%VRS%
echo(
set "CMDN=%~n0"
:: Проверка наличия входных файлов
if "%~1" == "" (
    echo(Использование: Проверьте блок установок SET в начале скрипта.
    echo(
    echo(Затем перетяните или вставьте видеофайлы на этот файл.
    echo(
    pause
    exit /b
)
:: Проверка наличия утилит
set "FFM=%~dp0bin\ffmpeg.exe"
set "FFP=%~dp0bin\ffprobe.exe"
set "MI=%~dp0bin\mediainfo.exe"
set "MKVP=%~dp0bin\mkvpropedit.exe"
if not exist "%FFM%" echo("%FFM%" не найден, выходим.& echo(& pause & exit /b
if not exist "%FFP%" echo("%FFP%" не найден, выходим.& echo(& pause & exit /b
if not exist "%MI%" echo("%MI%" не найден, выходим.& echo(& pause & exit /b
if not exist "%MKVP%" echo"(%MKVP%" не найден, выходим.& echo(& pause & exit /b





:: === Блок: Старт ===
:FILE_LOOP
:: Записываем имя файла в переменные чтобы %1 не сломалось в процессе
set "FNF=%~1"
set "FNN=%~n1"
set "FNWE=%~nx1"
set "EXT=%~x1"

:: Если больше нет файлов - выходим
if "%FNF%" == "" goto FILE_LOOP_END

:: Временное имя OEM-лога - используем дату, а не %random%
set "TH=%time:~0,2%"
if "%TH:~0,1%"==" " set "TH=0%TH:~1,1%"
set "TYMDHMS=%date:~6,4%-%date:~3,2%-%date:~0,2%_%TH%-%time:~3,2%-%time:~6,2%"

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
echo("%OUTPUT_NAME%" уже существует, пропускаем.
echo(
goto NEXT
:DONE_SIZE_CHK
title Обработка %FNWE%...
echo(%DATE% %TIME:~0,8% Начата обработка "%FNWE%"...
echo(
>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Начата обработка "%FNWE%"...








:: === Блок: ВРЕМЯ ===
:: Получаем длительность видео. Ключ :nk=1 отбросит текст "duration="
set "TMP_FILE=%TEMP%\ffprobe_time_%random%%random%.tmp"
"%FFP%" -v error -show_entries format=duration -of default=nw=1:nk=1 "%FNF%" >"%TMP_FILE%"
set /p LENGTH_SECONDS= <"%TMP_FILE%"
del "%TMP_FILE%"
if not defined LENGTH_SECONDS (
    >>"%LOG%" echo([ERROR] %DATE% %TIME:~0,8% Не удалось извлечь длительность видео
    goto DONE_LENGTH
)

:: Оставляем только целые секунды
for /f "tokens=1 delims=." %%a in ("%LENGTH_SECONDS%") do set "LENGTH_SECONDS=%%a"

:: Добавляем +1, чтобы округлить вверх
set /a LENGTH_SECONDS+=1

:: Определяем коэффициент x100 по кодеку
set "SPEED_CENTI="
if /i "%CODEC:~-5%" == "nvenc" set "SPEED_CENTI=%SPEED_NVENC%"
if /i "%CODEC:~-3%" == "amf"   set "SPEED_CENTI=%SPEED_AMF%"
if /i "%CODEC:~-3%" == "qsv"   set "SPEED_CENTI=%SPEED_QSV%"
if /i "%CODEC%" == "libx264"   set "SPEED_CENTI=%SPEED_LIBX264%"
if /i "%CODEC%" == "libx265"   set "SPEED_CENTI=%SPEED_LIBX265%"

:: Fallback, если кодек не распознан
if not defined SPEED_CENTI (
    >>"%LOG%" echo([WARNING] %DATE% %TIME:~0,8% Неизвестный кодек: %CODEC%.
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Для расчёта времени кодирования берем скорость 50
    set "SPEED_CENTI=50"
)

:: Рассчитываем примерное время кодирования
set /a ENCODE_SECONDS = (LENGTH_SECONDS * SPEED_CENTI) / 100

:: Минимум 1 секунда
if %ENCODE_SECONDS% LSS 1 set "ENCODE_SECONDS=1"

:: Переводим в минуты:секунды
set /a "MINUTES=ENCODE_SECONDS / 60"
set /a "SECONDS=ENCODE_SECONDS %% 60"
if %SECONDS% LSS 10 set "SECONDS=0%SECONDS%"

echo(Примерное время кодирования: %MINUTES% минут %SECONDS% секунд.
echo(
:DONE_LENGTH





:: === Блок: COLOR RANGE ===
set "PIX_FMT="
:: Если задан Force full range
set "COLOR_RANGE="
if defined FORCE_FULL_RANGE (
    set "COLOR_RANGE=1"
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Задан Force color range
    goto COLOR_RANGE_DONE
)
:: Определение full range через ffprobe. Ключ :nk=1 отбросит текст "pix_fmt="
set "TMP_FILE=%TEMP%\ffprobe_pix_fmt_%random%%random%.tmp"
"%FFP%" -v error -select_streams v:0 -show_entries stream=pix_fmt -of default=nw=1:nk=1 "%FNF%" >"%TMP_FILE%"
if not exist "%TMP_FILE%" (
    >>"%LOG%" echo([ERROR] %DATE% %TIME:~0,8% Не получилось создать временный файл "%TMP_FILE%"
    goto COLOR_RANGE_DONE
)
set /p PIX_FMT= <"%TMP_FILE%"
del "%TMP_FILE%"
if not defined PIX_FMT (
    >>"%LOG%" echo([ERROR] %DATE% %TIME:~0,8% FFProbe не смог определить формат пикселей
    goto COLOR_RANGE_DONE
)
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Формат пикселей исходника: %PIX_FMT%
for /f "tokens=1" %%a in ("%PIX_FMT%") do set "PIX_FMT=%%a"
:: Автоопределение full range по pix_fmt
if /i "%PIX_FMT%" == "yuvj420p" (
    set "COLOR_RANGE=1"
)

:: Если OUTPUT_EXT = mp4 - меняем на mkv
if not "%OUTPUT_EXT%" == "mp4" goto COLOR_RANGE_DONE
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Для записи metadata full color с помощью mkvpropedit - меняем расширение на mkv
set "OUTPUT_EXT=mkv"
set "OUTPUT=%OUTPUT_DIR%%OUTPUT_NAME%.%OUTPUT_EXT%"
:COLOR_RANGE_DONE






:: === Блок: CURRENT SIZE ===
:: Получаем исходные размеры видео для поворота и масштабирования через ffprobe
:: Используем временный файл, так как этот вывод ffprobe может содержать:
::     - пробелы (например, "1920 1080")
::     - специальные символы (например, escape-символы, двоеточия)
::     - пустые строки или ошибки
:: которые могут сломать for /f
set "CURRENT_DIM="
set "TMP_FILE=%TEMP%\video_info_%random%%random%.tmp"
"%FFP%" -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "%FNF%" >"%TMP_FILE%"
if not exist "%TMP_FILE%" goto SKIP_CURRENT_DIM
:: Извлекаем первую непустую строку (goto 'выход' нужен для прерывания цикла)
for /f "tokens=1,2 delims=," %%a in ('type "%TMP_FILE%"') do (
    set "CURRENT_W=%%a"
    set "CURRENT_H=%%b"
)
del "%TMP_FILE%"
if not defined CURRENT_W (
    >>"%LOG%" echo([ERROR] %DATE% %TIME:~0,8% FFProbe не смог определить ширину/высоту
    goto SKIP_CURRENT_DIM
)
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Разрешение исходника: %CURRENT_W%x%CURRENT_H%
:SKIP_CURRENT_DIM





:: === Блок: ROTATION ===
:: Блок должен быть до блока SCALE
set "ROTATION_FILTER="
set "ROTATION_METADATA="

:: Если ROTATION не задан - пытаемся извлечь тег Rotate из файла
if not defined ROTATION goto NO_USER_ROTATION

:: Если задано значение отличное от 0 - используем его
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Задан USER ROTATION=%ROTATION%
goto APPLY_ROTATION

:NO_USER_ROTATION
if /i "%EXT%" == ".mp4" goto GET_ROTATE
if /i "%EXT%" == ".mov" goto GET_ROTATE
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Формат %EXT% не поддерживает тег Rotate - извлечение пропущено.
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Если видео повёрнуто - принудительно задайте set ROTATION.
goto NO_ROTATION_TAG

:GET_ROTATE
set "ROTATION_TAG="
set "TMP_FILE=%TEMP%\ffprobe_rotation_%random%%random%.tmp"
"%FFP%" -v error -show_entries stream_tags=rotate -of default=nw=1:nk=1 "%FNF%" >"%TMP_FILE%"
if not exist "%TMP_FILE%" goto NO_ROTATION_TAG
set /p ROTATION_TAG= < "%TMP_FILE%"
del "%TMP_FILE%"
if not defined ROTATION_TAG goto NO_ROTATION_TAG

:: Удаляем пробелы
set "ROTATION_TAG=%ROTATION_TAG: =%"
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% В metadata найден тег Rotate: "%ROTATION_TAG%"

:: Устанавливаем ROTATION только если она ещё не задана
set "ROTATION=%ROTATION_TAG%"

:: Проверяем, поддерживает ли кодек поворот
:APPLY_ROTATION
set "SUPPORTS_TRANSPOSE=1"
if /i "%CODEC%" == "hevc_qsv"     set "SUPPORTS_TRANSPOSE="
if /i "%CODEC%" == "hevc_d3d12va" set "SUPPORTS_TRANSPOSE="
if /i "%CODEC%" == "h264_qsv"     set "SUPPORTS_TRANSPOSE="
if /i "%CODEC%" == "h264_d3d12va" set "SUPPORTS_TRANSPOSE="
if not defined SUPPORTS_TRANSPOSE goto SAVE_ROTATION_METADATA

:SET_TRANSPOSE
:: Формируем фильтр поворота
if "%ROTATION%" == "90" (
    set "ROTATION_FILTER=transpose=1"
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Применён поворот на 90 градусов по часовой стрелке
    goto ROTATION_DONE
)
:: transpose=2 - поворот на 90 против часовой, но нам нужно 180.
:: Поэтому применяем дважды: 90 + 90 = 180.
if "%ROTATION%" == "180" (
    set "ROTATION_FILTER=transpose=2,transpose=2"
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Применён поворот на 180 градусов
    goto ROTATION_DONE
)
if "%ROTATION%" == "270" (
    set "ROTATION_FILTER=transpose=2"
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Применён поворот на 90 градусов против часовой стрелки
    goto ROTATION_DONE
)

:: Сюда попадаем, если поворот напрямую невозможен, но можно сохранить как metadata
:SAVE_ROTATION_METADATA

:: === Коллизия: full range vs rotate ===
:: Невозможно одновременно:
::   - colour-range=1 (требует MKV)
::   - тег rotate (требует MP4)
::   - и кодек без transpose (qsv/d3d12va)
:: Решение: colour-range важнее. Пропускаем файл.
if defined COLOR_RANGE (
    echo([ERROR] Конфликт: colour-range и rotate для %CODEC% - невозможны вместе.
    echo(colour-range важнее. Поверните видео до кодирования или смените кодек.
    echo(
    >>"%LOG%" echo([ERROR] %DATE% %TIME:~0,8% Конфликт: colour-range и rotate. Смените кодек.
    goto NEXT
)

:: Если OUTPUT_EXT = mkv - меняем на mp4
if not "%OUTPUT_EXT%" == "mkv" goto ROT_EXT_OK
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Меняем расширение на mp4 для записи тега Rotate
set "OUTPUT_EXT=mp4"
set "OUTPUT=%OUTPUT_DIR%%OUTPUT_NAME%.%OUTPUT_EXT%"
:ROT_EXT_OK

:: Сохраняем как metadata
set "ROTATION_METADATA=-metadata:s:v:0 rotate=%ROTATION%"
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Так как поворот кодеком невозможен - тег поворота будет сохранён в файле MP4
goto ROTATION_DONE

:: Сюда попадаем, если поворот не определён или некорректен
:NO_ROTATION_TAG
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% В metadata не найден тег rotate или он некорректен.
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% При необходимости задайте set ROTATION принудительно

:ROTATION_DONE







:: === Блок: SCALE (должен быть после ROTATION) ===
:: Обработка масштабирования с учётом Rotation
set "SCALE_EXPR="
:: Если SET SCALE не задан - пропускаем формирование scale_expr
if not defined SCALE (
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Высота не задана, масштабирование отключено
    goto SKIP_SCALE
)
set "TARGET_H=%SCALE%"
:: Учитываем поворот: при 90/270 меняем ось масштабирования
if "%ROTATION%"=="90" (
    set "SCALE_EXPR=scale=%SCALE%:-2"
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Задан поворот на 90 градусов по часовой стрелке - масштабируем по ширине
    goto SKIP_SCALE
)
if "%ROTATION%"=="270" (
    set "SCALE_EXPR=scale=%SCALE%:-2"
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Задан поворот на 90 градусов против часовой стрелки - масштабируем по ширине
    goto SKIP_SCALE
)
:: По умолчанию масштабируем по высоте
set "SCALE_EXPR=scale=-2:%SCALE%"
:SKIP_SCALE






:: === Блок: SKIP_SCALE_FILTER ===
:: Проверяем, нужно ли вообще применять scale:
:: - совпадает ли высота с целевой,
:: - нет ли принудительного поворота,
:: - нет ли metadata поворота.
:: Если всё совпадает - пропускаем scale в -vf, чтобы избежать бесполезной перекодировки.
set "SRC_H="
set "SKIP_SCALE_FILTER="
:: Если SCALE не задан - пропускаем проверку
if not defined SCALE goto SKIP_HEIGHT_CHECK

:: Получаем исходную высоту через ffprobe, ключ :nk=1 отбросит текст "height="
set "TMP_FILE=%TEMP%\ffprobe_height_%random%%random%.tmp"
"%FFP%" -v error -show_entries stream^=height -of default=nw=1:nk=1 "%FNF%" >"%TMP_FILE%"
if not exist "%TMP_FILE%" (
    >>"%LOG%" echo([WARNING] %DATE% %TIME:~0,8% Не удалось получить высоту видео из файла
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
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Видео будет масштабировано. Исходная высота: %SRC_H%, целевая: %SCALE%
goto SKIP_HEIGHT_CHECK

:HANDLE_SKIP_SCALE
:: Высота совпадает, проверяем необходимость поворота
if defined FORCE_ROTATE goto SKIP_HEIGHT_CHECK
if defined ROTATION_METADATA goto SKIP_HEIGHT_CHECK

:: Ни поворота, ни метаданных нет - можно пропустить scale
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Высота %SCALE% уже соответствует файлу. Масштабирование пропущено
set "SKIP_SCALE_FILTER=1"
:SKIP_HEIGHT_CHECK





:: === Блок FPS ===
:: Цель: привести VFR (variable frame rate) к CFR (constant), чтобы:
:: - избежать проблем с аппаратными кодеками (некоторые их не любят),
:: - уменьшить размер файла (VFR может быть "тяжёлым"),
:: - улучшить совместимость с проигрывателями и TV.
if defined FPS (
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% FPS задан принудительно: %FPS%, пропускаем его извлечение
    goto FPS_DONE
)
:: Получение частоты кадров через ffprobe
set "TMP_FILE=%TEMP%\ffprobe_fps_%random%%random%.tmp"
"%FFP%" -v error -select_streams v:0 -show_entries stream=r_frame_rate,avg_frame_rate -of default=nw=1 "%FNF%" >"%TMP_FILE%"
if not exist "%TMP_FILE%" (
    >>"%LOG%" echo([WARNING] %DATE% %TIME:~0,8% Не удалось получить FPS - файл не создан
    goto FPS_DONE
)
:: Извлечение r_frame_rate
for /f "tokens=2 delims==" %%a in ('find "r_frame_rate" "%TMP_FILE%"') do set "R_FPS=%%a"
:: Извлечение avg_frame_rate
for /f "tokens=2 delims==" %%a in ('find "avg_frame_rate" "%TMP_FILE%"') do set "A_FPS=%%a"
del "%TMP_FILE%"
if not defined R_FPS (
    >>"%LOG%" echo([WARNING] %DATE% %TIME:~0,8% Не удалось найти r_frame_rate
    goto FPS_DONE
)
if not defined A_FPS (
    >>"%LOG%" echo([WARNING] %DATE% %TIME:~0,8% Не удалось найти avg_frame_rate
    goto FPS_DONE
)

:: Сравниваем значения как строки
if "%R_FPS%" == "%A_FPS%" goto FPS_DONE
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Обнаружен FPS VFR. Извлекаем max frame rate из mediainfo

:: Получаем Max FPS из MediaInfo
set "FPS="
set "MAX_FPS="
"%MI%" --Inform="Video;%%FrameRate_Maximum%%" "%FNF%" > "%TMP_FILE%"
if not exist "%TMP_FILE%" (
    >>"%LOG%" echo([WARNING] %DATE% %TIME:~0,8% Не удалось получить FPS - файл не создан
    goto FPS_DONE
)
set /p MAX_FPS= < "%TMP_FILE%"
del "%TMP_FILE%"
if not defined MAX_FPS (
    >>"%LOG%" echo([WARNING] %DATE% %TIME:~0,8% Не удалось извлечь max frame rate из mediainfo
    goto FPS_DONE
)

>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Извлечен max frame rate: %MAX_FPS%

:: Оставляем только целые значения FPS
for /f "tokens=1 delims=." %%m in ("%MAX_FPS%") do set "MAX_FPS=%%m"

:: Принудительно устанавливаем ближайший FPS CFR
set "FPS=25"
if %MAX_FPS% GTR 25 set "FPS=30"
:: 35 - специально для файлов с VFR ~31.4 fps
if %MAX_FPS% GTR 35 set "FPS=50"
if %MAX_FPS% GTR 50 set "FPS=60"
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% По диапазонам установлен FPS CFR: %FPS%
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
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Установлен профиль кодирования: %USE_PROFILE%





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
>>"%LOG%" echo([WARNING] %DATE% %TIME:~0,8% Кодек %CODEC% не поддерживает профиль main10. Параметр проигнорирован

:SET_PIXFMT8
set "PIX_FMT_ARGS=-pix_fmt yuv420p"

:DONE_PIXFMT
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Для кодека %CODEC% с профилем %USE_PROFILE% добавляем флаг: %PIX_FMT_ARGS%







:: === Блок: CRF ===
set "FINAL_CRF="
if not defined CRF goto SKIP_CRF
if /i "%CODEC:~-5%" == "nvenc" set "FINAL_CRF=-cq %CRF%"
if /i "%CODEC:~-3%" == "amf"   set "FINAL_CRF=-quality %CRF%"
if /i "%CODEC:~-3%" == "qsv"   set "FINAL_CRF=-global_quality %CRF%"
if /i "%CODEC%" == "libx265"   set "FINAL_CRF=-crf %CRF%"
if /i "%CODEC%" == "libx264"   set "FINAL_CRF=-crf %CRF%"
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% CRF установлен: %CRF%
:SKIP_CRF






:: === Блок: VF ===
:: Этот блок должен быть после блоков ROTATION, SCALE
:: Формируем цепочку видеофильтров.
:: Порядок важен:
:: 1. scale - уменьшаем до нужного размера
:: 2. transpose - поворачиваем (уже на меньшем видео - быстрее)
:: 3. fps - фиксируем частоту кадров
:: Поэтому этот блок - после ROTATION, SCALE и FPS.

set "FILTER_LIST="
:: Сначала scale, чтобы уменьшить размер перед поворотом, если не пропущен
if not "%SKIP_SCALE_FILTER%" == "1" if defined SCALE_EXPR set "FILTER_LIST=%FILTER_LIST%%SCALE_EXPR%,"

:: Затем rotate
if defined ROTATION_FILTER set "FILTER_LIST=%FILTER_LIST%%ROTATION_FILTER%,"

:: FPS
if defined FPS set "FILTER_LIST=%FILTER_LIST%fps=%FPS%,"

:: Удаляем завершающую запятую
if not defined FILTER_LIST goto :SKIP_COMMA_REMOVAL
set "LAST_CHAR=%FILTER_LIST:~-1%"
if not "%LAST_CHAR%" == "," goto :SKIP_COMMA_REMOVAL
set "FILTER_LIST=%FILTER_LIST:~0,-1%"
:SKIP_COMMA_REMOVAL

:: Формируем флаг -vf
set "VF="
if defined FILTER_LIST set "VF=-vf "%FILTER_LIST%""

:: Логируем результат. Внимание - в -vf есть кавычки !
if defined VF >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Видеофильтр: %VF%






:: === Блок: FINALKEYS ===
:: Порядок ключей КРИТИЧЕН для аппаратных кодеков (qsv, nvenc, amf).
:: Некоторые драйверы игнорируют параметры, если они идут не в правильной последовательности.
:: Поэтому сначала: кодек, профиль, preset, потом vf, pix_fmt, crf и т.д.
:: Порядок ключей должен быть такой:
:: -hide_banner -c:v codec [-profile:v] [-preset] [-vf] [-pix_fmt] [-crf] [-tune] [-level]
::  [-r FPS] [-metadata rotate] -c:a -c:s [-metadata lng]
set "FINAL_KEYS=-hide_banner"

:: Кодек и профиль
set "FINAL_KEYS=%FINAL_KEYS% -c:v %CODEC% -profile:v %USE_PROFILE%"

:: Preset и quality
if not defined PRESET goto SKIP_PRESET
if /i "%CODEC:~-5%" == "nvenc" set "FINAL_KEYS=%FINAL_KEYS% -preset %PRESET%"
if /i "%CODEC:~-3%" == "amf"   set "FINAL_KEYS=%FINAL_KEYS% -quality %PRESET%"
if /i "%CODEC:~-3%" == "qsv"   set "FINAL_KEYS=%FINAL_KEYS% -preset %PRESET%"
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Установлен preset %PRESET%
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
:: FPS устанавливается через -vf fps=%FPS%, поэтому -r не нужен
:: if defined FPS set "FINAL_KEYS=%FINAL_KEYS% -r %FPS%"

:: Metadata - Rotate если не поворачиваем видео из-за неподдерживаемого аппаратного кодека
if defined ROTATION_METADATA set "FINAL_KEYS=%FINAL_KEYS% %ROTATION_METADATA%"

:: Аудио и субтитры
set "FINAL_KEYS=%FINAL_KEYS% %AUDIO_ARGS% -c:s copy"

:: Устанавливаем язык аудио и субтитров в "rus". Язык видео - не трогаем: 
:: ffmpeg делает это криво в MKV, а в MP4 пусть остаётся und/eng.
:: Язык видео будет установлен позже через mkvpropedit.
:: Он же добавит метадату для full-range MKV - ffmpeg не умеет.
set "FINAL_KEYS=%FINAL_KEYS% -metadata language=rus -metadata:s:a:0 language=rus -metadata:s:s:0 language=rus"
:: Удаляем старые теги видео: ffmpeg копирует BPS, размер и длительность из исходника,
:: даже при перекодировке - они становятся неверными.
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:v BPS= -metadata:s:v BPS-eng= -metadata:s:v NUMBER_OF_BYTES= -metadata:s:v NUMBER_OF_BYTES-eng= -metadata:s:v DURATION-eng="
:: Удаляем теги аудио ТОЛЬКО при перекодировке: при -c:a copy они верные,
:: а при перекодировке ffmpeg не обновляет их - остаются ложные значения.
if "%AUDIO_ARGS%" == "-c:a copy" goto SKIP_CLEAN_AUDIO
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:a BPS= -metadata:s:a BPS-eng= -metadata:s:a NUMBER_OF_BYTES= -metadata:s:a NUMBER_OF_BYTES-eng= -metadata:s:a DURATION-eng="
:SKIP_CLEAN_AUDIO






:: === Блок: FFMPEG ===
set "CMD_LINE="%FFM%" -i "%FNF%" %FINAL_KEYS% "%OUTPUT%""
>>"%LOG%" echo([CMD] %DATE% %TIME:~0,8% Строка кодирования: %CMD_LINE%
:: В CMD_LINE уже есть кавычки - нельзя писать "%CMD_LINE%"
:: FFMPEG пишет лог в stderr, а не в stdout - поэтому 2>"%FFMPEG_LOG%"
%CMD_LINE% 2>"%FFMPEG_LOG%"

:: Здесь уже только MKV - даже если OUTEXT был MP4, выше мы его уже принудительно сменили.
:: Для Full-range добавляем цветовые метаданные + меняем язык на русский
:: Остальные дорожки (аудио, субтитры) уже получили language=rus через ffmpeg -metadata (см. выше)
if not defined COLOR_RANGE goto SKIPMKVPROP
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Full color range: добавляем в MKV дополнительные теги c помощью mkvpropedit
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% В MKV меняем язык видеодорожки на русский
"%MKVP%" "%OUTPUT%" --edit track:v1 --set "language=rus" --set "colour-range=1" --set "color-matrix-coefficients=1">nul
goto DONEMKVPROP
:SKIPMKVPROP
:: Если не full-range, но файл - MKV: только меняем язык видео
:: Остальное (аудио, субтитры) уже помечено как rus через ffmpeg
if not "%OUTPUT_EXT%" == "mkv" goto DONEMKVPROP
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% В MKV меняем язык видеодорожки на русский
"%MKVP%" "%OUTPUT%" --edit track:v1 --set "language=rus">nul
:DONEMKVPROP




:: === Блок: Конвертация логов ===
:: FFmpeg пишет лог в UTF-8, а cmd - в OEM (cp866). Поэтому:
:: 1. FFmpeg лог - отдельно, в UTF-8 (для просмотра в редакторах).
:: 2. Основной лог - в OEM, потом конвертируется в UTF-8 для просмотра.
:: Это позволяет искать ошибки в FFmpeg-логе - findstr работает только с OEM.

:: Временно конвертируем UTF8-лог FFmpeg в OEM для поиска ошибок через findstr
set "VT=%temp%\%CMDN%-utf2oem-%random%%random%.vbs"
pushd "%OUTPUT_DIR%logs"
set "TMPFLUTF=flogutf_%random%%random%"
set "TMPFLOEM=flogoem_%random%%random%"
if exist "%TMPFLUTF%" del "%TMPFLUTF%"
if exist "%TMPFLOEM%" del "%TMPFLOEM%"
copy "%FFMPEG_LOG_NAME%" "%TMPFLUTF%">nul
>"%VT%" echo(With CreateObject("ADODB.Stream"^)
>>"%VT%" echo(.Type=2:.Charset="UTF-8":.Open:.LoadFromFile "%TMPFLUTF%"
>>"%VT%" echo(s=.ReadText:.Close
>>"%VT%" echo(.Type=2:.Charset="cp866":.Open:.WriteText s
>>"%VT%" echo(.SaveToFile "%TMPFLOEM%",2:.Close
>>"%VT%" echo(End With
cscript //nologo "%VT%"
del "%TMPFLUTF%"
findstr /i "error failed" "%TMPFLOEM%">nul
if %ERRORLEVEL% EQU 0 (
    echo(FFmpeg завершился с ошибкой - см. "%FFMPEG_LOG_NAME%"
    echo(
    >>"%LOG%" echo([ERROR] %DATE% %TIME:~0,8% FFmpeg завершился с ошибкой - см. "%FFMPEG_LOG_NAME%"
)
del "%TMPFLOEM%"
popd
del "%VT%"

:: Завершили обработку файла
echo(%DATE% %TIME:~0,8% Обработка "%FNWE%" завершена.
echo(Создан "%OUTPUT_NAME%.%OUTPUT_EXT%".
echo(Cм. логи в папке "%OUTPUT_DIR%logs".
echo(---
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Создан "%OUTPUT_NAME%.%OUTPUT_EXT%"
>>"%LOG%" echo(---

:: Конвертируем OEM-лог в UTF-8:
:: %LOGE% - входной OEM-лог, %LOGU% - выходной UTF-8-лог.
:: Пути должны быть без кириллицы из-за разных кодировок CMD и VBS
:: Переходим в папку Logs
set "VT=%temp%\%CMDN%-oem2utf-%random%%random%.vbs"
pushd "%OUTPUT_DIR%logs"
>"%VT%" echo(With CreateObject("ADODB.Stream"^)
>>"%VT%" echo(.Type=2:.Charset="cp866":.Open:.LoadFromFile "%LOGE%"
>>"%VT%" echo(s=.ReadText:.Close
>>"%VT%" echo(.Type=2:.Charset="UTF-8":.Open:.WriteText s
>>"%VT%" echo(.SaveToFile "%LOGU%",2:.Close
>>"%VT%" echo(End With
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
echo(Все файлы обработаны.
echo(
set "EV=%temp%\%CMDN%-end-%random%%random%.vbs"
set "EMSG=Пакетный файл %CMDN% закончил работу."
chcp 1251 >nul
>"%EV%" echo(MsgBox "%EMSG%",,"%CMDN%"
chcp 866 >nul
cscript //nologo "%EV%"
del "%EV%"
pause
exit