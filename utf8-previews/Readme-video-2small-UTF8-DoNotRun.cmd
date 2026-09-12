@echo off
rem Перекодирование видеофайлов в уменьшенный размер с высоким качеством
set "DO=Video recode script"
set "VRS=Froz %DO% v20.08.2026"

rem === Блок: ПРОВЕРКИ ===
title %DO%
echo(%VRS%
echo(Прервать кодирование - Ctrl-C.
echo(
set "CMDN=%~n0"
set "CONV="
set "GLOG="
set "STAMP="

rem Проверка наличия утилит
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
rem Создаем конвертер OEM в UTF-8 и наоборот (поменять местами ключи cp/utf)
rem Пример: cscript //nologo "%CONV%" "ВходнойФайл" "ВыходнойФайл" "cp866" "UTF-8"
set "CONV=%temp%\%CMDN%-conv.vbs"
>"%CONV%"  echo(Set a=WScript.Arguments:With CreateObject("ADODB.Stream")
>>"%CONV%" echo(.Type=2:.Open:.Charset=a(2):.LoadFromFile a(0):s=.ReadText:.Close
>>"%CONV%" echo(.Open:.Charset=a(3):.WriteText s:.SaveToFile a(1),2:End With

set "ININAME=%CMDN%.ini"
set "INIFULL=%~dp0%ININAME%"
if exist "%INIFULL%" goto SRC_CHK
rem Если ini нет - создаём OEM-шаблон во временной папке Windows.
set "IOEMW=%temp%\%CMDN%-inioemw.txt"
>"%IOEMW%" echo(; Настройки Froz Video recode script (%CMDN%). Подробнее см. в %CMDN%.txt
>>"%IOEMW%" echo(-------------------------------------------------------------------------------------
>>"%IOEMW%" echo(
>>"%IOEMW%" echo(; РАЗМЕР: 1 = уменьшить до 720p, пусто = до 1080p. Меньшие видео не увеличиваются.
>>"%IOEMW%" echo(SCALE=
>>"%IOEMW%" echo(
>>"%IOEMW%" echo(; КАЧЕСТВО (меньше = лучше): AV1_NVENC: 30-44, AV1_CPU: 26-42, 
>>"%IOEMW%" echo(; HEVC_NVENC: 27-36, HEVC_CPU(x265): 24-30. Пусто = авто-качество (обычно невысокое)
>>"%IOEMW%" echo(CRF=32
>>"%IOEMW%" echo(
>>"%IOEMW%" echo(; ТЕСТОВЫЙ РЕЖИМ: 1 = включить. Кодирует короткий фрагмент без звука и субтитров
>>"%IOEMW%" echo(; для быстрой оценки качества (CRF). Имя файла получит суффикс _TEST_имякодека[_CRFxx].
>>"%IOEMW%" echo(TEST=
>>"%IOEMW%" echo(; ДИАПАЗОН ТЕСТА (ОТ-ДО в секундах). Пример: 10-20 (с 10-й по 20-ю сек).
>>"%IOEMW%" echo(TESTLENGTH=10-20
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
>>"%IOEMW%" echo(; СУФФИКС готового файла (добавляется к имени исходника). При включенном TEST - игнорируется
>>"%IOEMW%" echo(NAME_APPEND=_sm
>>"%IOEMW%" echo(
>>"%IOEMW%" echo(; КАЛИБРОВКА СКОРОСТИ: Нужна для расчета времени (сек. кодирования / сек. видео) x 100.
>>"%IOEMW%" echo(SPEED_LIBSVTAV1=130
>>"%IOEMW%" echo(SPEED_LIBX265=150
>>"%IOEMW%" echo(SPEED_LIBX264=120
>>"%IOEMW%" echo(SPEED_NVENC=46
>>"%IOEMW%" echo(SPEED_AMF=50
>>"%IOEMW%" echo(SPEED_QSV=50
rem Конвертируем из temp в папку скрипта и удаляем временный файл
cscript //nologo "%CONV%" "%IOEMW%" "%INIFULL%" "cp866" "UTF-8"
del "%IOEMW%"
echo([!] Файл настроек не найден - создан новый шаблон.
echo(
goto HELP

:SRC_CHK
rem Проверка наличия входных файлов
if "%~1" == "" goto HELP
rem Проверяем первый аргумент на "папка", если да - выходим из ВСЕГО скрипта.
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
echo(%INIFULL%
echo(редактором для Unicode TXT-файлов, например Блокнотом.
echo(
echo(Затем перетяните или вставьте видеофайлы на этот файл.
echo(
goto FASTEXIT

:READ_INI
rem Делаем сброс переменных для будущих if defined и читаем переменные из ini
set "SCALE="
set "CRF="
set "TEST="
set "TESTLENGTH="
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
rem Конвертация UTF-8 в OEM во временную папку
set "IOEMR=%temp%\%CMDN%-inioemr.txt"
cscript //nologo "%CONV%" "%INIFULL%" "%IOEMR%" "UTF-8" "cp866"
rem Чтение ini-файла и удаление временного OEM
for /f "usebackq tokens=1* delims==" %%a in ("%IOEMR%") do (
    if "%%a"=="SCALE"           set "SCALE=%%b"
    if "%%a"=="CRF"             set "CRF=%%b"
    if "%%a"=="TEST"            set "TEST=%%b"
    if "%%a"=="TESTLENGTH"      set "TESTLENGTH=%%b"
    if "%%a"=="OUTPUT_EXT"      set "OUTPUT_EXT=%%b"
    if "%%a"=="AUDIO_ARGS"      set "AUDIO_ARGS=%%b"
    if "%%a"=="ROTATION"        set "ROTATION=%%b"
    if "%%a"=="CODEC"           set "CODEC=%%b"
    if "%%a"=="FPS"             set "FPS=%%b"
    if "%%a"=="NAME_APPEND"     set "NAME_APPEND=%%b"
    if "%%a"=="SPEED_LIBSVTAV1" set "SPEED_LIBSVTAV1=%%b"
    if "%%a"=="SPEED_LIBX265"   set "SPEED_LIBX265=%%b"
    if "%%a"=="SPEED_LIBX264"   set "SPEED_LIBX264=%%b"
    if "%%a"=="SPEED_NVENC"     set "SPEED_NVENC=%%b"
    if "%%a"=="SPEED_AMF"       set "SPEED_AMF=%%b"
    if "%%a"=="SPEED_QSV"       set "SPEED_QSV=%%b"
)
del "%IOEMR%"

rem Проверка ключевых user sets:
if not defined CODEC (
    echo([!] В %INIFULL%
    echo(не задан параметр CODEC - задайте. Выходим.
    echo(
    pause
    goto FASTEXIT
)
if not defined OUTPUT_EXT (
    set "OUTPUT_EXT=mkv"
    echo([!] В %INIFULL%
    echo(не задано расширение выходных файлов - принимаем: %OUTPUT_EXT%
    echo(
)
if not defined NAME_APPEND (
    set "NAME_APPEND=_sm"
    echo([!] В %INIFULL%
    echo(не задан суффикс выходных файлов - принимаем: %NAME_APPEND%
    echo(
)

rem Проверка: поддерживает ли GPU выбранный GPU-кодек. CPU - пропускаем
if /i "%CODEC:~0,3%" == "lib" goto SKIP_GCHK
rem По умолчанию целимся в 10-bit (p010le) для HEVC и AV1
set "FF_PIXFMT=-pix_fmt p010le"
rem Если выбран кодек семейства h264 - для него стартуем сразу с 8-bit (пустой фильтр)
if /i "%CODEC:~0,4%" == "h264" set "FF_PIXFMT="
rem Базовое имя для временных файлов (логи и скрипт перекодировки)
set "GLOG=%temp%\%CMDN%-gpuchk.log"
rem Сбрасываем флаг возможной второй попытки перед входом в TRY_GPU
set "GPU_RETRY="
:TRY_GPU
rem Создаём виртуальный пустой видеофайл длиной в 1 секунду и пытаемся сжать кодеком
"%FFM%" -hide_banner -v error -f lavfi -i nullsrc -c:v %CODEC% %FF_PIXFMT% -t 1 -f null - 2>"%GLOG%"
rem ffmpeg пишет лог в UTF-8, ошибки на латинице можно искать без конвертации в OEM. 
rem Если ошибка есть (строка найдена - findstr вернул 0) - проверка не пройдена.
rem Не отрывать строки findstr от строк errorlevel !
rem Проверка кривого имени кодека:
findstr /i /c:"Unknown encoder" "%GLOG%" >nul
if %ERRORLEVEL% EQU 0 (
    echo([ERROR] Имя кодека некорректно - проверьте INI-файл. Выходим.
    echo(
    type "%GLOG%"
    echo(
    goto FASTEXIT
)
rem Проверка на отсутствие аппаратной поддержки GPU:
findstr /i /c:"Error while opening encoder" "%GLOG%" >nul
set "GPU_ERR=%ERRORLEVEL%"
rem Если ошибки нет (строка Error НЕ найдена - findstr вернул 1) - проверка пройдена
if %GPU_ERR% EQU 1 goto SKIP_GCHK
if defined GPU_RETRY goto GPU_NOT_SUPPORTED
rem 8 бит для AV1 не проверяем - нет GPU которые умеют AV1-8 но не умеют AV1-10
if /i not "%CODEC:~0,4%" == "hevc" goto GPU_NOT_SUPPORTED
rem Если мы тут, значит упал HEVC 10-битный режим. Пробуем 8 бит
set "GPU_RETRY=1"
set "FF_PIXFMT="
echo([INFO] GPU не поддерживает 10-bit. Пробуем 8-bit...
goto TRY_GPU
:GPU_NOT_SUPPORTED
rem Если мы здесь - это окончательный сбой - упал H.264, AV1, 8-битный HEVC
echo([ERROR] Видеокарта или её драйвер не поддерживает выбранный GPU-кодек.
echo(Обновите видеокарту и драйвер или смените кодек в настройках. Выходим.
echo(
type "%GLOG%"
echo(

:FASTEXIT
rem Удаляем VBS-хелперы и временные файлы и завершаем работу
rem Этот блок выхода здесь, т.к. иначе ошибка GPU не видит его (ошибка cmd-парсера)
if defined CONV del "%CONV%"
if defined GLOG del "%GLOG%"
if defined STAMP del "%STAMP%"
pause
exit /b

:SKIP_GCHK






rem Глобальные set перед LOOP
rem Все подаваемые на вход файлы всегда лежат в одной папке. ВАЖНО: В конце dp1 есть слэш
set "OUTPUT_DIR=%~dp1"
rem Сохраняем исходные user-значения которые могут быть перезаписаны при работе
set "INI_CRF=%CRF%"
set "INI_AUDIO_ARGS=%AUDIO_ARGS%"
set "INI_FPS=%FPS%"
set "INI_OUTPUT_EXT=%OUTPUT_EXT%"
set "AUDIO_DEFAULT=-c:a copy"
rem Создаем VBS-хелпер штампа времени, не зависящий от локали - формат ГГГГ-ММ-ДД_ЧЧММСС
set "STAMP=%temp%\%CMDN%-STAMP.vbs"
>"%STAMP%"  echo(s=Year(Now)^&"-"^&Right("0"^&Month(Now),2)^&"-"
>>"%STAMP%" echo(s=s^&Right("0"^&Day(Now),2)
>>"%STAMP%" echo(s=s^&"_"^&Right("0"^&Hour(Now),2)^&Right("0"^&Minute(Now),2)
>>"%STAMP%" echo(s=s^&Right("0"^&Second(Now),2):WScript.Echo s
rem Для тестовых сжатий. Сброс FF_SEEK обязательно перед if - т.к. он есть в строке ffmpeg
set "FF_SEEK="
if not defined TEST goto LOOP
if not defined TESTLENGTH set "TESTLENGTH=10-20"
for /f "tokens=1,2 delims=-" %%s in ("%TESTLENGTH%") do set "FF_SEEK=-ss %%s -to %%t"





rem === Блок: СТАРТ ===
:LOOP
rem Восстанавливаем ini-значения для нового файла
set "OUTPUT_EXT=%INI_OUTPUT_EXT%"
set "AUDIO_ARGS=%INI_AUDIO_ARGS%"
set "FPS=%INI_FPS%"
set "CRF=%INI_CRF%"
set "TEST_STEP="
rem Записываем имя файла в переменные чтобы %1 не сломалось в процессе
set "FNF=%~1"
set "FNN=%~n1"
set "FNWE=%~nx1"
set "EXT=%~x1"
rem Собираем имя и путь к готовому файлу, учитываем режим ТЕСТ
if defined TEST set "NAME_APPEND=_TEST_%CODEC%"
set "OUTPUT_NAME=%FNN%%NAME_APPEND%"
set "OUTPUT=%OUTPUT_DIR%%OUTPUT_NAME%.%OUTPUT_EXT%"
rem Если больше нет файлов - выходим
if not defined FNF goto END
set "ATTR=%~a1"
if /i not "%ATTR:~0,1%"=="d" goto START
echo(%FNN% - папка, пропускаем.
goto NEXT
:START
rem Запрашиваем текущий штамп времени из VBS-хелпера TV
for /f %%t in ('cscript //nologo "%STAMP%"') do set "DTMP=%%t"
rem Имена и папка логов (используем только полные пути)
set "LOG=%OUTPUT_DIR%logs\%DTMP%-oem.txt"
set "LOGFINAL=%OUTPUT_DIR%logs\%FNN%%NAME_APPEND%-log.txt"
rem Совместить логи CMD+FFMpeg в один не получится, так как ffmpeg выводит в UTF8, а CMD - в OEM
set "FFMPEG_LOG_NAME=%OUTPUT_NAME%-log_ffmpeg.txt"
set "FFMPEG_LOG=%OUTPUT_DIR%logs\%FFMPEG_LOG_NAME%"
rem Создаём папку для логов
if not exist "%OUTPUT_DIR%logs" md "%OUTPUT_DIR%logs"
rem Проверяем что конечный файл уже существует и ненулевого размера
if not exist "%OUTPUT%" goto DONE_SIZE_CHK
for %%F in ("%OUTPUT%") do set SIZE=%%~zF
if %SIZE% GTR 0 goto FEXIST
del "%OUTPUT%"
goto DONE_SIZE_CHK
:FEXIST
echo("%OUTPUT_NAME%" уже существует, пропускаем.
echo(
if exist "%LOG%" del "%LOG%"
goto NEXT
:DONE_SIZE_CHK
title Обработка %FNWE%...
if defined TEST title Обработка %FNWE% - включен ТЕСТ-режим!...
echo(%DATE% %TIME:~0,8% Начата обработка "%FNWE%"...
>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Начата обработка "%FNWE%"...





rem === Блок: ИЗВЛЕЧЕНИЕ ===
rem ffprobe извлекает: размеры, pix_fmt, чересстрочность, FPS (база/среднее),
rem поворот, длительность, "мусорные" видеотеги (для удаления позже).
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
rem Если найден видео-тег BPS - ставим флаг
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
rem Проверяем, что первый параметр "ширина кадра" извлечен и не равен нулю. Иначе это не видеофайл.
if not defined SRC_W goto BADFILE
if %SRC_W% EQU 0 goto BADFILE
rem Извлекаем кодек аудиодорожки чтобы решить что с ним делать дальше
set "FFP_ATMP=%temp%\%CMDN%-ffprobe-audio-%random%.txt"
rem Ключ :nk=1 отбросит текст "codec_name="
"%FFP%" -v error -select_streams a:0 -show_entries stream=codec_name -of default=nw=1:nk=1 "%FNF%" >"%FFP_ATMP%"
set /p "AUDIO_CODEC=" <"%FFP_ATMP%"
del "%FFP_ATMP%"
goto EXTRACT_DONE
:BADFILE
echo([ERROR] Не получилось извлечь параметры видео. Файл пропущен.
echo(
>>"%LOG%" echo([ERROR] %DATE% %TIME:~0,8% Не получилось извлечь параметры видео. Файл пропущен.
goto FILE_DONE
:EXTRACT_DONE





rem === Блок: ЦВЕТ ===
rem Блок должен быть перед блоком ПОВОРОТ, так как здесь может измениться контейнер
rem а в MP4 может быть тег Rotation.
rem yuvj420p = Full-Range. Ставим colour-range=1 через mkvpropedit
rem В MP4 он не работает, поэтому такие файлы принудительно уходят в MKV.
set "COLOR_RANGE="
if /i "%SRC_PIXFMT%" == "yuvj420p" set "COLOR_RANGE=1"
rem Если не Full Range или уже MKV - пропускаем изменения
if not defined COLOR_RANGE goto COLOR_DONE
if /i "%OUTPUT_EXT%" == "mkv" goto COLOR_DONE
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Для записи metadata full color с помощью mkvpropedit - меняем расширение на mkv
rem Меняем расширение на mkv для full-range, пересчитываем OUTPUT
set "OUTPUT_EXT=mkv"
set "OUTPUT=%OUTPUT_DIR%%OUTPUT_NAME%.%OUTPUT_EXT%"
:COLOR_DONE





rem === Блок: ПОВОРОТ ===
rem Этот блок должен быть после блока ЦВЕТ и перед блоком МАСШТАБ
rem 1. Если есть тег rotate в MP4/MOV - ffmpeg применит его сам (autorotate),
rem    мы только меняем SRC_H = SRC_W для блока МАСШТАБ.
rem 2. Если ROTATION задан юзером - добавляем transpose. Для кодека *qsv - пишем варнинг и игнорируем.
rem SRC_H, SRC_W и ROTATION_TAG извлечены ранее
set "ROTATION_FILTER="
rem Ожидаем только теги кратные 90: 90, 270 и -90. Никогда не встречал видео с тегом 180.
if defined ROTATION_TAG (
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Применён тег Rotate из файла: %ROTATION_TAG%
    set "SRC_H=%SRC_W%"
)
rem Обрабатываем User-ROTATION
if not defined ROTATION goto ROTATE_DONE
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Указан дополнительный поворот User-Rotation: %ROTATION%. Добавляем ключ transpose.
if "%ROTATION%" == "-90" set "ROTATION_FILTER=transpose=1" & set "SRC_H=%SRC_W%" & goto ROTATE_DONE
if "%ROTATION%" == "90" set "ROTATION_FILTER=transpose=2" & set "SRC_H=%SRC_W%" & goto ROTATE_DONE
rem при 180 - размеры не меняются - SRC_H остаётся как есть
if "%ROTATION%" == "180" set "ROTATION_FILTER=transpose=1,transpose=1"
:ROTATE_DONE





rem === Блок: МАСШТАБ ===
rem Масштабируем если "SCALE=1": до 720p, если высота > 720. "SCALE=": до 1080p, если есть transpose и высота > 1080
set "SCALE_EXPR="
rem Устанавливаем значения по умолчанию (для случая, когда SCALE не задан)
set "SCL_LIMIT=1080" & set "SCL_PREFIX=SCALE не задан"
rem Если SCALE определён в ini - переопределяем значения
if defined SCALE set "SCL_LIMIT=720" & set "SCL_PREFIX=Задан SCALE=1"
rem Единая проверка высоты
if %SRC_H% LEQ %SCL_LIMIT% (
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% %SRC_H% - %SCL_LIMIT% или менее - не масштабируем.
    goto SCALE_DONE
)
rem Масштабирование требуется
set "SCALE_EXPR=scale=-2:%SCL_LIMIT%"
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% %SRC_H% - масштабируем до %SCL_LIMIT%.
:SCALE_DONE





rem === Блок: ЧАСТОТА ===
rem Цель: привести VFR к CFR - для совместимости с HW-кодеками и плеерами/ТВ.
rem VFR определяем по несовпадению r_frame_rate (база) и avg_frame_rate (среднее).
rem FIELD_ORDER, R_FPS, A_FPS извлечены ранее. Для interlaced FPS ставим всегда.
rem Сброс MAX_FPS/IS_INTERLACED здесь заранее - нужны для if defined в блоке ВРЕМЯ.
set "MAX_FPS="
set "IS_INTERLACED="
rem Если FPS задан вручную - выходим сразу. Это отключает деинтерлейсинг bwdif 50p/60p
rem Если юзер вручную ставит FPS=25/30 - получит 25p/30p без bwdif.
if defined FPS (
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% FPS задан принудительно: %FPS%.
    goto FPS_DONE
)
rem Если видео чересстрочное - ставим FPS по умолчанию и выходим
if /i "%FIELD_ORDER%" == "unknown" (
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% FIELD_ORDER не определён - "unknown". Считаем видео progressive.
    goto HANDLE_PROGRESSIVE
)
if /i not "%FIELD_ORDER%" == "progressive" goto HANDLE_INTERLACED
:HANDLE_PROGRESSIVE
rem Дальше может быть только progressive видео. Всегда извлекаем MAX_FPS в т.ч. для блока ВРЕМЯ
set "MI_TMP=%temp%\%CMDN%-mi-fps-%random%.txt"
"%MI%" --Inform=Video;%%FrameRate%% "%FNF%" >"%MI_TMP%"
set /p MAX_FPS= <"%MI_TMP%"
del "%MI_TMP%"
if not defined MAX_FPS (
    >>"%LOG%" echo([WARNING] %DATE% %TIME:~0,8% Не удалось извлечь max frame rate из mediainfo
    goto FPS_DONE
)
rem Оставляем только целые значения FPS
for /f "tokens=1 delims=." %%m in ("%MAX_FPS%") do set "MAX_FPS=%%m"
rem Если r_frame_rate == avg_frame_rate - это CFR, ничего не делаем
if "%R_FPS%" == "%A_FPS%" goto FPS_DONE
rem Progressive + VFR - определяем MAX_FPS и ставим стандартные CFR
if %MAX_FPS% GTR 50 set "FPS=60" & goto REPORT_FPS
rem Если VFR-видео содержит фрагменты с высоким FPS (например, slow-mo >35 к/с),
rem выбираем 50 fps вместо 30, чтобы сохранить плавность.
if %MAX_FPS% GTR 40 set "FPS=50" & goto REPORT_FPS
if %MAX_FPS% GTR 28 set "FPS=30" & goto REPORT_FPS
if %MAX_FPS% GTR 24 set "FPS=25" & goto REPORT_FPS
rem Fallback-FPS
set "FPS=24"
:REPORT_FPS
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Найден переменный FPS. Max Frame Rate: %MAX_FPS%. Установлен FPS: %FPS%
goto FPS_DONE
:HANDLE_INTERLACED
rem Чересстрочное видео - по умолчанию 50p (PAL) или 60p (NTSC 480i)
rem FPS здесь нужен для расчёта времени и выбора режима деинтерлейса
set "IS_INTERLACED=1"
set "FPS=50"
if %SRC_H% == 480 set "FPS=60"
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Обнаружено чересстрочное видео. Установлен FPS по умолчанию: %FPS%
:FPS_DONE





rem === Блок: ВРЕМЯ ===
rem Блок должен быть после блока ЧАСТОТА
if defined TEST echo(Включен режим тестового сжатия!& goto TIME_DONE
rem Определяем базовую скорость кодирования (SPEED_CENTI = секунд кодирования на 100 сек видео)
if "%LENGTH_SECONDS%" == "N/A" (
    echo(Не получилось извлечь длину видео, расчёт времени кодирования пропущен. Продолжаем кодирование.
    goto TIME_DONE
)
rem Определяем базовую скорость (сек кодирования на 100 сек видео)
set "SPEED_CENTI="
if /i "%CODEC%" == "libsvtav1" set "SPEED_CENTI=%SPEED_LIBSVTAV1%"
if /i "%CODEC%" == "libx265" set "SPEED_CENTI=%SPEED_LIBX265%"
if /i "%CODEC%" == "libx264" set "SPEED_CENTI=%SPEED_LIBX264%"
if /i "%CODEC:~-5%" == "nvenc" set "SPEED_CENTI=%SPEED_NVENC%"
if /i "%CODEC:~-3%" == "amf"   set "SPEED_CENTI=%SPEED_AMF%"
if /i "%CODEC:~-3%" == "qsv"   set "SPEED_CENTI=%SPEED_QSV%"
if defined SPEED_CENTI goto TIME_VARS_SET
rem Fallback если кодек не найден в INI
set "SPEED_CENTI=30"
if /i "%CODEC:~0,3%" == "lib" set "SPEED_CENTI=130"
:TIME_VARS_SET
rem Определяем рабочий FPS для расчёта (связка с блоком ЧАСТОТА)
rem Приоритет 1: Целевой FPS после VFR/Interlaced или ручного ввода юзера (%FPS%)
rem Приоритет 2: Родной стабильный фреймрейт из MediaInfo (%MAX_FPS%)
rem Приоритет 3: Заглушка 30 FPS, если переменные пусты
set "FPS_FOR_TIME=30"
if defined MAX_FPS set "FPS_FOR_TIME=%MAX_FPS%"
if defined FPS set "FPS_FOR_TIME=%FPS%"
rem Накидываем +25% для 50-60 FPS, иначе оставляем как есть
if %FPS_FOR_TIME% GTR 35 set /a "SPEED_CENTI=(SPEED_CENTI * 125) / 100"
rem Скидываем -20% для 720p и ниже
if %SRC_H% LEQ 720 set /a "SPEED_CENTI=(SPEED_CENTI * 80) / 100"
rem Добавляем психологический запас 10%
set /a "SPEED_CENTI=(SPEED_CENTI * 110) / 100"
rem Расчет примерного времени кодирования в секундах (точка защищает от пустой переменной)
for /f "tokens=1 delims=." %%a in ("%LENGTH_SECONDS%.") do set /a "ENCODE_SECONDS=(%%a * SPEED_CENTI) / 100"
rem Гарантируем минимум 1 секунду
if %ENCODE_SECONDS% EQU 0 set "ENCODE_SECONDS=1"
rem Переводим секунды в минуты:секунды
set /a "MINUTES=ENCODE_SECONDS / 60"
set /a "SECONDS=ENCODE_SECONDS %% 60"
if %SECONDS% LSS 10 set "SECONDS=0%SECONDS%"
echo(Примерное время кодирования: %MINUTES% минут %SECONDS% секунд.
:TIME_DONE







rem === Блок: ПРОФИЛЬ ===
rem 1. Базовый дефолт для 8-bit (Упавший HEVC автоматом получает main и yuv420p)
set "PROFILE=main"
set "FF_PIXFMT=-pix_fmt yuv420p"
rem 2. Если тест GPU зафиксировал откат HEVC в 8-бит - база уже настроена идеально, уходим
if defined GPU_RETRY goto PROFILE_DONE
rem 3. Если это H.264 (GPU или CPU) - меняем профиль на high (формат yuv420p уже стоит) и уходим
if /i "%CODEC:~0,4%" == "h264" set "PROFILE=high" & goto PROFILE_DONE
if /i "%CODEC%" == "libx264" set "PROFILE=high" & goto PROFILE_DONE
rem 4. Для всех остальных (современных 10-битных) кодеков включаем апгрейд на main10 и p010le
set "PROFILE=main10"
set "FF_PIXFMT=-pix_fmt p010le"
rem 5. Корректировка формата пикселей для CPU-версий (они используют yuv420p10le вместо p010le)
if /i "%CODEC:~0,3%" == "lib" set "FF_PIXFMT=-pix_fmt yuv420p10le"
rem 6. Сброс профиля для AV1 (CPU и GPU - драйвер выставит сам, уходим)
if /i "%CODEC:~0,3%" == "av1" set "PROFILE=" & goto PROFILE_DONE
if /i "%CODEC%" == "libsvtav1" set "PROFILE="
:PROFILE_DONE
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Для %CODEC% установлен формат пикселей: %FF_PIXFMT%






rem === Блок: АУДИО ===
if defined TEST set "AUDIO_ARGS=-an" & goto AUDIO_DONE
rem Базовый дефолт (закрывает сценарии копирования для MP4 и MKV, а также пустой ini)
set "AUDIO_ARGS=%AUDIO_DEFAULT%"
rem Если звука в оригинале нет - обнуляем и уходим
if not defined AUDIO_CODEC set "AUDIO_ARGS=" & goto AUDIO_DONE
rem Если юзер удалил кодек в ini - copy уже задан - уходим
if not defined INI_AUDIO_ARGS goto AUDIO_DONE
rem --- СЦЕНАРИЙ: КОНТЕЙНЕР MP4 ---
if /i "%OUTPUT_EXT%" == "mkv" goto AUDIO_MKV
rem Если родной звук уже AAC - копируется, уходим
if /i "%AUDIO_CODEC%" == "aac" goto AUDIO_DONE
rem Если юзер сам вручную вписал ключевое слово "aac" в ini - отдаем его кастомные ключи и уходим
rem В строке ниже несмотря на "if not" - работает "если в INI_AUDIO_ARGS найден AAC то..."
rem Но поиск сработает только если set не пустой, поэтому раньше была нужна проверка на непустое
if not "%INI_AUDIO_ARGS%" == "%INI_AUDIO_ARGS:aac=%" set "AUDIO_ARGS=%INI_AUDIO_ARGS%" & goto AUDIO_DONE
rem Во всех остальных случаях для MP4 (например в ini дефолтный Opus) - принудительно ставим AAC 192k
set "AUDIO_ARGS=-c:a aac -b:a 192k -ac 2"
>>"%LOG%" echo([WARNING] %DATE% %TIME:~0,8% В ini указан не AAC. Для MP4 принудительно применен AAC-192k.
goto AUDIO_DONE
:AUDIO_MKV
rem --- СЦЕНАРИЙ: КОНТЕЙНЕР MKV ---
rem В MKV если родной звук Opus - копия уже стоит, уходим
if /i "%AUDIO_CODEC%" == "opus" goto AUDIO_DONE
rem В остальных случаях для MKV (например, исходник MP3) - берём из ini
set "AUDIO_ARGS=%INI_AUDIO_ARGS%"
:AUDIO_DONE
if /i "%AUDIO_ARGS%" == "%AUDIO_DEFAULT%" (
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Аудиодорожка: %AUDIO_CODEC%, контейнер: %OUTPUT_EXT%. Копируем без перекодирования.
)





rem === Блок: СУБТИТРЫ ===
if defined TEST goto SUBS_DONE
rem Должен быть перед блоком ВИДЕОФИЛЬТР. Обрабатывается только первая дорожка субтитров.
set "SUBS_TYPE="
set "SUBS_FILE="
set "FFP_STMP=%temp%\%CMDN%-ffprobe-subs-%random%.txt"
rem Ключ :nk=1 отбросит текст "codec_name="
"%FFP%" -v error -select_streams s:0 -show_entries stream=codec_name -of default=nw=1:nk=1 "%FNF%" >"%FFP_STMP%"
set /p "SUBS_TYPE=" <"%FFP_STMP%"
del "%FFP_STMP%"
rem Если субтитров нет или вывод в MKV - извлечение не требуется (MKV копирует дорожки напрямую)
if not defined SUBS_TYPE goto SUBS_DONE
if /i "%OUTPUT_EXT%"=="mkv" goto SUBS_DONE
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Найдены субтитры %SUBS_TYPE%. Обрабатывается только первая дорожка.
rem Для MP4 поддерживаем вшивание только srt и ass
if /i "%SUBS_TYPE%"=="srt" set "SUBS_FILE=tempsubs%random%.srt" & goto SUBS_EXTRACT
if /i "%SUBS_TYPE%"=="ass" set "SUBS_FILE=tempsubs%random%.ass" & goto SUBS_EXTRACT
>>"%LOG%" echo([WARNING] %DATE% %TIME:~0,8% Тип субтитров %SUBS_TYPE% не поддерживается для вшивания в MP4. Пропускаем.
goto SUBS_DONE
:SUBS_EXTRACT
"%FFM%" -hide_banner -v error -i "%FNF%" -c:s copy "%OUTPUT_DIR%%SUBS_FILE%" 2>nul
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Извлечён временный файл субтитров %SUBS_FILE%.
:SUBS_DONE






rem === Блок: ВИДЕОФИЛЬТР ===
rem Этот блок должен быть после блоков МАСШТАБ, ПОВОРОТ, ЧАСТОТА
rem Порядок фильтров: scale -> transpose -> deinterlace -> fps
rem   - scale до поворота (размеры), deinterlace после (ориентация), fps в конце (VFR)
set "FILTER_LIST="
set "SKIP_FPS_FILTER="
set "VF="
rem Собираем базовые фильтры геометрии
rem Намеренно добавляем запятую перед каждым фильтром - в конце отрежем первый символ (%FL:~1%)
rem Масштабирование, если не пропущен и задан
if defined SCALE_EXPR set "FILTER_LIST=%FILTER_LIST%,%SCALE_EXPR%"
rem Поворот, если задан
if defined ROTATION_FILTER set "FILTER_LIST=%FILTER_LIST%,%ROTATION_FILTER%"
rem Обработка деинтерлейса (только для интерлейсного видео)
if not defined IS_INTERLACED goto PROCESS_FPS
rem По умолчанию: bwdif=1 - 50i->50p, 60i->60p - сохранит плавность
set "INTCMD=bwdif=1"
rem FPS тут всегда определён. Для interlaced либо авто 50/60,
rem либо явно задан юзером - доп. проверка на defined FPS не нужна.
rem При юзер-FPS 25/30 - bwdif=0 и skip FPS, чтобы избежать артефактов
rem от bwdif=1,fps=25 (50 кадров и отбросить каждый второй)
if %FPS% LEQ 30 set "INTCMD=bwdif=0" & set "SKIP_FPS_FILTER=1"
set "FILTER_LIST=%FILTER_LIST%,%INTCMD%"
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Применён деинтерлейсинг: %INTCMD%
:PROCESS_FPS
rem Если установлен флаг пропуска (из-за bwdif=0) - не добавляем фильтр fps
if defined SKIP_FPS_FILTER goto PROCESS_SUBS
rem Если FPS вообще не задан - не добавляем
if not defined FPS goto PROCESS_SUBS
set "FILTER_LIST=%FILTER_LIST%,fps=%FPS%"
:PROCESS_SUBS
rem Hardburn субтитров в MP4
if not defined SUBS_FILE goto VF_COMPILE
set "FILTER_LIST=%FILTER_LIST%,subtitles=%SUBS_FILE%"
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Для MP4 вшиваем субтитры %SUBS_TYPE% в видеоряд (hardburn).
:VF_COMPILE
rem Финальная сборка -vf: (:~1%) отрезает лидирующую запятую от склейки ,scale,fps
if defined FILTER_LIST set "VF=-vf "%FILTER_LIST:~1%""






rem === Блок: ВИДЕОКЛЮЧИ ===
rem Порядок ключей ffmpeg КРИТИЧЕН для правильной работы GPU-кодеков. Должно быть так:
rem -hide_banner -c:v codec [-preset] [кодек-специфичные init-параметры] [-tune] [-profile:v]
rem [-vf] [-pix_fmt] [-crf] [-level] -c:a -c:s [-metadata lng]
set "FFKEYS=-hide_banner -c:v %CODEC%"
if /i "%CODEC:~-5%" == "nvenc" goto NV_OPTS
if /i "%CODEC:~-3%" == "amf" goto AMF_OPTS
if /i "%CODEC:~-3%" == "qsv" goto QSV_OPTS
rem Мы в CPU libx-кодеках
if /i "%CODEC:~-3%" == "av1" set "FFKEYS=%FFKEYS% -preset 4 -svtav1-params tune=0" & goto KEYS_PROFILE
set "FFKEYS=%FFKEYS% -preset slow"
goto KEYS_PROFILE
:NV_OPTS
set "FFKEYS=%FFKEYS% -preset p7 -rc vbr -rc-lookahead 32 -spatial-aq 1 -temporal-aq 1 -b_ref_mode 1"
if /i "%CODEC:~0,4%" == "h264" set "FFKEYS=%FFKEYS% -tune hq" & goto KEYS_PROFILE
set "FFKEYS=%FFKEYS% -tune uhq"
goto KEYS_PROFILE
:AMF_OPTS
rem GPU AMD: Не протестировано (нет железа) - тут только теория!
rem Переносим -preset в начало, чтобы он не затирал тонкие init-параметры
if /i "%CODEC:~0,4%" == "h264" set "FFKEYS=%FFKEYS% -preset 2" & goto AMF_INIT
set "FFKEYS=%FFKEYS% -preset 0"
:AMF_INIT
set "FFKEYS=%FFKEYS% -usage transcode -rc qvbr -preanalysis 1"
rem VBAQ есть только в H.264/HEVC. В AV1 его нет, там используется -aq_mode.
if /i not "%CODEC:~0,3%" == "av1" set "FFKEYS=%FFKEYS% -vbaq 1"
rem AV1: PROFILE был сброшен ранее, включаем режим адаптивного квантования
if /i "%CODEC:~0,3%" == "av1" set "FFKEYS=%FFKEYS% -aq_mode 1" & goto KEYS_PROFILE
rem 10-bit для HEVC включаем только при PROFILE=main10 (автомат теста GPU)
if /i "%PROFILE%" == "main10" set "FFKEYS=%FFKEYS% -bitdepth 10"
goto KEYS_PROFILE
:QSV_OPTS
rem GPU Intel: Не протестировано (нет железа) - тут только теория!
set "FFKEYS=%FFKEYS% -preset veryslow -low_power 0 -extbrc 1"
rem В av1_qsv параметр rdo отсутствует , поэтому добавляем только для h264/hevc
if /i not "%CODEC:~0,3%" == "av1" set "FFKEYS=%FFKEYS% -rdo 1"
rem Если look_ahead_depth 100 или сам режим упадут на старом CPU - отключить look_ahead (ставим 0)
set "FFKEYS=%FFKEYS% -adaptive_i 1 -adaptive_b 1 -look_ahead 1 -look_ahead_depth 100"
goto KEYS_PROFILE
:KEYS_PROFILE
rem Если профиль определён (h264/hevc) - добавляем. Для av1_ и libsvtav1 переменная пуста - ключ пропускается.
if defined PROFILE set "FFKEYS=%FFKEYS% -profile:v %PROFILE%"
rem H.264 для совместимости с плеерами ставим level не выше 4.1 (включает 1080@60)
if /i "%PROFILE%" == "high" set "FFKEYS=%FFKEYS% -level 4.1"
rem Видеофильтр -vf
if defined VF set "FFKEYS=%FFKEYS% %VF%"
rem Формат пикселей (8 bit yuv420p или 10 bit yuv420p10le)
if defined FF_PIXFMT set "FFKEYS=%FFKEYS% %FF_PIXFMT%"
rem Сохраняем готовую базу видеоключей до входа в CRF
set "FFKEYS_NOCRF=%FFKEYS%"
rem Обработка тестовых сжатий
if not defined TEST goto CRFSET
if not defined CRF goto CRFSET
set "TEST_STEP=1"
:TEST_CRFSTEPS
rem ЦИКЛ ТЕСТОВЫХ СЖАТИЙ: TEST_STEP=1: базовый CRF (уже закодирован до входа сюда)
rem TEST_STEP=2: CRF-2 (лучше качество), TEST_STEP=3: CRF+2 (хуже качество, меньше размер), TEST_STEP=4: выход из цикла
if %TEST_STEP% EQU 2 set /a CRF=INI_CRF-2
if %TEST_STEP% EQU 3 set /a CRF=INI_CRF+2
set "NAME_APPEND=_TEST_%CODEC%_CRF%CRF%"
set "OUTPUT_NAME=%FNN%%NAME_APPEND%"
set "OUTPUT=%OUTPUT_DIR%%OUTPUT_NAME%.%OUTPUT_EXT%"
:CRFSET
rem Управление качеством CRF/CQ
set "FFCRF="
if not defined CRF goto KEYS_CRF_DONE
if /i "%CODEC:~-5%" == "nvenc" set "FFCRF=-cq %CRF%"
if /i "%CODEC:~-3%" == "amf" set "FFCRF=-qvbr_quality_level %CRF%"
if /i "%CODEC:~-3%" == "qsv" set "FFCRF=-global_quality %CRF%"
if /i "%CODEC:~0,3%" == "lib" set "FFCRF=-crf %CRF%"
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% CRF для %CODEC% установлен: %CRF%
:KEYS_CRF_DONE
if defined FFCRF set "FFKEYS=%FFKEYS_NOCRF% %FFCRF%"





rem === Блок: ПРОЧИЕ КЛЮЧИ ===
rem Продолжение сборки FFKEYS. Порядок между -c:a/-c:s/-metadata менее критичен,
rem чем в блоке ВИДЕОКЛЮЧИ выше, но не переставляй -movflags - он должен быть после -c:s.
rem Добавляем аудио если есть, устанавливаем язык аудио в "rus".
if defined TEST set "FFKEYS=%FFKEYS% %AUDIO_ARGS%" & goto KEYS_DONE
if not defined AUDIO_ARGS goto KEYS_AUD_DONE
set "FFKEYS=%FFKEYS% %AUDIO_ARGS% -metadata:s:a:0 language=rus"
if /i "%AUDIO_ARGS%" == "-c:a copy" goto KEYS_AUD_DONE
rem Чистим устаревшие аудио-теги только при перекодировании
set "FFKEYS=%FFKEYS% -metadata:s:a BPS= -metadata:s:a BPS-eng="
set "FFKEYS=%FFKEYS% -metadata:s:a NUMBER_OF_BYTES= -metadata:s:a NUMBER_OF_BYTES-eng="
:KEYS_AUD_DONE
rem Устанавливаем глобальный язык файла. Видеодорожку не трогаем -
rem ffmpeg делает это криво в MKV, а в MP4 пусть остаётся und/eng.
rem Язык видеодорожки устанавливается через mkvpropedit
rem Если включён full-range (COLOR_RANGE=1) - mkvpropedit также добавит цветовые метаданные.
rem Также копируем глобальные метаданные (Дата съемки, модель камеры, GPS)
set "FFKEYS=%FFKEYS% -metadata language=rus -map_metadata 0"
if not defined SUBS_TYPE goto KEYS_METADATA
if /i "%OUTPUT_EXT%" == "mkv" (
    set "FFKEYS=%FFKEYS% -c:s copy -metadata:s:s:0 language=rus"
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Копируем субтитры %SUBS_TYPE% в MKV отдельной дорожкой.
    goto KEYS_METADATA
)
rem Для MP4: добавляем быстрый старт воспроизведения (faststart) и теги стандарта Apple/Google
rem Если кодек HEVC - добавляем тег hvc1 для совместимости с Apple/Android
set "FFKEYS=%FFKEYS% -movflags +faststart+use_metadata_tags"
if /i "%CODEC:~0,4%" == "hevc" set "FFKEYS=%FFKEYS% -tag:v hvc1"
if /i "%CODEC%" == "libx265" set "FFKEYS=%FFKEYS% -tag:v hvc1"
:KEYS_METADATA
rem Удаляем старые видео-теги "битрейт" и "размер потока", если они есть.
rem FFmpeg копирует их из исходника, но при перекодировании значения неактуальны.
if not defined TAGBPS goto KEYS_DONE
set "FFKEYS=%FFKEYS% -metadata:s:v BPS= -metadata:s:v BPS-eng="
set "FFKEYS=%FFKEYS% -metadata:s:v NUMBER_OF_BYTES= -metadata:s:v NUMBER_OF_BYTES-eng="
>>"%LOG%" echo([CMD] %DATE% %TIME:~0,8% Удаляем "мусорный" metadata-тег BPS %TAGBPS% и сопутствующие ему.
:KEYS_DONE







rem === Блок: ОБРАБОТКА ===
rem CMD_LINE пишется в лог чисто для истории. 
rem Сам запуск идет через прямые переменные, иначе CMD ломает кавычки ключей.
set "CMD_LINE="%FFM%" %FF_SEEK% -i "%FNF%" %FFKEYS% "%OUTPUT%""
>>"%LOG%" echo([CMD] %DATE% %TIME:~0,8% Строка кодирования: %CMD_LINE%
rem Запуск кодирования. FFmpeg пишет лог в stderr, а не в stdout - поэтому 2>LOG
rem Не запускаем через CMD_LINE, т.к. могут быть ошибки при спецсимволах.
rem Переходим в папку вывода перед самым запуском для корректной работы фильтра субтитров
rem Для включенного ТЕСТ-режима в 3 сжатия - имя лога ffmpeg и его перезапись не важны
pushd "%OUTPUT_DIR%"
"%FFM%" %FF_SEEK% -i "%FNF%" %FFKEYS% "%OUTPUT%" 2>"%FFMPEG_LOG%"
popd
rem Управление повторными прогонами ТЕСТА. Если TEST_STEP не задан (нет CRF или TEST выключен) - выходим
if not defined TEST_STEP goto NOTEST
rem Цикл делает 3 прогона: 1 (базовый), 2 (CRF-2), 3 (CRF+2). При TEST_STEP=4 - выход.
set /a TEST_STEP=TEST_STEP+1
if %TEST_STEP% LSS 4 goto TEST_CRFSTEPS
:NOTEST
rem Удаляем временный файл субтитров (если был):
if defined SUBS_FILE del "%OUTPUT_DIR%%SUBS_FILE%"
rem Проверяем, создан ли выходной видеофайл и ненулевой ли он
if not exist "%OUTPUT%" goto ENCODE_BAD
for %%F in ("%OUTPUT%") do set SIZE=%%~zF
if %SIZE% EQU 0 goto ENCODE_BAD
if defined TEST goto ENCODE_DONE
rem Если файл - MKV но не full-range - только меняем язык видео на русский
rem Остальные дорожки (аудио, субтитры) уже получили language=rus через ffmpeg -metadata (см. выше)
if /i "%OUTPUT_EXT%" == "mp4" goto ENCODE_DONE
if not defined COLOR_RANGE goto MKV_LANG_ONLY
rem Для MKV Full-range добавляем цветовые метаданные + меняем язык на русский
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
rem Конвертируем OEM-лог в итоговый UTF-8 лог
cscript //nologo "%CONV%" "%LOG%" "%LOGFINAL%" "cp866" "UTF-8"
rem Удаляем промежуточный OEM-лог
del "%LOG%"
rem Переход к следующему файлу
:NEXT
shift
goto LOOP
rem Завершение работы скрипта
:END
echo(Все файлы обработаны.
echo(
set "EV=%temp%\%CMDN%-MSG.vbs"
set "EMSG=Пакетный файл %CMDN% закончил работу."
rem Для VBS MsgBox текст нужен в ANSI, поэтому 1251, потом возвращаем 866
chcp 1251 >nul
>"%EV%" echo(MsgBox "%EMSG%",,"%CMDN%"
chcp 866 >nul
cscript //nologo "%EV%"
del "%EV%"
goto FASTEXIT