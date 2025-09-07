@echo off
set "DO=Video recode script"
set "VRS=Froz %DO% v07.09.2025"
:: Перекодирование видеофайлов в уменьшенный размер с высокими настройками - для видеоархива


:: === Блок: ЮЗЕР ===
:: Высота кадра: 1 = уменьшить до 720, в том числе если после поворота высота > 720
:: Пусто - уменьшить до 1080 (стандартный FullHD монитор), в том числе если после поворота высота > 1080.
set "SCALE="

:: Уровень качества (меньше = лучше). Пусто - кодек выбирает сам (обычно выбирают среднее качество).
:: Если пусто - для nvenc включается multipass и целевой битрейт 2.5М для 720 и 4.5М для 1080.
:: Лучше устанавливать CRF принудительно: nvenc: 18-30, amf/qsv: 1-51 (режим cqp), libx264/5: 18-28.
:: Для hevc_nvenc при 30fps H720 CRF26 = 4,5 мбит, H1080 CRF32 = 4,5 мбит.
:: По умолчанию hevc_nvenc ставит: H720 ~CRF32 = 2,5 мбит, H1080 ~CRF38 = 2 мбит.
set "CRF="

:: Аудио: уменьшить размер: set "AUDIO_ARGS=-c:a libopus -b:a 128k"
:: Пусто или закомментировать (::) - аудио копируется без изменений
set "AUDIO_ARGS=-c:a libopus -b:a 128k"

:: Поворот: -90 = по часовой, 90 = против часовой. Если не задано - берётся из тега поворота (только MP4/MOV).
:: *qsv не поворачивает видео; *amf может работать с ошибками. При ручной установке тег из файла игнорируется.
set "ROTATION="

:: Видеокодек:
:: NVIDIA GPU: hevc_nvenc (рекомендуемый) и h264_nvenc.
::             Требуется GeForce GTX 950+ (Maxwell 2nd Gen GM20x) (2014+) и драйвер Nvidia v.570+.
:: AMD GPU:    hevc_amf и h264_amf - Radeon RX 400 / R9 300 серии и новее (2015+)
::             Требуется драйвер AMD Adrenalin Edition (не Microsoft)
:: Intel GPU:  hevc_qsv и h264_qsv - Intel Skylake+ (2015+), драйвер Intel HD + Media Feature Pack
:: CPU:        libx265 - очень медленно, libx264 - медленно
:: Примечание: HEVC - меньше размер, выше качество, H.264 - совместимость.
set "CODEC=hevc_nvenc"

:: Профиль кодирования для HEVC: main10 (10 bit) и main (8 bit). Для H.264 - всегда будет установлен high.
:: Если не задано - устанавливается main10 если поддерживается кодеком.
set "PROFILE=main10"

:: Частота кадров. Если пусто - берётся из исходника.
:: Плавающий FPS (VFR) преобразуется в стандартный ближайший по значению (CFR), округление вверх
:: Примеры: 24, 25, 30, 50, 60, 24000/1001 (~23.976), 30000/1001 (~29.97)
:: Для чересстрочного видео (MPEG2 50/60i) - игнорируется, деинтерлейсер преобразует в 50/60p.
set "FPS="

:: Контейнер: mkv - больше функций, mp4 - лучше для qsv/amf и проигрывателей.
set "OUTPUT_EXT=mkv"

:: Суффикс к имени: например _sm -> имя_sm.mkv
set "NAME_APPEND=_sm"

:: Параметр скорости кодирования от вашего GPU/CPU - помогает скрипту вычислить примерное время кодирования.
:: Расчёт опытным путём: (секунд кодирования / секунд видео) х 100. Пример: 0.3 -> ставим 30
set "SPEED_NVENC=7"
set "SPEED_AMF=20"
set "SPEED_QSV=20"
set "SPEED_LIBX264=50"
set "SPEED_LIBX265=100"





:: === Блок: ПРОВЕРКИ ===
title %DO%
echo(%VRS%
echo(
set "CMDN=%~n0"
:: Проверка наличия входных файлов
if "%~1" == "" (
    echo(Использование: Проверьте настройки в начале скрипта и при необходимости
    echo(отредактируйте в редакторе с поддержкой кодировки OEM,
    echo(например Блокнот с шрифтом Terminal, Notepad++, редакторы файловых менеджеров.
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
if not exist "%MKVP%" echo("%MKVP%" не найден, выходим.& echo(& pause & exit /b

:: Проверка: поддерживает ли GPU выбранный GPU-кодек
if /i "%CODEC:~0,5%" == "libx2" goto SKIP_GCHK
:: Конвертируем UTF-8 лог ffmpeg в OEM (cp866) для корректной работы findstr
:: ffmpeg пишет stderr в UTF-8, а findstr в cmd работает только с OEM
set "GLOG=%temp%\%CMDN%-gpuchk-%random%%random%"
set "GLOGOEM=%GLOG%-oem"
set "VT=%GLOG%.vbs"
>"%VT%" echo(With CreateObject("ADODB.Stream"^)
>>"%VT%" echo(.Type=2:.Charset="UTF-8":.Open:.LoadFromFile "%GLOG%"
>>"%VT%" echo(s=.ReadText:.Close
>>"%VT%" echo(.Type=2:.Charset="cp866":.Open:.WriteText s
>>"%VT%" echo(.SaveToFile "%GLOGOEM%",2:.Close
>>"%VT%" echo(End With
:: Создаём виртуальный пустой видеофайл длиной в 1 секунду и пытаемся сжать кодеком
"%FFM%" -hide_banner -v error -f lavfi -i nullsrc -c:v %CODEC% -t 1 -f null - 2>"%GLOG%"
cscript //nologo "%VT%"
:: Не отрывать строку findstr от if errorlevel
findstr /i "Error while opening encoder" "%GLOGOEM%" >nul
if %ERRORLEVEL% EQU 0 (
    echo(Ошибка: Видеокарта или её драйвер не поддерживает выбранный GPU-кодек.
    echo(Обновите видеокарту и/или драйвер, или смените кодек в настройках скрипта. Выходим.
    echo(
    pause
    exit /b
)
del "%GLOG%"
del "%GLOGOEM%"
del "%VT%"
:SKIP_GCHK

:: Глобальные set перед FILE_LOOP
set "OUTPUT_DIR=%~dp1"
:: Сохраняем исходные user-значения которые могут быть перезаписаны при работе
set "USER_ROTATION=%ROTATION%"
set "USER_OUTPUT_EXT=%OUTPUT_EXT%"
set "USER_FPS=%FPS%"





:: === Блок: СТАРТ ===
:FILE_LOOP
:: Восстанавливаем user-значения для нового файла
set "ROTATION=%USER_ROTATION%"
set "OUTPUT_EXT=%USER_OUTPUT_EXT%"
set "FPS=%USER_FPS%"
:: Записываем имя файла в переменные чтобы %1 не сломалось в процессе
set "FNF=%~1"
set "FNN=%~n1"
set "FNWE=%~nx1"
set "EXT=%~x1"
set "OUTPUT_NAME=%FNN%%NAME_APPEND%"
set "OUTPUT=%OUTPUT_DIR%%OUTPUT_NAME%.%OUTPUT_EXT%"

:: Если больше нет файлов - выходим
if "%FNF%" == "" goto FILE_LOOP_END

:: Временное имя OEM-лога для текущего видеофайла - используем дату, а не %random%.
:: Чтобы не зависеть от локали Windows берём текущую дату-время через VBS, 
:: а не через %date% %time%. Формат: ГГГГ-ММ-ДД_ЧЧММСС
set "TV=%temp%\%~n0-dtmp-%random%%random%.vbs"
>"%TV%" echo(s=Year(Now)^&"-"^&Right("0"^&Month(Now),2)^&"-"
>>"%TV%" echo(s=s^&Right("0"^&Day(Now),2)
>>"%TV%" echo(s=s^&"_"^&Right("0"^&Hour(Now),2)^&Right("0"^&Minute(Now),2)
>>"%TV%" echo(s=s^&Right("0"^&Second(Now),2):WScript.Echo s
for /f %%t in ('cscript //nologo "%TV%"') do set "DTMP=%%t"
del "%TV%"

:: Имена и папка логов
set "LOGE=%DTMP%oem"
set "LOG=%OUTPUT_DIR%logs\%LOGE%"
set "LOGU=%DTMP%utf"
set "LOGN=%FNN%%NAME_APPEND%-log.txt"
:: Совместить логи CMD+FFMpeg в один не получится, так как ffmpeg выводит в UTF8, а CMD - в OEM
set "FFMPEG_LOG_NAME=%OUTPUT_NAME%-log_ffmpeg.txt"
set "FFMPEG_LOG=%OUTPUT_DIR%logs\%FFMPEG_LOG_NAME%"

:: Создаём папку для логов
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





:: === Блок: ИЗВЛЕЧЕНИЕ ===
:: ffprobe извлекает: размеры кадра, формат пикселей, чересстрочность,
:: частоту кадров (базовая и средняя), поворот, длительность,
:: "мусорные" видеотеги для их удаления позже.
set "SRC_W="
set "SRC_H="
set "PIX_FMT="
set "FIELD_ORDER="
set "R_FPS="
set "A_FPS="
set "ROTATION_TAG="
set "HAS_VIDEO_TAGS="
set "LENGTH_SECONDS="
set "FFP_DATA=%temp%\ffprobe_data_%random%%random%.txt"
"%FFP%" -v error ^
    -select_streams v:0 ^
    -show_entries stream=width,height,pix_fmt,field_order,r_frame_rate,avg_frame_rate ^
    -show_entries stream_side_data=rotation ^
    -show_entries stream_tags=BPS ^
    -show_entries format=duration ^
    -of default=nw=1 ^
    "%FNF%" > "%FFP_DATA%"
:: Если найден видео-тег BPS - ставим флаг
for /f "tokens=1,2 delims==" %%a in ('type "%FFP_DATA%"') do (
    if "%%a"=="width"          set "SRC_W=%%b"
    if "%%a"=="height"         set "SRC_H=%%b"
    if "%%a"=="pix_fmt"        set "PIX_FMT=%%b"
    if "%%a"=="field_order"    set "FIELD_ORDER=%%b"
    if "%%a"=="r_frame_rate"   set "R_FPS=%%b"
    if "%%a"=="avg_frame_rate" set "A_FPS=%%b"
    if "%%a"=="rotation"       set "ROTATION_TAG=%%b"
    if "%%a"=="TAG:BPS"        set "HAS_VIDEO_TAGS=1"
    if "%%a"=="duration"       set "LENGTH_SECONDS=%%b"
)
del "%FFP_DATA%"
:: Проверяем, что первый параметр "ширина кадра" извлечен и не равен нулю. Иначе это не видеофайл.
if not defined SRC_W goto BADFILE
if %SRC_W% EQU 0 goto BADFILE
goto FILE_VALID
:BADFILE
echo([ERROR] ffprobe не смог извлечь параметры видео. Файл пропущен.
echo(
>>"%LOG%" echo([ERROR] %DATE% %TIME:~0,8% ffprobe не смог извлечь параметры видео. Файл пропущен.
goto NEXT
:FILE_VALID






:: === Блок: ВРЕМЯ ===
:: LENGTH_SECONDS извлечён ранее
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
:: Fallback на усредненный показатель скорости, если кодек не распознан
if not defined SPEED_CENTI (
    >>"%LOG%" echo([WARNING] %DATE% %TIME:~0,8% Неизвестный кодек: %CODEC%.
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Для расчёта времени кодирования берем скорость 50
    set "SPEED_CENTI=50"
)
:: Рассчитываем примерное время кодирования в секундах
set /a ENCODE_SECONDS = (LENGTH_SECONDS * SPEED_CENTI) / 100
:: Должна быть минимум 1 секунда
if %ENCODE_SECONDS% LSS 1 set "ENCODE_SECONDS=1"
:: Переводим секунды в минуты:секунды
set /a "MINUTES=ENCODE_SECONDS / 60"
set /a "SECONDS=ENCODE_SECONDS %% 60"
if %SECONDS% LSS 10 set "SECONDS=0%SECONDS%"
echo(Примерное время кодирования: %MINUTES% минут %SECONDS% секунд.
echo(
:DONE_LENGTH






:: === Блок: ЦВЕТ ===
:: Блок должен быть перед блоком ПОВОРОТ
:: Определение цветового диапазона (Full Range / Limited Range)
::   - Если ffprobe извлёк pix_fmt=yuvj420p - считаем, что видео должно отображаться в Full Range,
::     хотя видео по факту - Limited (16-235). Это стандартное поведение телефонов:
::     они используют yuvj420p, чтобы плееры "растянули" диапазон и сделали видео ярче.
::   - Чтобы сохранить этот эффект, устанавливаем colour-range=1 через mkvpropedit в MKV.
::     ffmpeg не гарантирует запись этого тега, а mkvpropedit не работает с MP4.
::     Поэтому при yuvj420p расширение меняется на MKV, даже если юзер выбрал MP4.
::   - Важно: colour-range приоритетнее rotate при кодеке *qsv - конфликт решается в блоке ПОВОРОТ.
:: Если очень надо получить MP4 с Full Range (теория, не проверено), то вручную позже:
::   ffmpeg.exe -i input.mkv -c copy -map 0:v -map 0:a? -map 0:s? -f mp4 -tag:v hvc1 temp.mp4
::   MP4Box.exe -add temp.mp4 -new output.mp4 -color=1

:: PIX_FMT извлечён ранее - определяем JPEG FULL RANGE по PIX_FMT
if /i "%PIX_FMT%" == "yuvj420p" set "COLOR_RANGE=1"

:: Здесь нельзя if (...) так как второй %OUTPUT_EXT% во второй строке не возьмёт первый set
if "%OUTPUT_EXT%" == "mkv" goto COLOR_RANGE_DONE
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Для записи metadata full color с помощью mkvpropedit - меняем расширение на mkv
set "OUTPUT_EXT=mkv"
set "OUTPUT=%OUTPUT_DIR%%OUTPUT_NAME%.%OUTPUT_EXT%"
:COLOR_RANGE_DONE







:: === Блок: ПОВОРОТ ===
:: Этот блок должен быть после блока ЦВЕТ и перед блоком МАСШТАБ
:: Определяет способ поворота:
:: - физический (transpose), если кодек поддерживает (*nvenc, *amf)
:: - или через metadata rotate в MP4 (для *qsv)
:: Учитывает: user ROTATION, тег Rotate в MP4/MOV
:: Устанавливает: ROTATION_FILTER, ROTATION_METADATA, EFFECTIVE_H

:: SRC_H, SRC_W и ROTATION_TAG извлечены ранее
set "ROTATION_FILTER="
set "ROTATION_METADATA="
set "EFFECTIVE_H=%SRC_H%"

:: Проверяем user-set - он приоритет
if defined ROTATION (
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Пользователь задал ROTATION=%ROTATION%
    goto APPLY_ROTATION
)

:: Только MP4/MOV поддерживают тег Rotate
set "SUPPORTS_ROTATE_TAG="
if /i "%EXT%" == ".mp4" set "SUPPORTS_ROTATE_TAG=1"
if /i "%EXT%" == ".mov" set "SUPPORTS_ROTATE_TAG=1"
if not defined SUPPORTS_ROTATE_TAG goto ROTATION_DONE
if not defined ROTATION_TAG goto ROTATION_DONE
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% В metadata найден тег Rotate: "%ROTATION_TAG%"
set "ROTATION=%ROTATION_TAG%"

:APPLY_ROTATION
:: Кодеки *qsv не поддерживают фильтр transpose - используем metadata
if /i not "%CODEC:~-3%" == "qsv" goto TRY_TRANSPOSE
if not defined COLOR_RANGE goto CHANGE_EXT
:: Конфликт: full-range (требует MKV) и rotate tag (требует MP4) при кодеке без transpose (qsv)
:: Решение: full-range важнее - файл пропускается
echo([ERROR] Конфликт: colour-range и rotate для "%CODEC%" - невозможны вместе.
echo(colour-range важнее. Поверните видео до кодирования или смените кодек. Файл пропущен.
echo(
>>"%LOG%" echo([ERROR] %DATE% %TIME:~0,8% Конфликт: colour-range и rotate. Смените кодек. Файл пропущен.
goto NEXT

:CHANGE_EXT
:: Для записи тега rotate в metadata требуется MP4
::   - тег rotate не работает в MKV (плееры его игнорируют)
::   - кодек %CODEC% не поддерживает фильтр transpose (нельзя повернуть физически)
:: Поэтому временно меняем расширение на mp4, даже если выбран mkv
if "%OUTPUT_EXT%" == "mp4" goto SKIP_CHANGE_EXT
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Меняем расширение на mp4 для записи тега Rotate
set "OUTPUT_EXT=mp4"
set "OUTPUT=%OUTPUT_DIR%%OUTPUT_NAME%.%OUTPUT_EXT%"
:SKIP_CHANGE_EXT
:: Сохраняем поворот как metadata
set "ROTATION_METADATA=-metadata:s:v:0 rotate=%ROTATION%"
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Поворот кодеком невозможен - будет сохранён как тег metadata в файле MP4
goto ROTATION_DONE

:TRY_TRANSPOSE
:: При физическом повороте (transpose) ширина становится высотой: EFFECTIVE_H = SRC_W
if "%ROTATION%" == "-90" (
    set "ROTATION_FILTER=transpose=1"
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Применён поворот на 90 градусов по часовой стрелке
    set "EFFECTIVE_H=%SRC_W%"
    goto ROTATION_DONE
)
if "%ROTATION%" == "90" (
    set "ROTATION_FILTER=transpose=2"
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Применён поворот на 90 градусов против часовой стрелки
    set "EFFECTIVE_H=%SRC_W%"
    goto ROTATION_DONE
)

:ROTATION_DONE






:: === Блок: МАСШТАБ ===
:: Принимает решение о масштабировании:
:: - SCALE=1: до 720p, если высота > 720
:: - SCALE=: до 1080p, если физически повёрнуто и высота > 1080
:: Устанавливает: SET_SCALE_FILTER, SCALE_EXPR

set "SET_SCALE_FILTER="
set "SCALE_EXPR="
:: EFFECTIVE_H уже установлена в блоке ROTATION_SETUP
:: Без ROTATION_FILTER: EFFECTIVE_H = SRC_H. Иначе: EFFECTIVE_H = SRC_W

:: Если SCALE не задан - переходим к обработке без масштабирования по повороту
if not defined SCALE goto CHECK_SCALE_EMPTY

:: SCALE=1 - задан - уменьшаем до 720 только при превышении высоты
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Режим SCALE=1: высота после поворота %EFFECTIVE_H% -
if %EFFECTIVE_H% LEQ 720 (
    >>"%LOG%" echo([INFO] 720 или менее - не масштабируем.
    goto SKIP_SCALE
)
>>"%LOG%" echo([INFO] более 720 - масштабируем до 720

:: При физическом повороте (transpose) ширина становится высотой - масштабируем по ширине
if defined ROTATION_FILTER (
    set "SCALE_EXPR=scale=720:-2"
    goto SET_SCALE_FLAG
)

:: Физического поворота нет - масштабируем по высоте
set "SCALE_EXPR=scale=-2:720"
goto SET_SCALE_FLAG

:: Если SCALE не задан -> масштабируем до 1080 ТОЛЬКО если физически повёрнуто и высота > 1080
:CHECK_SCALE_EMPTY
if not defined ROTATION_FILTER goto SKIP_SCALE

>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Кадр физически повёрнут, высота после поворота %EFFECTIVE_H%
if %EFFECTIVE_H% LEQ 1080 (
    >>"%LOG%" echo([INFO] 1080 или менее - не масштабируем.
    goto SKIP_SCALE
)
>>"%LOG%" echo([INFO] больше 1080 - масштабируем до 1080.
set "SCALE_EXPR=scale=1080:-2"

:SET_SCALE_FLAG
set "SET_SCALE_FILTER=1"

:SKIP_SCALE






:: === Блок: ЧАСТОТА ===
:: Цель: привести VFR (variable frame rate) к CFR (constant), чтобы:
:: - избежать проблем с аппаратными кодеками (некоторые их не любят),
:: - улучшить совместимость с проигрывателями и ТВ.
:: r_frame_rate = базовая частота (например, 30000/1001)
:: avg_frame_rate = средняя за видео
:: Их несовпадение означает VFR FPS.
:: FIELD_ORDER, R_FPS и A_FPS извлечены ранее

:: Пропускаем анализ FPS, если видео чересстрочное
if /i not "%FIELD_ORDER%" == "progressive" (
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Обнаружено чересстрочное видео. Пропускаем анализ FPS VFR.
    goto FPS_DONE
)

if defined FPS (
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% FPS задан принудительно: %FPS%, пропускаем его обработку
    goto FPS_DONE
)

if not defined R_FPS (
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Не удалось извлечь r_frame_rate - анализ VFR пропущен
    goto FPS_DONE
)
:: Эту проверку оставляем только для лога, так как если нет R_FPS, то и не с чем сравнивать
if not defined A_FPS (
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Не удалось извлечь avg_frame_rate - анализ VFR пропущен
    goto FPS_DONE
)

:: Если r_frame_rate == avg_frame_rate - это CFR, ничего не делаем
if "%R_FPS%" == "%A_FPS%" goto FPS_DONE

:: Если дошли сюда - значит: progressive, R/A_FPS есть, но не равны -> VFR
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Обнаружен FPS VFR. Извлекаем max frame rate из mediainfo
set "MAX_FPS="
set "TMPMI=%temp%\%CMDN%-mi-fps-%random%%random%.txt"
"%MI%" --Inform="Video;%%FrameRate_Maximum%%" "%FNF%" >"%TMPMI%"
set /p MAX_FPS= <"%TMPMI%"
del "%TMPMI%"
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






:: === Блок: ПРОФИЛЬ ===
:: Профиль кодирования profile: main/high - 8 bit, main10 - 10 bit. Для всех H.264 - только high.
:: Формат пикселей pix_fmt: в зависимости от профиля и поддержки кодеком
set "USE_PROFILE=high"
set "PIX_FMT_ARGS=-pix_fmt yuv420p"
:: H.264 использует профиль high по умолчанию
if /i "%CODEC:~0,5%" == "h264_" goto PROFILE_PIX_DONE
if /i "%CODEC%" == "libx264" goto PROFILE_PIX_DONE
:: Для HEVC используем main10, libx265 требует yuv420p10le
set "USE_PROFILE=main10"
set "PIX_FMT_ARGS=-pix_fmt p010le"
if /i "%CODEC%" == "libx265" set "PIX_FMT_ARGS=-pix_fmt yuv420p10le"
:: Если пользователь явно запросил для HEVC профиль main - меняем
if /i not "%PROFILE%" == "main" goto PROFILE_PIX_DONE
set "USE_PROFILE=main"
set "PIX_FMT_ARGS=-pix_fmt yuv420p"
:PROFILE_PIX_DONE
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Установлен профиль кодирования: %USE_PROFILE%
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Установлен формат пикселей: %PIX_FMT_ARGS%







:: === Блок: ВИДЕОФИЛЬТР ===
:: Этот блок должен быть после блоков МАСШТАБ, ПОВОРОТ, ЧАСТОТА
:: Порядок фильтров: scale -> transpose -> deinterlace -> fps
::   - scale до поворота (размеры), deinterlace после (ориентация), fps в конце (VFR)
set "FILTER_LIST="
:: Добавляем scale, если не пропущен и задан
if not defined SET_SCALE_FILTER goto SKIP_SCALE
if not defined SCALE_EXPR goto SKIP_SCALE
if defined FILTER_LIST (
    set "FILTER_LIST=%FILTER_LIST%,%SCALE_EXPR%"
    goto SKIP_SCALE
)
set "FILTER_LIST=%SCALE_EXPR%"
:SKIP_SCALE

:: Добавляем transpose, если задан
if not defined ROTATION_FILTER goto SKIP_TRANSPOSE
if defined FILTER_LIST (
    set "FILTER_LIST=%FILTER_LIST%,%ROTATION_FILTER%"
    goto SKIP_TRANSPOSE
)
set "FILTER_LIST=%ROTATION_FILTER%"
:SKIP_TRANSPOSE

:: Добавляем деинтерлейс, если включён
if /i "%FIELD_ORDER%" == "progressive" goto SKIP_DEINT
set "INTCMD=bwdif=1"
if defined FILTER_LIST (
    set "FILTER_LIST=%FILTER_LIST%,%INTCMD%"
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Применён деинтерлейсинг: %INTCMD%
    goto SKIP_DEINT
)
set "FILTER_LIST=%INTCMD%"
:SKIP_DEINT

:: Добавляем fps, если задан
if not defined FPS goto SKIP_FPS
if defined FILTER_LIST (
    set "FILTER_LIST=%FILTER_LIST%,fps=%FPS%"
    goto SKIP_FPS
)
set "FILTER_LIST=fps=%FPS%"
:SKIP_FPS

:: Формируем итоговый флаг -vf
if not defined FILTER_LIST (
    set "VF="
    goto VF_DONE
)
set "VF=-vf "%FILTER_LIST%""
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Видеофильтр: %VF%
:VF_DONE







:: === Блок: КЛЮЧИ ===
:: Порядок ключей КРИТИЧЕН (особенно для qsv): кодек -> профиль -> vf -> crf
:: Общий порядок ключей ffmpeg должен быть такой:
:: -hide_banner -c:v codec [-profile:v] [-preset] [-vf] [-pix_fmt] [-crf] [-tune] [-level]
:: [-metadata rotate] -c:a -c:s [-metadata lng]
set "FINAL_KEYS=-hide_banner -c:v %CODEC%"
if /i not "%CODEC:~-5%" == "nvenc" set "FINAL_KEYS=%FINAL_KEYS% -profile:v %USE_PROFILE%"
if /i "%CODEC%" == "libx264" set "FINAL_KEYS=%FINAL_KEYS% -preset slow -tune film"

:: Обработка CRF/VBR для *nvenc:
if /i not "%CODEC:~-5%" == "nvenc" goto SKIP_NVENC_OPTS
set "FINAL_KEYS=%FINAL_KEYS% -preset p7 -tune uhq"
:: -multipass fullres несовместим с CRF, но даст качество выше
:: При multipass нужно задавать битрейт: -b:v - целевой битрейт (average)
:: -maxrate - пиковый битрейт, -bufsize - размер буфера декодера (VBV)
:: bufsize должен быть не меньше maxrate, иначе могут быть проблемы с проигрывателями
:: Оптимальные: 720: -b:v 2.5M -maxrate 3.5M -bufsize 4M. 1080: -b:v 4.5M -maxrate 6M -bufsize 7M
if defined CRF (
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% NVENC: Используется CRF-режим -cq %CRF%
    goto SKIP_BITRATE
)
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% NVENC: Используется VBR-HQ с multipass, битрейт по высоте %EFFECTIVE_H%p
:: Устанавливаем битрейт по EFFECTIVE_H
if %EFFECTIVE_H% LEQ 720 (
    set "BITRATE_V=2.5M"
    set "BITRATE_MAX=3.5M"
    set "BITRATE_BUF=4M"
)
if %EFFECTIVE_H% GTR 720 (
    set "BITRATE_V=4.5M"
    set "BITRATE_MAX=6M"
    set "BITRATE_BUF=7M"
)
set "FINAL_KEYS=%FINAL_KEYS% -multipass fullres"
set "FINAL_KEYS=%FINAL_KEYS% -b:v %BITRATE_V% -maxrate %BITRATE_MAX% -bufsize %BITRATE_BUF%"
:SKIP_BITRATE
set "FINAL_KEYS=%FINAL_KEYS% -rc-lookahead 32 -spatial_aq 1"
set "FINAL_KEYS=%FINAL_KEYS% -aq-strength 12 -temporal_aq 1 -b_ref_mode each"
:: если будет ошибка b_ref_mode 'each' is not supported - вернуть -b_ref_mode middle
:SKIP_NVENC_OPTS

:: Level для h264_* кодеков (совместимость с проигрывателями)
if /i "%CODEC:~0,5%" == "h264_" set "FINAL_KEYS=%FINAL_KEYS% -level 4.0"
if /i "%CODEC%" == "libx264" set "FINAL_KEYS=%FINAL_KEYS% -level 4.0"

:: Видеофильтр -vf
if defined VF set "FINAL_KEYS=%FINAL_KEYS% %VF%"

:: Формат пикселей (8 bit yuv420p или 10 bit yuv420p10le)
if defined PIX_FMT_ARGS set "FINAL_KEYS=%FINAL_KEYS% %PIX_FMT_ARGS%"

:: Параметры управления качеством (не битрейтом)
set "FINAL_CRF="
if not defined CRF goto SKIP_CRF
if /i "%CODEC:~-5%" == "nvenc"  set "FINAL_CRF=-cq %CRF%"
if /i "%CODEC:~-3%" == "amf"    set "FINAL_CRF=-rc cqp -qp_i %CRF% -qp_p %CRF% -quality quality"
if /i "%CODEC:~-3%" == "qsv"    set "FINAL_CRF=-global_quality %CRF%"
if /i "%CODEC:~0,5%" == "libx2" set "FINAL_CRF=-crf %CRF%"
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% CRF установлен: %CRF%
:SKIP_CRF
if defined FINAL_CRF set "FINAL_KEYS=%FINAL_KEYS% %FINAL_CRF%"

:: Metadata - Rotate если не поворачиваем видео из-за неподдерживаемого аппаратного кодека
if defined ROTATION_METADATA set "FINAL_KEYS=%FINAL_KEYS% %ROTATION_METADATA%"

:: Аудио и субтитры
if not defined AUDIO_ARGS set "AUDIO_ARGS=-c:a copy"
set "FINAL_KEYS=%FINAL_KEYS% %AUDIO_ARGS% -c:s copy"

:: Устанавливаем язык аудио и субтитров в "rus". Язык видео - не трогаем: 
:: ffmpeg делает это криво в MKV, а в MP4 пусть остаётся und/eng.
:: Язык видеодорожки устанавливается через mkvpropedit - ffmpeg делает это некорректно в MKV.
:: Если включён full-range (COLOR_RANGE=1) - mkvpropedit также добавит цветовые метаданные.
set "FINAL_KEYS=%FINAL_KEYS% -metadata language=rus"
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:a:0 language=rus"
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:s:0 language=rus"

:: Удаляем старые видео-теги "битрейт" и "размер потока", если они есть.
:: FFmpeg копирует их из исходника, но при перекодировании значения неактуальны.
if not defined HAS_VIDEO_TAGS goto SKIP_CLEAN
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:v BPS="
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:v BPS-eng="
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:v NUMBER_OF_BYTES="
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:v NUMBER_OF_BYTES-eng="
:: Удаляем старые аудио-теги "битрейт" и "размер потока" ТОЛЬКО при перекодировании,
:: так как при -c:a copy значения остаются корректными.
if "%AUDIO_ARGS%" == "-c:a copy" goto SKIP_CLEAN
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:a BPS="
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:a BPS-eng="
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:a NUMBER_OF_BYTES="
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:a NUMBER_OF_BYTES-eng="
:SKIP_CLEAN





:: === Блок: ОБРАБОТКА ===
:: Пишем CMD_LINE в лог через set, так как есть ключи с кавычками и спецсимволами
set "CMD_LINE="%FFM%" -i "%FNF%" %FINAL_KEYS% "%OUTPUT%""
>>"%LOG%" echo([CMD] %DATE% %TIME:~0,8% Строка кодирования: %CMD_LINE%
:: Запуск кодирования. FFmpeg пишет лог в stderr, а не в stdout - поэтому 2>LOG
:: Не запускаем через %CMD_LINE%, т.к. могут быть ошибки при спецсимволах.
"%FFM%" -i "%FNF%" %FINAL_KEYS% "%OUTPUT%" 2>"%FFMPEG_LOG%"

:: Конвертируем лог в OEM для findstr (см. блок GPU-проверки)
:: Пути должны быть без кириллицы из-за разных кодировок CMD и VBS
:: Переходим в папку Logs
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
set "FFERR="
:: Не отрывать строку findstr от if errorlevel
findstr /i "error failed" "%TMPFLOEM%">nul
if %ERRORLEVEL% EQU 0 (
    set "FFERR=1"
    echo(FFmpeg завершился с ошибкой! Cм. "%FFMPEG_LOG_NAME%"
    echo(
    >>"%LOG%" echo([ERROR] %DATE% %TIME:~0,8% FFmpeg завершился с ошибкой - см. "%FFMPEG_LOG_NAME%"
)
del "%TMPFLOEM%"
popd
del "%VT%"
if not exist "%OUTPUT%" goto FINISH
if defined FFERR goto CLEAN

:: Если файл - MKV но не full-range - только меняем язык видео на русский
:: Остальные дорожки (аудио, субтитры) уже получили language=rus через ffmpeg -metadata (см. выше)
if not "%OUTPUT_EXT%" == "mkv" goto SUCCESS
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% В MKV меняем язык видеодорожки на русский
if defined COLOR_RANGE goto MKVFULLRANGE
"%MKVP%" "%OUTPUT%" --edit track:v1 --set "language=rus">nul
goto SUCCESS

:MKVFULLRANGE
:: Для MKV Full-range добавляем цветовые метаданные + меняем язык на русский
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Full color range: добавляем в MKV теги colour-range
"%MKVP%" "%OUTPUT%" --edit track:v1 --set "language=rus" --set "colour-range=1" --set "color-matrix-coefficients=1">nul

:SUCCESS
echo(Создан "%OUTPUT_NAME%.%OUTPUT_EXT%".
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Создан "%OUTPUT_NAME%.%OUTPUT_EXT%"
>>"%LOG%" echo(---
goto FINISH

:CLEAN
:: Если ffmpeg после ошибки создал нулевой файл - удаляем его
for %%F in ("%OUTPUT%") do set SIZE=%%~zF
if %SIZE% EQU 0 del "%OUTPUT%"

:FINISH
echo(%DATE% %TIME:~0,8% Обработка "%FNWE%" завершена.
echo(Cм. логи в папке "%OUTPUT_DIR%logs".
echo(---

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