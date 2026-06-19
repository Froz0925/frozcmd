@echo off
:: Перекодирование видеофайлов в уменьшенный размер с высоким качеством
set "DO=Video recode script"
set "VRS=Froz %DO% v03.06.2026"

:: === Блок: ПРОВЕРКИ ===
title %DO%
echo(%VRS%
echo(Прервать кодирование - Ctrl-C.
echo(
set "CMDN=%~n0"
:: Инициализация var для if defined в FASTEXIT
set "CONV="
set "GLOG="
set "DTMPV="

:: Проверка наличия утилит
set "FFM=%~dp0bin\ffmpeg.exe"
set "FFP=%~dp0bin\ffprobe.exe"
set "MI=%~dp0bin\mediainfo.exe"
set "MKVP=%~dp0bin\mkvpropedit.exe"
if not exist "%FFM%" echo([!] "%FFM%"& goto NOEXE
if not exist "%FFP%" echo([!] "%FFP%"& goto NOEXE
if not exist "%MI%" echo([!] "%MI%"& goto NOEXE
if not exist "%MKVP%" echo([!] "%MKVP%"& goto NOEXE
goto CHECK_INI
:NOEXE
echo( не найден, выходим.& echo(
goto FASTEXIT

:CHECK_INI
:: Создаём один раз VBS-хелпер конвертации файлов OEM-UTF и UTF-OEM. Нужен pushd.
:: Пример запуска: cscript //nologo "%CONV%" "%LOGE%" "%LOGU%" "cp866" "UTF-8"
:: ADODB.Stream принимает пути без внешних кавычек. 
:: WScript.Arguments(x) очищает кавычки автоматически перед передачей в VBS.
set "CONV=%temp%\%CMDN%-conv.vbs"
>"%CONV%"  echo(Set a=WScript.Arguments:With CreateObject("ADODB.Stream")
>>"%CONV%" echo(.Type=2:.Open:.Charset=a(2):.LoadFromFile a(0):s=.ReadText:.Close
>>"%CONV%" echo(.Open:.Charset=a(3):.WriteText s:.SaveToFile a(1),2:End With

set "INI_NAME=%CMDN%.ini"
set "INI_FPATH=%~dp0%INI_NAME%"
if exist "%INI_FPATH%" goto SRC_CHK
:: Если ini нет - создаём шаблон. В VBS нельзя полный путь, поэтому меняем папку
pushd "%~dp0"
set "IOEMW=%CMDN%-inioemw%random%"
>"%IOEMW%" echo(; Настройки Froz Video recode script (%CMDN%). Подробнее см. в %CMDN%.txt
>>"%IOEMW%" echo(-------------------------------------------------------------------------
>>"%IOEMW%" echo(
>>"%IOEMW%" echo(; РАЗМЕР: 1 = уменьшить до 720p. Пусто = до 1080p. Меньшие видео не увеличиваются.
>>"%IOEMW%" echo(SCALE=
>>"%IOEMW%" echo(
>>"%IOEMW%" echo(; КАЧЕСТВО (меньше = лучше): nvenc/libx265: 26-33, libx264: 18-28. 
>>"%IOEMW%" echo(; AV1 (все энкодеры): 28-35. amf/qsv: 20-30. Пусто = авто-качество (обычно невысокое).
>>"%IOEMW%" echo(CRF=32
>>"%IOEMW%" echo(
>>"%IOEMW%" echo(; КОНТЕЙНЕР: mkv (рекомендуется) или mp4. При Full-Range цвете будет принудительно MKV.
>>"%IOEMW%" echo(OUTPUT_EXT=mkv
>>"%IOEMW%" echo(
>>"%IOEMW%" echo(; АУДИО: Пусто = копировать аудиодорожку без перекодирования.
>>"%IOEMW%" echo(; OPUS (для MKV): -c:a libopus -b:a 128k -ac 2
>>"%IOEMW%" echo(; AAC (для MP4): -c:a aac -b:a 192k -ac 2.  См. правила копирования в %CMDN%.txt.
>>"%IOEMW%" echo(AUDIO_ARGS=-c:a libopus -b:a 128k -ac 2
>>"%IOEMW%" echo(
>>"%IOEMW%" echo(; ПОВОРОТ: -90 (по час.), 90 (против), 180. Пусто = авто из тега файла (если есть).
>>"%IOEMW%" echo(ROTATION=
>>"%IOEMW%" echo(
>>"%IOEMW%" echo(; КОДЕК: CPU - медленно, макс. кач-во. По убыванию эффективности - меньший размер
>>"%IOEMW%" echo(; при том же качестве: libsvtav1, libx265, libx264. 
>>"%IOEMW%" echo(; GPU (nvenc-Nvidia, amf-AMD, qsv-Intel): av1_nvenc, av1_amf, av1_qsv
>>"%IOEMW%" echo(; hevc_nvenc, hevc_amf, hevc_qsv. Требования к железу - см. %CMDN%.txt.
>>"%IOEMW%" echo(CODEC=libsvtav1
>>"%IOEMW%" echo(
>>"%IOEMW%" echo(; FPS: 24, 25, 30, 50, 60, 24000/1001 (~23.976), 30000/1001 (~29.97). Пусто = авто.
>>"%IOEMW%" echo(FPS=
>>"%IOEMW%" echo(
>>"%IOEMW%" echo(; СУФФИКС готового файла (добавляется к имени исходника).
>>"%IOEMW%" echo(NAME_APPEND=_sm
>>"%IOEMW%" echo(
>>"%IOEMW%" echo(; КАЛИБРОВКА СКОРОСТИ: Нужна для расчета времени (сек. кодирования / сек. видео) x 100.
>>"%IOEMW%" echo(SPEED_LIBSVTAV1=130
>>"%IOEMW%" echo(SPEED_LIBX265=150
>>"%IOEMW%" echo(SPEED_LIBX264=120
>>"%IOEMW%" echo(SPEED_NVENC=8
>>"%IOEMW%" echo(SPEED_AMF=50
>>"%IOEMW%" echo(SPEED_QSV=50
:: Конвертируем ini в UTF-8 и удаляем временный файл
cscript //nologo "%CONV%" "%IOEMW%" "%INI_NAME%" "cp866" "UTF-8"
del "%IOEMW%"
popd
echo([!] Файл настроек не найден - создан новый шаблон.
echo(
goto HELP

:SRC_CHK
:: Проверка наличия входных файлов
if "%~1" == "" goto HELP
set "ATTR=%~a1"
if /i "%ATTR:~0,1%"=="d" (
    echo([ERROR] Папки не обрабатываются, выходим.
    echo(
    pause
    goto FASTEXIT
)
goto READ_INI
:HELP
echo([!] Не заданы входные файлы.
echo(
echo(Использование: При необходимости измените настройки в файле
echo(%INI_FPATH%
echo(редактором для Unicode TXT-файлов, например Блокнотом.
echo(
echo(Затем перетяните или вставьте видеофайлы на этот файл.
echo(
goto FASTEXIT

:READ_INI
:: Читаем ini-файл в переменные.
:: Сброс переменных
set "SCALE="
set "CRF="
set "OUTPUT_EXT="
set "AUDIO_ARGS="
set "ROTATION="
set "CODEC="
set "FPS="
set "NAME_APPEND="
set "SPEED_LIBSVTAV1="
set "SPEED_LIBX265="
set "SPEED_LIBX264="
set "SPEED_NVENC="
set "SPEED_AMF="
set "SPEED_QSV="
:: Конвертация UTF-8 в OEM - нельзя полный путь в VBS, поэтому pushd
pushd "%~dp0"
set "IOEMR=%CMDN%-inioemr%random%"
cscript //nologo "%CONV%" "%INI_NAME%" "%IOEMR%" "UTF-8" "cp866"
:: Чтение ini-файла
for /f "usebackq tokens=1* delims==" %%a in ("%IOEMR%") do (
    if "%%a"=="SCALE"               set "SCALE=%%b"
    if "%%a"=="CRF"                 set "CRF=%%b"
    if "%%a"=="OUTPUT_EXT"          set "OUTPUT_EXT=%%b"
    if "%%a"=="AUDIO_ARGS"          set "AUDIO_ARGS=%%b"
    if "%%a"=="ROTATION"            set "ROTATION=%%b"
    if "%%a"=="CODEC"               set "CODEC=%%b"
    if "%%a"=="FPS"                 set "FPS=%%b"
    if "%%a"=="NAME_APPEND"         set "NAME_APPEND=%%b"
    if "%%a"=="SPEED_LIBSVTAV1"     set "SPEED_LIBSVTAV1=%%b"
    if "%%a"=="SPEED_LIBX265"       set "SPEED_LIBX265=%%b"
    if "%%a"=="SPEED_LIBX264"       set "SPEED_LIBX264=%%b"
    if "%%a"=="SPEED_NVENC"         set "SPEED_NVENC=%%b"
    if "%%a"=="SPEED_AMF"           set "SPEED_AMF=%%b"
    if "%%a"=="SPEED_QSV"           set "SPEED_QSV=%%b"
)
:: Удаление OEM-ini и возврат в исходную папку
del "%IOEMR%"
popd

:: Проверка ключевых user sets:
if not defined CODEC (
    echo([!] В %INI_FPATH%
    echo(не задан параметр CODEC - задайте. Выходим.
    echo(
    pause
    goto FASTEXIT
)
if not defined OUTPUT_EXT (
    set "OUTPUT_EXT=mkv"
    echo([!] В %INI_FPATH%
    echo(не задано расширение выходных файлов - принимаем: %OUTPUT_EXT%
    echo(
)
if not defined NAME_APPEND (
    set "NAME_APPEND=_sm"
    echo([!] В %INI_FPATH%
    echo(не задан суффикс выходных файлов - принимаем: %NAME_APPEND%
    echo(
)

:: Проверка: поддерживает ли GPU выбранный GPU-кодек
:: Для CPU проверка корректности имени кодека в INI не делается - надеемся на пряморукость юзера
::if /i "%CODEC:~0,3%" == "lib" goto SKIP_GCHK
:: По умолчанию целимся в 10-bit (p010le) для HEVC и AV1
set "FF_PIXFMT=-pix_fmt p010le"
:: Если выбран кодек семейства h264 - для него стартуем сразу с 8-bit (пустой фильтр)
if /i "%CODEC:~0,4%" == "h264" set "FF_PIXFMT="
:: Базовое имя для временных файлов (логи и скрипт перекодировки)
set "GLOG=%temp%\%CMDN%-gpuchk.log"
:: Сбрасываем флаг возможной второй попытки перед входом в TRY_GPU
set "GPU_RETRY="
:TRY_GPU
:: Создаём виртуальный пустой видеофайл длиной в 1 секунду и пытаемся сжать кодеком
"%FFM%" -hide_banner -v error -f lavfi -i nullsrc -c:v %CODEC% %FF_PIXFMT% -t 1 -f null - 2>"%GLOG%"
:: ffmpeg пишет stderr в UTF-8, но мы ищем латиницу, поэтому можно не конвертировать лог в OEM для findstr
:: Проверка на кривое имя GPU-энкодера в INI-файле
:: Если ошибка есть (строка найдена - findstr вернул 0) - проверка не пройдена
:: Не отрывать строку findstr от строки errorlevel !
findstr /i /c:"Unknown encoder" "%GLOG%" >nul
if %ERRORLEVEL% EQU 0 (
    echo([ERROR] Имя кодека некорректно - проверьте INI-файл. Выходим.
    echo(
    pause
    goto FASTEXIT
)
:: Не отрывать строку findstr от строки errorlevel !
findstr /i /c:"Error while opening encoder" "%GLOG%" >nul
set "GPU_ERR=%ERRORLEVEL%"
:: Если ошибки нет (строка Error НЕ найдена - findstr вернул 1) - проверка пройдена
if %GPU_ERR% EQU 1 goto SKIP_GCHK
if defined GPU_RETRY goto GPU_NOT_SUPPORTED
if /i not "%CODEC:~0,4%" == "hevc" goto GPU_NOT_SUPPORTED
:: Если мы тут, значит упал HEVC 10-битный режим. Пробуем 8 бит
set "GPU_RETRY=1"
set "FF_PIXFMT="
echo([INFO] GPU не поддерживает 10-bit. Пробуем 8-bit...
goto TRY_GPU
:GPU_NOT_SUPPORTED
:: Если мы здесь - это окончательный сбой (упал H.264, AV1, 8-битный HEVC)
echo([ERROR] Видеокарта или её драйвер не поддерживает выбранный GPU-кодек.
echo(Обновите видеокарту/драйвер или смените кодек в настройках. Выходим.
echo(
goto FASTEXIT
:SKIP_GCHK





:: Глобальные set перед LOOP
:: Все подаваемые на вход файлы всегда лежат в одной папке.
set "OUTPUT_DIR=%~dp1"
:: Сохраняем исходные user-значения которые могут быть перезаписаны при работе
set "INI_OUTPUT_EXT=%OUTPUT_EXT%"
set "INI_AUDIO_ARGS=%AUDIO_ARGS%"
set "INI_FPS=%FPS%"
set "AUDIO_DEFAULT=-c:a copy"

:: Создаём один раз VBS-хелпер штампа времени для temp-файлов
:: Временное имя OEM-лога для текущего видеофайла - используем дату, а не %random%.
:: Чтобы не зависеть от локали Windows берём текущую дату-время через VBS, 
:: а не через %date% %time%. Формат: ГГГГ-ММ-ДД_ЧЧММСС
set "DTMPV=%temp%\%CMDN%-dtmpv.vbs"
>"%DTMPV%"  echo(s=Year(Now)^&"-"^&Right("0"^&Month(Now),2)^&"-"
>>"%DTMPV%" echo(s=s^&Right("0"^&Day(Now),2)
>>"%DTMPV%" echo(s=s^&"_"^&Right("0"^&Hour(Now),2)^&Right("0"^&Minute(Now),2)
>>"%DTMPV%" echo(s=s^&Right("0"^&Second(Now),2):WScript.Echo s





:: === Блок: СТАРТ ===
:LOOP
:: Восстанавливаем ini-значения для нового файла
set "OUTPUT_EXT=%INI_OUTPUT_EXT%"
set "AUDIO_ARGS=%INI_AUDIO_ARGS%"
set "FPS=%INI_FPS%"
:: Записываем имя файла в переменные чтобы %1 не сломалось в процессе
set "FNF=%~1"
set "FNN=%~n1"
set "FNWE=%~nx1"
set "EXT=%~x1"
set "OUTPUT_NAME=%FNN%%NAME_APPEND%"
set "OUTPUT=%OUTPUT_DIR%%OUTPUT_NAME%.%OUTPUT_EXT%"

:: Если больше нет файлов - выходим
if not defined FNF goto END

set "ATTR=%~a1"
if /i not "%ATTR:~0,1%"=="d" goto START
echo(%FNN% - папка, пропускаем.
goto NEXT
:START
:: Для надёжности переходим в папку с файлом чтобы ffmpeg всегда нашёл внешние субтитры если они будут
pushd "%OUTPUT_DIR%"
:: Запрашиваем текущий штамп времени из VBS-хелпера TV
for /f %%t in ('cscript //nologo "%DTMPV%"') do set "DTMP=%%t"
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
if %SIZE% GTR 0 goto EXIST
del "%OUTPUT%"
goto DONE_SIZE_CHK
:EXIST
echo("%OUTPUT_NAME%" уже существует, пропускаем.
echo(
goto NEXT
:DONE_SIZE_CHK

title Обработка %FNWE%...
echo(%DATE% %TIME:~0,8% Начата обработка "%FNWE%"...
>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Начата обработка "%FNWE%"...





:: === Блок: ИЗВЛЕЧЕНИЕ ===
:: ffprobe извлекает: размеры кадра, формат пикселей, чересстрочность,
:: частоту кадров (базовая и средняя), поворот, длительность,
:: "мусорные" видеотеги для их удаления позже.
set "SRC_W="
set "SRC_H="
set "SRC_PIXFMT="
set "FIELD_ORDER="
set "R_FPS="
set "A_FPS="
set "ROTATION_TAG="
set "TAGBPS="
set "LENGTH_SECONDS="
set "AUDIO_CODEC="
set "FFP_VTMP=%temp%\%CMDN%-ffprobe-video-%random%.txt"
"%FFP%" -v error ^
    -select_streams v:0 ^
    -show_entries stream=width,height,pix_fmt,field_order,r_frame_rate,avg_frame_rate ^
    -show_entries stream_side_data=rotation ^
    -show_entries stream_tags=BPS ^
    -show_entries format=duration ^
    -of default=nw=1 ^
    "%FNF%" >"%FFP_VTMP%"
:: Если найден видео-тег BPS - ставим флаг
for /f "tokens=1* delims==" %%a in ('type "%FFP_VTMP%"') do (
    if "%%a"=="width"          set "SRC_W=%%b"
    if "%%a"=="height"         set "SRC_H=%%b"
    if "%%a"=="pix_fmt"        set "SRC_PIXFMT=%%b"
    if "%%a"=="field_order"    set "FIELD_ORDER=%%b"
    if "%%a"=="r_frame_rate"   set "R_FPS=%%b"
    if "%%a"=="avg_frame_rate" set "A_FPS=%%b"
    if "%%a"=="rotation"       set "ROTATION_TAG=%%b"
    if "%%a"=="TAG:BPS"        set "TAGBPS=%%b"
    if "%%a"=="duration"       set "LENGTH_SECONDS=%%b"
)
del "%FFP_VTMP%"
:: Проверяем, что первый параметр "ширина кадра" извлечен и не равен нулю. Иначе это не видеофайл.
if not defined SRC_W goto BADFILE
if %SRC_W% EQU 0 goto BADFILE
:: Извлекаем кодек аудиодорожки чтобы решить что с ним делать дальше
set "FFP_ATMP=%temp%\%CMDN%-ffprobe-audio-%random%.txt"
:: Ключ :nk=1 отбросит текст "codec_name="
"%FFP%" -v error -select_streams a:0 -show_entries stream=codec_name -of default=nw=1:nk=1 "%FNF%" >"%FFP_ATMP%"
set /p "AUDIO_CODEC=" <"%FFP_ATMP%"
del "%FFP_ATMP%"
goto EXTRACT_DONE
:BADFILE
echo([ERROR] Не получилось извлечь параметры видео. Файл пропущен.
echo(
>>"%LOG%" echo([ERROR] %DATE% %TIME:~0,8% Не получилось извлечь параметры видео. Файл пропущен.
goto NEXT
:EXTRACT_DONE





:: === Блок: ЦВЕТ ===
:: Блок должен быть перед блоком ПОВОРОТ, так как здесь может измениться контейнер
:: а в MP4 есть тег Rotation.
:: При yuvj420p видео по факту - Limited (16-235). Некоторые телефоны используют yuvj420p,
:: чтобы плееры "растянули" диапазон и сделали видео ярче.
:: Чтобы сохранить этот эффект, устанавливаем colour-range=1 через mkvpropedit в MKV.
:: Если тег записывать через ffmpeg, то по факту он не работает, а mkvpropedit не работает с MP4.
:: Поэтому при yuvj420p расширение принудительно меняем на MKV.
:: Если очень надо получить MP4 с Full Range, то можно вручную позже (не проверено):
::   ffmpeg.exe -i input.mkv -c copy -map 0:v -map 0:a? -map 0:s? -f mp4 -tag:v hvc1 temp.mp4
::   MP4Box.exe -add temp.mp4 -new output.mp4 -color=1
set "COLOR_RANGE="
if /i "%SRC_PIXFMT%" == "yuvj420p" set "COLOR_RANGE=1"
:: Если не Full Range или уже MKV - пропускаем изменения
if not defined COLOR_RANGE goto COLOR_DONE
if /i "%OUTPUT_EXT%" == "mkv" goto COLOR_DONE
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Для записи metadata full color с помощью mkvpropedit - меняем расширение на mkv
:: Меняем расширение на mkv для full-range, пересчитываем OUTPUT
set "OUTPUT_EXT=mkv"
set "OUTPUT=%OUTPUT_DIR%%OUTPUT_NAME%.%OUTPUT_EXT%"
:COLOR_DONE





:: === Блок: ПОВОРОТ ===
:: Этот блок должен быть после блока ЦВЕТ и перед блоком МАСШТАБ
:: 1. Если есть тег rotate в MP4/MOV - ffmpeg применит его сам (autorotate),
::    мы только меняем SRC_H = SRC_W для блока МАСШТАБ.
:: 2. Если ROTATION задан юзером - добавляем transpose. Для кодека *qsv - пишем варнинг и игнорируем.
:: SRC_H, SRC_W и ROTATION_TAG извлечены ранее
set "ROTATION_FILTER="
if defined ROTATION_TAG (
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Применён тег Rotate из файла: %ROTATION_TAG%
    set "SRC_H=%SRC_W%"
)
:: Обрабатываем User-ROTATION
if not defined ROTATION goto ROTATE_DONE
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Указан дополнительный поворот User-Rotation: %ROTATION%. Добавляем ключ transpose.
if "%ROTATION%" == "-90" set "ROTATION_FILTER=transpose=1" & set "SRC_H=%SRC_W%" & goto ROTATE_DONE
if "%ROTATION%" == "90" set "ROTATION_FILTER=transpose=2" & set "SRC_H=%SRC_W%" & goto ROTATE_DONE
:: при 180 - размеры не меняются - SRC_H остаётся как есть
if "%ROTATION%" == "180" set "ROTATION_FILTER=transpose=1,transpose=1"
:ROTATE_DONE





:: === Блок: МАСШТАБ ===
:: Масштабируем если "SCALE=1": до 720p, если высота > 720. "SCALE=": до 1080p, если есть transpose и высота > 1080
set "SCALE_EXPR="
:: Устанавливаем значения по умолчанию (для случая, когда SCALE не задан)
set "SCL_LIMIT=1080"
set "SCL_PREFIX=SCALE не задан"
:: Если SCALE определён в ini - переопределяем значения
if defined SCALE set "SCL_LIMIT=720"
if defined SCALE set "SCL_PREFIX=Задан SCALE=1"
:: Единая проверка высоты
if %SRC_H% LEQ %SCL_LIMIT% (
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% %SRC_H% - %SCL_LIMIT% или менее - не масштабируем.
    goto SCALE_DONE
)
:: Масштабирование требуется
set "SCALE_EXPR=scale=-2:%SCL_LIMIT%"
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% %SRC_H% - масштабируем до %SCL_LIMIT%.
:SCALE_DONE





:: === Блок: ЧАСТОТА ===
:: Цель: привести VFR (variable frame rate) к CFR (constant), чтобы:
:: - избежать проблем с аппаратными кодеками (некоторые их не любят),
:: - улучшить совместимость с проигрывателями и ТВ.
:: r_frame_rate = базовая частота (например, 30000/1001)
:: avg_frame_rate = средняя за видео
:: Их несовпадение означает VFR FPS.
:: FIELD_ORDER, R_FPS и A_FPS извлечены ранее
:: Для interlaced - всегда устанавливать FPS.
:: Сброс здесь заранее, т.к. будет if defined в блоке ВРЕМЯ
set "MAX_FPS="
set "IS_INTERLACED="
:: Если FPS задан вручную - выходим сразу
if defined FPS (
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% FPS задан принудительно: %FPS%.
    goto FPS_DONE
)
:: Если видео чересстрочное - ставим FPS по умолчанию и выходим
if /i "%FIELD_ORDER%" == "unknown" (
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% FIELD_ORDER не определён - "unknown". Считаем видео progressive.
    goto HANDLE_PROGRESSIVE
)
if /i not "%FIELD_ORDER%" == "progressive" goto HANDLE_INTERLACED
:HANDLE_PROGRESSIVE
:: Дальше может быть только progressive видео. Всегда извлекаем MAX_FPS в т.ч. для блока ВРЕМЯ
set "MI_TMP=%temp%\%CMDN%-mi-fps-%random%.txt"
"%MI%" --Inform=Video;%%FrameRate%% "%FNF%" >"%MI_TMP%"
set /p MAX_FPS= <"%MI_TMP%"
del "%MI_TMP%"
if not defined MAX_FPS (
    >>"%LOG%" echo([WARNING] %DATE% %TIME:~0,8% Не удалось извлечь max frame rate из mediainfo
    goto FPS_DONE
)
:: Оставляем только целые значения FPS
for /f "tokens=1 delims=." %%m in ("%MAX_FPS%") do set "MAX_FPS=%%m"
:: Если r_frame_rate == avg_frame_rate - это CFR, ничего не делаем
if "%R_FPS%" == "%A_FPS%" goto FPS_DONE
:: Progressive + VFR - определяем MAX_FPS и ставим стандартный CFR
:: Определяем целевой FPS
if %MAX_FPS% GTR 50 set "FPS=60" & goto REPORT_FPS
:: Если VFR-видео содержит фрагменты с высоким FPS (например, slow-mo >35 к/с),
:: выбираем 50 fps вместо 30, чтобы сохранить плавность.
if %MAX_FPS% GTR 40 set "FPS=50" & goto REPORT_FPS
if %MAX_FPS% GTR 28 set "FPS=30" & goto REPORT_FPS
if %MAX_FPS% GTR 24 set "FPS=25" & goto REPORT_FPS
:: Fallback-FPS
set "FPS=24"
:REPORT_FPS
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Найден переменный FPS. Max Frame Rate: %MAX_FPS%. Установлен FPS: %FPS%
goto FPS_DONE
:HANDLE_INTERLACED
:: Чересстрочное видео - по умолчанию 50p (PAL) или 60p (NTSC 480i)
:: FPS здесь нужен для расчёта времени и выбора режима деинтерлейса (bwdif=0/1)
set "IS_INTERLACED=1"
set "FPS=50"
if %SRC_H% == 480 set "FPS=60"
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Обнаружено чересстрочное видео. Установлен FPS по умолчанию: %FPS%
:FPS_DONE





:: === Блок: ВРЕМЯ ===
:: Блок должен быть после блока ЧАСТОТА
:: Определяем базовую скорость кодирования (SPEED_CENTI = секунд кодирования на 100 сек видео)
set "LEN_CALC="
if "%LENGTH_SECONDS%" == "N/A" (
    echo(Не получилось извлечь длину видео, расчёт времени кодирования пропущен. Продолжаем кодирование.
    goto TIME_DONE
)
:: Определяем базовую скорость (сек кодирования на 100 сек видео)
set "SPEED_CENTI="
if /i "%CODEC%" == "libsvtav1" set "SPEED_CENTI=%SPEED_LIBSVTAV1%"
if /i "%CODEC%" == "libx265" set "SPEED_CENTI=%SPEED_LIBX265%"
if /i "%CODEC%" == "libx264" set "SPEED_CENTI=%SPEED_LIBX264%"
if /i "%CODEC:~-5%" == "nvenc" set "SPEED_CENTI=%SPEED_NVENC%"
if /i "%CODEC:~-3%" == "amf"   set "SPEED_CENTI=%SPEED_AMF%"
if /i "%CODEC:~-3%" == "qsv"   set "SPEED_CENTI=%SPEED_QSV%"
if defined SPEED_CENTI goto TIME_VARS_SET
:: Fallback если кодек не найден в INI
set "SPEED_CENTI=30"
if /i "%CODEC:~0,5%" == "libx2" set "SPEED_CENTI=200"
:TIME_VARS_SET
:: Определяем рабочий FPS для расчёта (приоритет: user > mediainfo > 30)
set "FPS_FOR_TIME=30"
if defined MAX_FPS set "FPS_FOR_TIME=%MAX_FPS%"
if defined FPS set "FPS_FOR_TIME=%FPS%"
:: Поправка на FPS: Видео 50/60 fps тяжелее, чем 30 fps (x1.8)
if %FPS_FOR_TIME% GTR 35 set /a "SPEED_CENTI=(SPEED_CENTI*180+50)/100"
:: Поправка на разрешение: 720p и ниже жмётся в ~2.2 раза быстрее (x0.45)
if %SRC_H% LEQ 720 set /a "SPEED_CENTI=(SPEED_CENTI*45+50)/100"
:: Психологический запас (x1.3) чтобы юзер получил результат "раньше срока"
set /a "SPEED_CENTI=(SPEED_CENTI*130+50)/100"
:: Расчёт времени (округляем длину видео вверх, не меняя исходную переменную)
:: Добавляем точку для защиты от целых чисел без дробной части
for /f "tokens=1 delims=." %%a in ("%LENGTH_SECONDS%.") do set /a "EST=%%a+1"
:: Рассчитываем примерное время кодирования в секундах
set /a "ENCODE_SECONDS=(EST*SPEED_CENTI)/100"
:: Гарантируем минимум 1 секунду
if %ENCODE_SECONDS% EQU 0 set "ENCODE_SECONDS=1"
:: Переводим секунды в минуты:секунды
set /a "MINUTES=ENCODE_SECONDS/60"
set /a "SECONDS=ENCODE_SECONDS%%60"
if %SECONDS% LSS 10 set "SECONDS=0%SECONDS%"
echo(Примерное время кодирования: %MINUTES% минут %SECONDS% секунд.
:TIME_DONE






:: === Блок: ПРОФИЛЬ ===
:: 1. Базовый дефолт для 8-bit (Упавший HEVC автоматом получает main и yuv420p)
set "PROFILE=main"
set "FF_PIXFMT=-pix_fmt yuv420p"
:: 2. Если тест GPU зафиксировал откат HEVC в 8-бит - база уже настроена идеально, уходим
if defined GPU_RETRY goto PROFILE_DONE
:: 3. Если это H.264 (GPU или CPU) - меняем профиль на high (формат yuv420p уже стоит) и уходим
if /i "%CODEC:~0,4%" == "h264" set "PROFILE=high" & goto PROFILE_DONE
if /i "%CODEC%" == "libx264" set "PROFILE=high" & goto PROFILE_DONE
:: 4. Для всех остальных (современных 10-битных) кодеков включаем апгрейд на main10 и p010le
set "PROFILE=main10"
set "FF_PIXFMT=-pix_fmt p010le"
:: 5. Корректировка формата пикселей для CPU-версий (они используют yuv420p10le вместо p010le)
if /i "%CODEC:~0,3%" == "lib" set "FF_PIXFMT=-pix_fmt yuv420p10le"
:: 6. Сброс профиля для AV1 (CPU и GPU - драйвер выставит сам, уходим)
if /i "%CODEC:~0,3%" == "av1" set "PROFILE=" & goto PROFILE_DONE
if /i "%CODEC%" == "libsvtav1" set "PROFILE="
:PROFILE_DONE
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Для %CODEC% установлен формат пикселей: %FF_PIXFMT%






:: === Блок: АУДИО ===
:: Базовый дефолт (закрывает сценарии копирования для MP4 и MKV, а также пустой ini)
set "AUDIO_ARGS=%AUDIO_DEFAULT%"
:: Если звука в оригинале нет - обнуляем и уходим
if not defined AUDIO_CODEC set "AUDIO_ARGS=" & goto AUDIO_DONE
:: Если юзер удалил кодек в ini - copy уже задан - уходим
if not defined INI_AUDIO_ARGS goto AUDIO_DONE
:: --- СЦЕНАРИЙ: КОНТЕЙНЕР MP4 ---
if /i "%OUTPUT_EXT%" == "mkv" goto AUDIO_MKV
:: Если родной звук уже AAC - копируется, уходим
if /i "%AUDIO_CODEC%" == "aac" goto AUDIO_DONE
:: Если юзер сам вручную вписал ключевое слово "aac" в ini - отдаем его кастомные ключи и уходим
:: В строке ниже несмотря на "if not" - работает "если в INI_AUDIO_ARGS найден AAC то..."
:: Но поиск сработает только если set не пустой, поэтому раньше была нужна проверка на непустое
if not "%INI_AUDIO_ARGS%" == "%INI_AUDIO_ARGS:aac=%" set "AUDIO_ARGS=%INI_AUDIO_ARGS%" & goto AUDIO_DONE
:: Во всех остальных случаях для MP4 (например в ini дефолтный Opus) - принудительно ставим AAC 192k
set "AUDIO_ARGS=-c:a aac -b:a 192k -ac 2"
>>"%LOG%" echo([WARNING] %DATE% %TIME:~0,8% В ini указан не AAC. Для MP4 принудительно применен AAC-192k.
goto AUDIO_DONE
:AUDIO_MKV
:: --- СЦЕНАРИЙ: КОНТЕЙНЕР MKV ---
:: В MKV если родной звук Opus - копия уже стоит, уходим
if /i "%AUDIO_CODEC%" == "opus" goto AUDIO_DONE
:: В остальных случаях для MKV (например, исходник MP3) - берём из ini
set "AUDIO_ARGS=%INI_AUDIO_ARGS%"
:AUDIO_DONE
if /i "%AUDIO_ARGS%" == "%AUDIO_DEFAULT%" (
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Аудиодорожка: %AUDIO_CODEC%, контейнер: %OUTPUT_EXT%. Копируем без перекодирования.
)





:: === Блок: СУБТИТРЫ ===
:: Должен быть перед блоком ВИДЕОФИЛЬТР. Обрабатывается только первая дорожка субтитров.
set "SUBS_TYPE="
set "SUBS_FILE="
set "FFP_STMP=%temp%\%CMDN%-ffprobe-subs-%random%.txt"
:: Ключ :nk=1 отбросит текст "codec_name="
"%FFP%" -v error -select_streams s:0 -show_entries stream=codec_name -of default=nw=1:nk=1 "%FNF%" >"%FFP_STMP%"
set /p "SUBS_TYPE=" <"%FFP_STMP%"
del "%FFP_STMP%"
:: Если субтитров нет или вывод в MKV - извлечение не требуется (MKV копирует дорожки напрямую)
if not defined SUBS_TYPE goto SUBS_DONE
if /i "%OUTPUT_EXT%"=="mkv" goto SUBS_DONE
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Найдены субтитры %SUBS_TYPE%. Обрабатывается только первая дорожка.
:: Для MP4 поддерживаем вшивание только srt и ass
if /i "%SUBS_TYPE%"=="srt" set "SUBS_FILE=tempsubs%random%.srt" & goto SUBS_EXTRACT
if /i "%SUBS_TYPE%"=="ass" set "SUBS_FILE=tempsubs%random%.ass" & goto SUBS_EXTRACT
>>"%LOG%" echo([WARNING] %DATE% %TIME:~0,8% Тип субтитров %SUBS_TYPE% не поддерживается для вшивания в MP4. Пропускаем.
goto SUBS_DONE
:SUBS_EXTRACT
"%FFM%" -hide_banner -v error -i "%FNF%" -c:s copy "%OUTPUT_DIR%%SUBS_FILE%" 2>nul
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Извлечён временный файл субтитров %SUBS_FILE%.
:SUBS_DONE






:: === Блок: ВИДЕОФИЛЬТР ===
:: Этот блок должен быть после блоков МАСШТАБ, ПОВОРОТ, ЧАСТОТА
:: Порядок фильтров: scale -> transpose -> deinterlace -> fps
::   - scale до поворота (размеры), deinterlace после (ориентация), fps в конце (VFR)
set "FILTER_LIST="
set "SKIP_FPS_FILTER="
set "VF="
:: Собираем базовые фильтры геометрии
:: Намеренно добавляем запятую перед каждым фильтром - в конце отрежем первый символ (%FL:~1%)
:: Масштабирование, если не пропущен и задан
if defined SCALE_EXPR set "FILTER_LIST=%FILTER_LIST%,%SCALE_EXPR%"
:: Поворот, если задан
if defined ROTATION_FILTER set "FILTER_LIST=%FILTER_LIST%,%ROTATION_FILTER%"
:: Обработка деинтерлейса (только для интерлейсного видео)
if not defined IS_INTERLACED goto PROCESS_FPS
:: По умолчанию: bwdif=1 - 50i->50p, 60i->60p - сохранит плавность
set "INTCMD=bwdif=1"
if not defined FPS goto ADD_DEINTERLACE
:: При юзер-FPS 25/30 ("кино") -> bwdif=0 + skip FPS, чтобы избежать артефактов
:: от bwdif=1,fps=25 (50 кадров и отбросить каждый второй)
if %FPS% LEQ 30 set "INTCMD=bwdif=0" & set "SKIP_FPS_FILTER=1"
:ADD_DEINTERLACE
set "FILTER_LIST=%FILTER_LIST%,%INTCMD%"
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Применён деинтерлейсинг: %INTCMD%
:PROCESS_FPS
:: Если установлен флаг пропуска (из-за bwdif=0) - не добавляем фильтр fps
if defined SKIP_FPS_FILTER goto PROCESS_SUBS
:: Если FPS вообще не задан - не добавляем
if not defined FPS goto PROCESS_SUBS
set "FILTER_LIST=%FILTER_LIST%,fps=%FPS%"
:PROCESS_SUBS
:: Hardburn субтитров в MP4
if not defined SUBS_FILE goto VF_COMPILE
set "FILTER_LIST=%FILTER_LIST%,subtitles=%SUBS_FILE%"
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Для MP4 вшиваем субтитры %SUBS_TYPE% в видеоряд (hardburn).
:VF_COMPILE
:: Финальная сборка ключа -vf
:: Отрезание первого символа (:~1%) убирает лидирующую запятую, 
:: которая неизбежно образуется при динамической склейке фильтров ,scale,fps
if defined FILTER_LIST set "VF=-vf "%FILTER_LIST:~1%""






:: === Блок: ВИДЕОКЛЮЧИ ===
:: Порядок ключей ffmpeg КРИТИЧЕН для правильной работы GPU-кодеков. Должно быть так:
:: -hide_banner -c:v codec [-preset] [кодек-специфичные init-параметры] [-profile:v]
:: [-vf] [-pix_fmt] [-crf] [-tune] [-level] -c:a -c:s [-metadata lng]
set "FFKEYS=-hide_banner -c:v %CODEC%"
if /i "%CODEC:~-5%" == "nvenc" goto NV_OPTS
if /i "%CODEC:~-3%" == "amf" goto AMF_OPTS
if /i "%CODEC:~-3%" == "qsv" goto QSV_OPTS
:: Мы в CPU libx-кодеках
set "FFKEYS=%FFKEYS% -preset slow"
if /i "%CODEC:~-3%" == "av1" set "FFKEYS=%FFKEYS% -preset 4 -svtav1-params tune=0"
goto KEYS_PROFILE
:NV_OPTS
set "FFKEYS=%FFKEYS% -preset p7 -rc vbr -rc-lookahead 32 -spatial-aq 1 -temporal-aq 1 -b_ref_mode 1"
if /i "%CODEC:~0,4%" == "h264" set "FFKEYS=%FFKEYS% -tune hq" & goto KEYS_PROFILE
set "FFKEYS=%FFKEYS% -tune uhq"
goto KEYS_PROFILE
:AMF_OPTS
:: GPU AMD: Не протестировано (нет железа) - тут только теория!
:: Переносим -preset в начало, чтобы он не затирал тонкие init-параметры
if /i "%CODEC:~0,4%" == "h264" set "FFKEYS=%FFKEYS% -preset 2" & goto AMF_INIT
set "FFKEYS=%FFKEYS% -preset 0"
:AMF_INIT
set "FFKEYS=%FFKEYS% -usage transcode -rc qvbr -preanalysis 1"
:: VBAQ есть только в H.264/HEVC. В AV1 его нет, там используется -aq_mode.
if /i not "%CODEC:~0,3%" == "av1" set "FFKEYS=%FFKEYS% -vbaq 1"
:: AV1: PROFILE был сброшен ранее, включаем режим адаптивного квантования
if /i "%CODEC:~0,3%" == "av1" set "FFKEYS=%FFKEYS% -aq_mode 1" & goto KEYS_PROFILE
:: 10-bit для HEVC включаем только при PROFILE=main10 (автомат теста GPU)
if /i "%PROFILE%" == "main10" set "FFKEYS=%FFKEYS% -bitdepth 10"
goto KEYS_PROFILE
:QSV_OPTS
:: GPU Intel: Не протестировано (нет железа) - тут только теория!
set "FFKEYS=%FFKEYS% -preset veryslow -low_power 0 -extbrc 1"
:: В av1_qsv нет rdo отсутствует , поэтому добавляем только для h264/hevc
if /i not "%CODEC:~0,3%" == "av1" set "FFKEYS=%FFKEYS% -rdo 1"
set "FFKEYS=%FFKEYS% -adaptive_i 1 -adaptive_b 1 -look_ahead_depth 100"
goto KEYS_PROFILE
:KEYS_PROFILE
:: Если профиль определён (h264/hevc) - добавляем. Для av1_ и libsvtav1 переменная пуста - ключ пропускается.
if defined PROFILE set "FFKEYS=%FFKEYS% -profile:v %PROFILE%"
:: H.264 для совместимости с плеерами ставим level не выше 4.1 (включает 1080@60)
if /i "%PROFILE%" == "high" set "FFKEYS=%FFKEYS% -level 4.1"
:: Видеофильтр -vf
if defined VF set "FFKEYS=%FFKEYS% %VF%"
:: Формат пикселей (8 bit yuv420p или 10 bit yuv420p10le)
if defined FF_PIXFMT set "FFKEYS=%FFKEYS% %FF_PIXFMT%"
:: Управление качеством CRF
set "FFCRF="
if not defined CRF goto KEYS_CRF_DONE
if /i "%CODEC:~-5%" == "nvenc" set "FFCRF=-cq %CRF%"
if /i "%CODEC:~-3%" == "amf" set "FFCRF=-qvbr_quality_level %CRF%"
if /i "%CODEC:~-3%" == "qsv" set "FFCRF=-global_quality %CRF%"
if /i "%CODEC:~0,3%" == "lib" set "FFCRF=-crf %CRF%"
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% CRF для %CODEC% установлен: %CRF%
:KEYS_CRF_DONE
if defined FFCRF set "FFKEYS=%FFKEYS% %FFCRF%"





:: === Блок: ПРОЧИЕ КЛЮЧИ ===
:: Порядок ключей ffmpeg КРИТИЧЕН для правильной работы GPU-кодеков. Должно быть так:
:: -hide_banner -c:v codec [кодек-специфичные init-параметры] [-profile:v] [-preset]
:: [-vf] [-pix_fmt] [-crf] [-tune] [-level] -c:a -c:s [-metadata lng]
:: Добавляем аудио если есть, устанавливаем язык аудио в "rus".
if not defined AUDIO_ARGS goto KEYS_AUD_DONE
set "FFKEYS=%FFKEYS% %AUDIO_ARGS% -metadata:s:a:0 language=rus"
if /i "%AUDIO_ARGS%" == "-c:a copy" goto KEYS_AUD_DONE
:: Чистим устаревшие аудио-теги только при перекодировании
set "FFKEYS=%FFKEYS% -metadata:s:a BPS= -metadata:s:a BPS-eng="
set "FFKEYS=%FFKEYS% -metadata:s:a NUMBER_OF_BYTES= -metadata:s:a NUMBER_OF_BYTES-eng="
:KEYS_AUD_DONE
:: Устанавливаем глобальный язык файла. Видеодорожку не трогаем -
:: ffmpeg делает это криво в MKV, а в MP4 пусть остаётся und/eng.
:: Язык видеодорожки устанавливается через mkvpropedit
:: Если включён full-range (COLOR_RANGE=1) - mkvpropedit также добавит цветовые метаданные.
:: Также копируем глобальные метаданные (Дата съемки, модель камеры, GPS)
set "FFKEYS=%FFKEYS% -metadata language=rus -map_metadata 0"
if not defined SUBS_TYPE goto KEYS_METADATA
if /i "%OUTPUT_EXT%" == "mkv" (
    set "FFKEYS=%FFKEYS% -c:s copy -metadata:s:s:0 language=rus"
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Копируем субтитры %SUBS_TYPE% в MKV отдельной дорожкой.
    goto KEYS_METADATA
)
:: Для MP4: добавляем быстрый старт воспроизведения (faststart) и теги стандарта Apple/Google
:: Если кодек HEVC - добавляем тег hvc1 для совместимости с Apple/Android
set "FFKEYS=%FFKEYS% -movflags +faststart+use_metadata_tags"
if /i "%CODEC:~0,4%" == "hevc" set "FFKEYS=%FFKEYS% -tag:v hvc1"
if /i "%CODEC%" == "libx265" set "FFKEYS=%FFKEYS% -tag:v hvc1"
:KEYS_METADATA
:: Удаляем старые видео-теги "битрейт" и "размер потока", если они есть.
:: FFmpeg копирует их из исходника, но при перекодировании значения неактуальны.
if not defined TAGBPS goto KEYS_DONE
set "FFKEYS=%FFKEYS% -metadata:s:v BPS= -metadata:s:v BPS-eng="
set "FFKEYS=%FFKEYS% -metadata:s:v NUMBER_OF_BYTES= -metadata:s:v NUMBER_OF_BYTES-eng="
>>"%LOG%" echo([CMD] %DATE% %TIME:~0,8% Удаляем "мусорный" metadata-тег BPS %TAGBPS% и сопутствующие ему.
:KEYS_DONE





:: === Блок: ОБРАБОТКА ===
:: CMD_LINE пишется в лог чисто для истории. 
:: Сам запуск идет через прямые переменные, иначе CMD ломает кавычки ключей.
set "CMD_LINE="%FFM%" -i "%FNF%" %FFKEYS% "%OUTPUT%""
>>"%LOG%" echo([CMD] %DATE% %TIME:~0,8% Строка кодирования: %CMD_LINE%
:: Запуск кодирования. FFmpeg пишет лог в stderr, а не в stdout - поэтому 2>LOG
:: Не запускаем через CMD_LINE, т.к. могут быть ошибки при спецсимволах.
"%FFM%" -i "%FNF%" %FFKEYS% "%OUTPUT%" 2>"%FFMPEG_LOG%"
:: Удаляем временный файл субтитров (если был):
if defined SUBS_FILE del "%OUTPUT_DIR%%SUBS_FILE%"
:: Проверяем, создан ли выходной видеофайл и ненулевой ли он
if not exist "%OUTPUT%" goto ENCODE_BAD
for %%F in ("%OUTPUT%") do set SIZE=%%~zF
if %SIZE% EQU 0 goto ENCODE_BAD
:: Если файл - MKV но не full-range - только меняем язык видео на русский
:: Остальные дорожки (аудио, субтитры) уже получили language=rus через ffmpeg -metadata (см. выше)
if /i "%OUTPUT_EXT%" == "mp4" goto ENCODE_DONE
if not defined COLOR_RANGE goto MKV_LANG_ONLY
:: Для MKV Full-range добавляем цветовые метаданные + меняем язык на русский
"%MKVP%" "%OUTPUT%" --edit track:v1 --set "language=rus" --set "colour-range=1" --set "color-matrix-coefficients=1">nul
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Full color range: добавляем в MKV теги colour-range и меняем язык видеодорожки на русский
goto ENCODE_DONE
:MKV_LANG_ONLY
"%MKVP%" "%OUTPUT%" --edit track:v1 --set "language=rus">nul
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% В MKV меняем язык видеодорожки на русский
:ENCODE_DONE
echo(Создан "%OUTPUT_NAME%.%OUTPUT_EXT%".
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Создан "%OUTPUT_NAME%.%OUTPUT_EXT%"
>>"%LOG%" echo(---
goto FILE_DONE
:ENCODE_BAD
if exist "%OUTPUT%" del "%OUTPUT%"
echo(FFmpeg не создал выходной файл или он нулевой. Cм. "%FFMPEG_LOG_NAME%"
echo(
>>"%LOG%" echo([ERROR] %DATE% %TIME:~0,8% FFmpeg завершился с ошибкой - см. "%FFMPEG_LOG_NAME%"
:FILE_DONE
echo(%DATE% %TIME:~0,8% Обработка "%FNWE%" завершена.
echo(Cм. логи в папке "%OUTPUT_DIR%logs".
echo(---
:: Выход из папки файла (вход был в начале метки START)
popd
:: Конвертируем OEM-лог в UTF-8:
:: %LOGE% - входной OEM-лог, %LOGU% - выходной UTF-8-лог.
:: Пути должны быть без кириллицы из-за разных кодировок CMD и VBS
:: Переходим в папку Logs
pushd "%OUTPUT_DIR%logs"
cscript //nologo "%CONV%" "%LOGE%" "%LOGU%" "cp866" "UTF-8"
del "%LOGE%"
if exist "%LOGN%" del "%LOGN%"
ren "%LOGU%" "%LOGN%"
popd
:: Переход к следующему файлу
:NEXT
shift
goto LOOP
:: Завершение работы скрипта
:END
echo(Все файлы обработаны.
echo(
set "EV=%temp%\%CMDN%-end%random%.vbs"
set "EMSG=Пакетный файл %CMDN% закончил работу."
chcp 1251 >nul
>"%EV%" echo(MsgBox "%EMSG%",,"%CMDN%"
chcp 866 >nul
cscript //nologo "%EV%"
del "%EV%"
:FASTEXIT
:: Удаляем VBS-хелперы и временные файлы
if defined CONV del "%CONV%"
if defined GLOG del "%GLOG%"
if defined DTMPV del "%DTMPV%"
pause