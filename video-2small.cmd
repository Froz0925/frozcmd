@echo off
:: Перекодирование видеофайлов в уменьшенный размер с высоким качеством
set "DO=Video recode script"
set "VRS=Froz %DO% v01.04.2026"

:: === Блок: ПРОВЕРКИ ===
title %DO%
echo(%VRS%
echo(Прервать кодирование - Ctrl-C.
echo(
set "CMDN=%~n0"

:: Проверка наличия утилит
set "FFM=%~dp0bin\ffmpeg.exe"
set "FFP=%~dp0bin\ffprobe.exe"
set "MI=%~dp0bin\mediainfo.exe"
set "MKVP=%~dp0bin\mkvpropedit.exe"
if not exist "%FFM%" echo([!] "%FFM%"& goto NOU
if not exist "%FFP%" echo([!] "%FFP%"& goto NOU
if not exist "%MI%" echo([!] "%MI%"& goto NOU
if not exist "%MKVP%" echo([!] "%MKVP%"& goto NOU
goto CHECK_INI
:NOU
echo(не найден, выходим.
echo(
pause
exit /b

:CHECK_INI
:: Проверка наличия ini-файла
set "USER_INI=%CMDN%.ini"
set "USER_INI_FULL=%~dp0%USER_INI%"
if exist "%USER_INI_FULL%" goto SRC_CHK

:: Если ini нет - создаём шаблон. Нельзя полный путь в VBS, поэтому pushd
pushd "%~dp0"
set "INIOEMW=%CMDN%-inioemw-%random%"
>"%INIOEMW%"  echo(Настройки Froz Video recode script (%CMDN%)
>>"%INIOEMW%" echo(------------------------------------------------------------
>>"%INIOEMW%" echo(
>>"%INIOEMW%" echo(; Размер картинки: 1 = уменьшить до 720p. Пусто = ограничить 1080p.
>>"%INIOEMW%" echo(; Если исходник меньше 720, он не будет увеличен.
>>"%INIOEMW%" echo(SCALE=1
>>"%INIOEMW%" echo(
>>"%INIOEMW%" echo(; Уровень качества (меньше = лучше). Пусто - кодек выбирает сам (обычно среднее качество).
>>"%INIOEMW%" echo(; Примерные значения в зависимости от исходника: nvenc и libx265: 26-33, libx264: 18-28
>>"%INIOEMW%" echo(; amf/qsv: 1-51 (18-28 дают качество, сравнимое с h264 CRF 23-26)
>>"%INIOEMW%" echo(CRF=32
>>"%INIOEMW%" echo(
>>"%INIOEMW%" echo(; Контейнер: mkv - больше функций. mp4 - совместимее (ограничены ключи и кодеки).
>>"%INIOEMW%" echo(; Внимание: расширение может быть принудительно изменено на MKV для сохранения 
>>"%INIOEMW%" echo(; цветового диапазона (Full Range), так как MP4 не поддерживает эти метаданные.
>>"%INIOEMW%" echo(OUTPUT_EXT=mkv
>>"%INIOEMW%" echo(
>>"%INIOEMW%" echo(; Аудио-ключи: Пусто или ; в начале = копировать исходный звук.
>>"%INIOEMW%" echo(; Рекомендуется OPUS: -c:a libopus -b:a 128k -ac 2
>>"%INIOEMW%" echo(; Формат AAC: -c:a aac -b:a 192k -ac 2
>>"%INIOEMW%" echo(; Для MKV: если в оригинале AAC или OPUS - копируется без перекодирования.
>>"%INIOEMW%" echo(; Для MP4: если в оригинале не AAC или если здесь указан несовместимый кодек 
>>"%INIOEMW%" echo(; скрипт принудительно установит AAC 192k для гарантии воспроизведения.
>>"%INIOEMW%" echo(AUDIO_ARGS=-c:a libopus -b:a 128k -ac 2
>>"%INIOEMW%" echo(
>>"%INIOEMW%" echo(; Принудительный поворот (transpose): -90 = по часовой, 90 = против часовой, 180.
>>"%INIOEMW%" echo(; Пусто = берется из тега поворота контейнеров MP4/MOV, если есть.
>>"%INIOEMW%" echo(; Заданный здесь поворот добавляется к тегу из файла. Кодек *qsv не поддерживает ключ transpose.
>>"%INIOEMW%" echo(ROTATION=
>>"%INIOEMW%" echo(
>>"%INIOEMW%" echo(; Видеокодек. Аппаратным кодекам выбраны их максимально качественные ключи. libx* - preset slow.
>>"%INIOEMW%" echo(; Примечание: HEVC - меньше размер, выше качество, H.264 - совместимость.
>>"%INIOEMW%" echo(; NVIDIA: hevc_nvenc и h264_nvenc. Быстро, но иногда при том же битрейте качество хуже чем libx.
>>"%INIOEMW%" echo(;         Требуется GeForce GTX 950+ (Maxwell 2nd Gen GM20x) (2014+) и драйвер Nvidia v.570+.
>>"%INIOEMW%" echo(; AMD:    hevc_amf и h264_amf - Radeon RX 400 / R9 300 серии и новее (2015+)
>>"%INIOEMW%" echo(;         Требуется драйвер AMD Adrenalin Edition (не Microsoft)
>>"%INIOEMW%" echo(; INTEL:  hevc_qsv и h264_qsv - Intel Skylake+ (2015+), драйвер Intel HD + Media Feature Pack
>>"%INIOEMW%" echo(; CPU:    libx265 - очень медленно. libx264 - медленно. Максимальное качество.
>>"%INIOEMW%" echo(CODEC=hevc_nvenc
>>"%INIOEMW%" echo(
>>"%INIOEMW%" echo(; Профиль кодирования для HEVC: main10 (10 bit) и main (8 bit).
>>"%INIOEMW%" echo(; Для H.264 всегда будет установлен high.
>>"%INIOEMW%" echo(; Если не задано - устанавливается main10, если поддерживается кодеком.
>>"%INIOEMW%" echo(PROFILE=
>>"%INIOEMW%" echo(
>>"%INIOEMW%" echo(; Частота кадров. Если не задано - обрабатывается автоматически:
>>"%INIOEMW%" echo(; - обычное видео остается как есть (CFR);
>>"%INIOEMW%" echo(; - плавающий FPS (VFR) приводится к ближайшему CFR: 25, 30, 50 или 60;
>>"%INIOEMW%" echo(; - чересстрочное (50i/60i) преобразуется в плавное 50p/60p (60p для 480i).
>>"%INIOEMW%" echo(; Если плавность 50p/60p не нужна (нужен эффект "кино") - установить 25 или 30.
>>"%INIOEMW%" echo(; Примеры: 24, 25, 30, 50, 60, 24000/1001 (~23.976), 30000/1001 (~29.97)
>>"%INIOEMW%" echo(FPS=
>>"%INIOEMW%" echo(
>>"%INIOEMW%" echo(; Суффикс имени файла
>>"%INIOEMW%" echo(NAME_APPEND=_sm
>>"%INIOEMW%" echo(
>>"%INIOEMW%" echo(; Калибровка скорости. Нужна для расчета оставшегося времени.
>>"%INIOEMW%" echo(; Расчет опытным путем: (секунд кодирования / секунд видео) x 100. Пример: 0.3 -^> ставим 30.
>>"%INIOEMW%" echo(; Лучше измерять на видео 1080/30, скрипт учтёт ускорение для 720p и замедление для 50/60 fps.
>>"%INIOEMW%" echo(SPEED_NVENC=8
>>"%INIOEMW%" echo(SPEED_AMF=50
>>"%INIOEMW%" echo(SPEED_QSV=50
>>"%INIOEMW%" echo(SPEED_LIBX265=150
>>"%INIOEMW%" echo(SPEED_LIBX264=120
:: Конвертация OEM в UTF-8
set "VTO=%temp%\%CMDN%-oem2utf-%random%.vbs"
>"%VTO%"  echo(With CreateObject("ADODB.Stream")
>>"%VTO%" echo(.Type=2:.Charset="cp866":.Open:.LoadFromFile "%INIOEMW%":s=.ReadText:.Close
>>"%VTO%" echo(.Type=2:.Charset="UTF-8":.Open:.WriteText s:.SaveToFile "%USER_INI%",2:.Close:End With
cscript //nologo "%VTO%"
:: Удаление временных файлов и возврат в исходную папку
del "%INIOEMW%" & del "%VTO%"
popd
echo([!] Файл настроек не найден - создан новый шаблон.
echo(
goto HELP

:: Проверка наличия входных файлов
:SRC_CHK
if "%~1" == "" goto HELP
goto FLD_CHK

:HELP
echo(Использование: При необходимости измените настройки в файле
echo(%USER_INI_FULL%
echo(редактором для Unicode TXT-файлов, например Блокнотом.
echo(
echo(Затем перетяните или вставьте видеофайлы на этот файл.
echo(
pause
exit /b

:FLD_CHK
set "ATTR=%~a1"
if /i "%ATTR:~0,1%"=="d" echo(Папки не обрабатываются, выходим.& echo(& pause & exit /b

:: Проверка длины аргументов CMD через VBS
:: так как в CMD нет безопасного способа парсить строку с &)(
set "CTV=%temp%\%CMDN%-len-%random%.vbs"
set "CTO=%temp%\%CMDN%-out-%random%.txt"
:: Подсчёт длины всех аргументов с пробелами - для проверки лимита CMD (8191)
:: Массив + Join, т.к. WScript.Arguments не совместим с Join напрямую
:: Проверка на "%~1"=="" выше гарантирует a.Count >= 1 , значит ReDim безопасен
>"%CTV%" echo(Set a=WScript.Arguments.Unnamed:ReDim b(a.Count-1)
>>"%CTV%" echo(For i=0To a.Count-1:b(i)=a(i):Next:WScript.Echo Len(Join(b," "))
cscript //nologo "%CTV%" %* >"%CTO%"
set "ALEN=0"
set /p "ALEN=" <"%CTO%"
del "%CTV%" & del "%CTO%"
if %ALEN% GTR 7500 (
    echo(ВНИМАНИЕ: слишком длинная команда.
    echo(Общая длина путей к файлам больше 7500 символов - возможна потеря данных.
    echo(Ограничение Windows - 8191 символ, остальное будет обрезано. Выходим.
    echo(
    pause
    exit /b
)

:: Читаем ini-файл в переменные.
:: Сброс переменных
set "SCALE="
set "CRF="
set "AUDIO_ARGS="
set "ROTATION="
set "CODEC="
set "PROFILE="
set "FPS="
set "OUTPUT_EXT="
set "NAME_APPEND="
set "SPEED_NVENC="
set "SPEED_AMF="
set "SPEED_QSV="
set "SPEED_LIBX265="
set "SPEED_LIBX264="
:: Конвертация UTF-8 в OEM - нельзя полный путь в VBS, поэтому pushd
pushd "%~dp0"
set "INIOEMR=%CMDN%-inioemr-%random%"
set "VTU=%temp%\%CMDN%-utf2oem-%random%.vbs"
>"%VTU%"  echo(With CreateObject("ADODB.Stream")
>>"%VTU%" echo(.Type=2:.Charset="UTF-8":.Open:.LoadFromFile "%USER_INI%":s=.ReadText:.Close
>>"%VTU%" echo(.Type=2:.Charset="cp866":.Open:.WriteText s:.SaveToFile "%INIOEMR%",2:.Close:End With
cscript //nologo "%VTU%"
del "%VTU%"
:: Чтение ini-файла
for /f "usebackq tokens=1* delims==" %%a in ("%INIOEMR%") do (
    if "%%a"=="SCALE"               set "SCALE=%%b"
    if "%%a"=="CRF"                 set "CRF=%%b"
    if "%%a"=="AUDIO_ARGS"          set "AUDIO_ARGS=%%b"
    if "%%a"=="ROTATION"            set "ROTATION=%%b"
    if "%%a"=="CODEC"               set "CODEC=%%b"
    if "%%a"=="PROFILE"             set "PROFILE=%%b"
    if "%%a"=="FPS"                 set "FPS=%%b"
    if "%%a"=="OUTPUT_EXT"          set "OUTPUT_EXT=%%b"
    if "%%a"=="NAME_APPEND"         set "NAME_APPEND=%%b"
    if "%%a"=="SPEED_NVENC"         set "SPEED_NVENC=%%b"
    if "%%a"=="SPEED_AMF"           set "SPEED_AMF=%%b"
    if "%%a"=="SPEED_QSV"           set "SPEED_QSV=%%b"
    if "%%a"=="SPEED_LIBX265"       set "SPEED_LIBX265=%%b"
    if "%%a"=="SPEED_LIBX264"       set "SPEED_LIBX264=%%b"
)
:: Удаление OEM-ini и возврат в исходную папку
del "%INIOEMR%"
popd

:: Проверка ключевых user sets:
if not defined CODEC (
    echo([!] В %USER_INI_FULL%
    echo(не задан параметр CODEC - задайте. Выходим.
    echo(
    pause
    exit /b
)
if not defined OUTPUT_EXT (
    set "OUTPUT_EXT=mkv"
    echo([!] В %USER_INI_FULL%
    echo(не задано расширение выходных файлов - принимаем: %OUTPUT_EXT%
    echo(
)
if not defined NAME_APPEND (
    set "NAME_APPEND=_sm"
    echo([!] В %USER_INI_FULL%
    echo(не задан суффикс выходных файлов - принимаем: %NAME_APPEND%
    echo(
)

:: Проверка: поддерживает ли GPU выбранный GPU-кодек
if /i "%CODEC:~0,5%" == "libx2" goto SKIP_GCHK
:: Базовое имя для временных файлов (логи и скрипт перекодировки)
set "GLOG=%temp%\%CMDN%-gpuchk-%random%"
:: ffmpeg пишет stderr в UTF-8 -> сохраняем как UTF-8-лог
set "GLOGU=%GLOG%-utf8"
:: Создаём виртуальный пустой видеофайл длиной в 1 секунду и пытаемся сжать кодеком
"%FFM%" -hide_banner -v error -f lavfi -i nullsrc -c:v %CODEC% -t 1 -f null - 2>"%GLOGU%"
:: findstr в CMD работает только с OEM (cp866) - конвертируем лог из UTF-8 в OEM
set "GLOGE=%GLOG%-oem"
set "VT=%GLOG%.vbs"
>"%VT%"  echo(With CreateObject("ADODB.Stream")
>>"%VT%" echo(.Type=2:.Charset="UTF-8":.Open:.LoadFromFile "%GLOGU%":s=.ReadText:.Close
>>"%VT%" echo(.Type=2:.Charset="cp866":.Open:.WriteText s:.SaveToFile "%GLOGE%",2:.Close:End With
cscript //nologo "%VT%"
:: Не отрывать строку findstr от if errorlevel
findstr /i "Error while opening encoder" "%GLOGE%" >nul
if %ERRORLEVEL% EQU 0 (
    echo([!] Видеокарта или её драйвер не поддерживает выбранный GPU-кодек.
    echo(Обновите видеокарту и/или драйвер, или смените кодек в настройках скрипта. Выходим.
    echo(
    pause
    exit /b
)
del "%VT%" & del "%GLOGE%" & del "%GLOGU%"
:SKIP_GCHK

:: Глобальные set перед LOOP
:: Все подаваемые на вход файлы всегда лежат в одной папке.
set "OUTPUT_DIR=%~dp1"
:: Сохраняем исходные user-значения которые могут быть перезаписаны при работе
set "USER_ROTATION=%ROTATION%"
set "USER_OUTPUT_EXT=%OUTPUT_EXT%"
set "USER_FPS=%FPS%"






:: === Блок: СТАРТ ===
:LOOP
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
if not defined FNF goto END

set "ATTR=%~a1"
if /i not "%ATTR:~0,1%"=="d" goto FILEOK
echo(%FNN% - папка, пропускаем.
goto NEXT
:FILEOK
:: Временное имя OEM-лога для текущего видеофайла - используем дату, а не %random%.
:: Чтобы не зависеть от локали Windows берём текущую дату-время через VBS, 
:: а не через %date% %time%. Формат: ГГГГ-ММ-ДД_ЧЧММСС
set "TV=%temp%\%CMDN%-dtmp-%random%.vbs"
>"%TV%"  echo(s=Year(Now)^&"-"^&Right("0"^&Month(Now),2)^&"-"
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
set "TAGBPS="
set "LENGTH_SECONDS="
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
    if "%%a"=="pix_fmt"        set "PIX_FMT=%%b"
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
goto GET_AUDIO
:BADFILE
echo([ERROR] ffprobe не смог извлечь параметры видео. Файл пропущен.
echo(
>>"%LOG%" echo([ERROR] %DATE% %TIME:~0,8% ffprobe не смог извлечь параметры видео. Файл пропущен.
goto NEXT
:GET_AUDIO
:: Извлекаем кодек аудиодорожки чтобы решить что с ним делать дальше
set "AUDIO_CODEC="
set "FFP_ATMP=%temp%\%CMDN%-ffprobe-audio-%random%.txt"
:: Ключ :nk=1 отбросит текст "codec_name="
"%FFP%" -v error -select_streams a:0 -show_entries stream=codec_name -of default=nw=1:nk=1 "%FNF%" >"%FFP_ATMP%"
set /p "AUDIO_CODEC=" <"%FFP_ATMP%"
del "%FFP_ATMP%"






:: === Блок: ЦВЕТ ===
:: Блок должен быть перед блоком ПОВОРОТ
:: Определение цветового диапазона (Full Range / Limited Range)
::   - Если ffprobe извлёк pix_fmt=yuvj420p - считаем, что видео должно отображаться в Full Range,
::     хотя видео по факту - Limited (16-235). Это стандартное поведение телефонов:
::     они используют yuvj420p, чтобы плееры "растянули" диапазон и сделали видео ярче.
::   - Чтобы сохранить этот эффект, устанавливаем colour-range=1 через mkvpropedit в MKV.
::     ffmpeg не гарантирует запись этого тега, а mkvpropedit не работает с MP4.
::     Поэтому при yuvj420p расширение меняется на MKV, даже если юзер выбрал MP4.
:: Если очень надо получить MP4 с Full Range, то можно вручную позже (не проверено):
::   ffmpeg.exe -i input.mkv -c copy -map 0:v -map 0:a? -map 0:s? -f mp4 -tag:v hvc1 temp.mp4
::   MP4Box.exe -add temp.mp4 -new output.mp4 -color=1

:: PIX_FMT извлечён ранее - определяем JPEG FULL RANGE по PIX_FMT
set "COLOR_RANGE="
if /i "%PIX_FMT%" == "yuvj420p" set "COLOR_RANGE=1"
if not defined COLOR_RANGE goto COLOR_DONE
:: Здесь нельзя if (...) так как %OUTPUT_EXT% во второй строке не применит значение из первого set
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
:: Кодеки *qsv не поддерживают фильтр transpose. User-ROTATION будет проигнорирован.
if /i "%CODEC:~-3%" == "qsv" (
    >>"%LOG%" echo([WARNING] %DATE% %TIME:~0,8% Кодек %CODEC% не поддерживает ключ transpose.
    >>"%LOG%" echo([WARNING] %DATE% %TIME:~0,8% Не применяем User-Rotation.
    >>"%LOG%" echo([WARNING] %DATE% %TIME:~0,8% Поверните видео до кодирования или смените кодек.
    goto ROTATE_DONE
)
if "%ROTATION%" == "-90" (
    set "ROTATION_FILTER=transpose=1"
    set "SRC_H=%SRC_W%"
    goto ROTATE_DONE
)
if "%ROTATION%" == "90" (
    set "ROTATION_FILTER=transpose=2"
    set "SRC_H=%SRC_W%"
    goto ROTATE_DONE
)
:: при 180 - размеры не меняются - SRC_H остаётся как есть
if "%ROTATION%" == "180" (
    set "ROTATION_FILTER=transpose=1,transpose=1"
    goto ROTATE_DONE
)
:ROTATE_DONE






:: === Блок: МАСШТАБ ===
:: Масштабируем если "SCALE=1": до 720p, если высота > 720. "SCALE=": до 1080p, если есть transpose и высота > 1080
set "SCALE_EXPR="
if not defined SCALE goto CHECK_SCALE_EMPTY
:: SRC_H - физическая высота кадра после всех поворотов (из блока ПОВОРОТ).
:: Используется для принятия решения о масштабировании.
:: Режим SCALE=1: уменьшаем до 720, если высота > 720
if %SRC_H% LEQ 720 (
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Задан SCALE=1, высота после поворота ^(если он был^):
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% %SRC_H% - 720 или менее - не масштабируем.
    goto SCALE_DONE
)
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Задан SCALE=1: высота после поворота ^(если он был^):
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% %SRC_H% - масштабируем до 720.
set "SCALE_EXPR=scale=-2:720"
goto SCALE_DONE
:: Режим SCALE не задан: уменьшаем до 1080, если высота > 1080
:CHECK_SCALE_EMPTY
if %SRC_H% LEQ 1080 (
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% SCALE не задан, высота после поворота ^(если он был^):
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% %SRC_H% - 1080 или менее - не масштабируем.
    goto SCALE_DONE
)
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% SCALE не задан: высота после поворота ^(если он был^):
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% %SRC_H% - масштабируем до 1080.
set "SCALE_EXPR=scale=-2:1080"
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
:: Если FPS задан вручную - выходим сразу
if defined FPS (
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% FPS задан принудительно: %FPS%.
    goto FPS_DONE
)
:: Если видео чересстрочное - ставим FPS по умолчанию и выходим
set "IS_INTERLACED="
if /i "%FIELD_ORDER%" == "unknown" (
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% FIELD_ORDER не определён - "unknown". Считаем видео progressive.
    goto HANDLE_PROGRESSIVE
)
if /i not "%FIELD_ORDER%" == "progressive" goto HANDLE_INTERLACED
:HANDLE_PROGRESSIVE
:: Дальше может быть только progressive видео. Всегда извлекаем MAX_FPS в т.ч. для блока ВРЕМЯ
set "TMPMI=%temp%\%CMDN%-mi-fps-%random%.txt"
"%MI%" --Inform=Video;%%FrameRate%% "%FNF%" >"%TMPMI%"
set /p MAX_FPS= <"%TMPMI%"
del "%TMPMI%"
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
set "SPEED_CENTI="
if /i "%CODEC%" == "libx264" set "SPEED_CENTI=%SPEED_LIBX264%"
if /i "%CODEC%" == "libx265" set "SPEED_CENTI=%SPEED_LIBX265%"
if /i "%CODEC:~-5%" == "nvenc" set "SPEED_CENTI=%SPEED_NVENC%"
if /i "%CODEC:~-3%" == "amf"   set "SPEED_CENTI=%SPEED_AMF%"
if /i "%CODEC:~-3%" == "qsv"   set "SPEED_CENTI=%SPEED_QSV%"
if defined SPEED_CENTI goto TIME_VARS_SET
:: Fallback SPEED если кодек не в INI
set "SPEED_CENTI=30"
if /i "%CODEC:~0,5%" == "libx2" set "SPEED_CENTI=200"
:TIME_VARS_SET
:: Используем временную переменную, чтобы не сломать логику фильтрации.
:: Fallback-FPS = 30
set "FPS_FOR_TIME=30"
if defined MAX_FPS set "FPS_FOR_TIME=%MAX_FPS%"
if defined FPS set "FPS_FOR_TIME=%FPS%"
:: 1. Поправка на FPS: Видео 50/60 fps тяжелее, чем 30 fps (x1.8)
if %FPS_FOR_TIME% GTR 35 set /a "SPEED_CENTI=(SPEED_CENTI*180+50)/100"
:: 2. Поправка на разрешение: 720p и ниже жмётся в ~2.2 раза быстрее (x0.45)
if %SRC_H% LEQ 720 set /a "SPEED_CENTI=(SPEED_CENTI*45+50)/100"
:: 3. Коэффициент "Психологического запаса" (x1.3)
:: Чтобы юзер получил результат "раньше срока"
set /a "SPEED_CENTI=(SPEED_CENTI*130+50)/100"
:: LENGTH_SECONDS извлечён ранее. Округляем длину видео вверх (2.1 -> 3)
:: Добавляем точку для защиты от целых чисел без дробной части
for /f "tokens=1 delims=." %%a in ("%LENGTH_SECONDS%.") do set /a "LENGTH_SECONDS=%%a+1"
:: Рассчитываем примерное время кодирования в секундах
set /a "ENCODE_SECONDS=(LENGTH_SECONDS*SPEED_CENTI)/100"
:: Гарантируем минимум 1 секунду
if %ENCODE_SECONDS% EQU 0 set "ENCODE_SECONDS=1"
:: Переводим секунды в минуты:секунды
set /a "MINUTES=ENCODE_SECONDS/60"
set /a "SECONDS=ENCODE_SECONDS%%60"
if %SECONDS% LSS 10 set "SECONDS=0%SECONDS%"
echo(Примерное время кодирования: %MINUTES% минут %SECONDS% секунд.
echo(






:: === Блок: ПРОФИЛЬ ===
:: Профиль кодирования profile: main/high - 8 bit, main10 - 10 bit. Для всех H.264 - только high.
:: Формат пикселей pix_fmt: в зависимости от профиля и поддержки кодеком
set "USE_PROFILE=high"
set "PIX_FMT_ARGS=-pix_fmt yuv420p"
:: H.264 использует профиль high по умолчанию
if /i "%CODEC:~0,5%" == "h264_" goto PROFILE_DONE
if /i "%CODEC%" == "libx264" goto PROFILE_DONE
:: Для HEVC используем main10, libx265 требует yuv420p10le
set "USE_PROFILE=main10"
set "PIX_FMT_ARGS=-pix_fmt p010le"
if /i "%CODEC%" == "libx265" set "PIX_FMT_ARGS=-pix_fmt yuv420p10le"
:: Если пользователь явно запросил для HEVC профиль main - меняем
if /i "%PROFILE%" == "main" (
    set "USE_PROFILE=main"
    set "PIX_FMT_ARGS=-pix_fmt yuv420p"
)
:PROFILE_DONE
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Установлен профиль кодирования: %USE_PROFILE%





:: === Блок: АУДИО ===
:: Если звука нет - обнуляем юзер-сет и выходим
if not defined AUDIO_CODEC set "AUDIO_ARGS=" & goto AUDIO_DONE
:: Если в источнике уже AAC - копируем независимо от контейнера, игнорируем юзера
if /i "%AUDIO_CODEC%"=="aac" goto AUDIO_COPY
:: Если MP4 - пропускаем проверку OPUS
if /i "%OUTPUT_EXT%"=="mp4" goto AUDIO_MP4
:: Если OPUS и MKV - копируем, игнорируем юзера
if /i "%AUDIO_CODEC%"=="opus" goto AUDIO_COPY
:: Если юзер что-то ввел для MKV - оставляем его вариант
if defined AUDIO_ARGS goto AUDIO_DONE
:: Если у юзера пусто и MKV - копируем (AC3, DTS и т.д.)
goto AUDIO_COPY
:AUDIO_MP4
:: Если у юзера пусто для MP4 - ставим AAC
if not defined AUDIO_ARGS goto AAC_SET
:: Ищем AAC в user-set:
:: В строке ниже несмотря на "if not" - работает "если в user-set AUDIO_ARGS найден AAC то..."
:: Но поиск сработает только если set не пустой, поэтому выше была проверка на непустое
if /i not "%AUDIO_ARGS%"=="%AUDIO_ARGS:aac=%" goto AUDIO_DONE
:AAC_SET
set "AUDIO_ARGS=-c:a aac -b:a 192k -ac 2"
goto AUDIO_DONE
:AUDIO_COPY
set "AUDIO_ARGS=-c:a copy"
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Аудио подходит для %OUTPUT_EXT% - копируем без перекодирования
:AUDIO_DONE





:: === Блок: СУБТИТРЫ ===
:: Должен быть перед блоком ВИДЕОФИЛЬТР. Обрабатывается только первая дорожка субтитров.
set "SUBS_TYPE="
set "SUBS_FILE="
set "FFP_STMP=%temp%\%CMDN%-ffprobe-subs-%random%.txt"
:: Ключ :nk=1 отбросит текст "codec_name="
"%FFP%" -v error -select_streams s:0 -show_entries stream=codec_name -of default=nw=1:nk=1 "%FNF%" >"%FFP_STMP%"
set /p "SUBS_TYPE=" <"%FFP_STMP%"
del "%FFP_STMP%"
if not defined SUBS_TYPE goto SKIP_SUBS_EXTRACT
if /i not "%OUTPUT_EXT%" == "mp4" goto SKIP_SUBS_EXTRACT
if /i "%SUBS_TYPE%"=="srt" set "SUBS_FILE=tempsubs%random%.srt" & goto SUBS_EXTRACT
if /i "%SUBS_TYPE%"=="ass" set "SUBS_FILE=tempsubs%random%.ass" & goto SUBS_EXTRACT
goto SKIP_SUBS_EXTRACT
:SUBS_EXTRACT
"%FFM%" -hide_banner -v error -i "%FNF%" -c:s copy "%OUTPUT_DIR%%SUBS_FILE%" 2>nul
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Извлечён временный файл субтитров %SUBS_FILE%
:SKIP_SUBS_EXTRACT







:: === Блок: ВИДЕОФИЛЬТР ===
:: Этот блок должен быть после блоков МАСШТАБ, ПОВОРОТ, ЧАСТОТА
:: Порядок фильтров: scale -> transpose -> deinterlace -> fps
::   - scale до поворота (размеры), deinterlace после (ориентация), fps в конце (VFR)
set "FL="
:: Добавляем scale, если не пропущен и задан
if defined SCALE_EXPR set "FL=%SCALE_EXPR%"
:: Добавляем поворот, если задан
if not defined ROTATION_FILTER goto SKIP_TR
if defined FL set "FL=%FL%,"
set "FL=%FL%%ROTATION_FILTER%"
:SKIP_TR
:: Добавляем деинтерлейс для interlaced видео
if not defined IS_INTERLACED goto SKIP_DE
:: По умолчанию: bwdif=1 - 50i->50p, 60i->60p - сохранит плавность
set "INTCMD=bwdif=1"
if not defined FPS goto FL_INT
:: При юзер-FPS 25/30 ("кино") -> bwdif=0 + skip FPS, чтобы избежать артефактов
:: от bwdif=1,fps=25 (50 кадров и отбросить каждый второй)
set "FL_SKIP_FPS="
if %FPS% LEQ 30 set "INTCMD=bwdif=0" & set "FL_SKIP_FPS=1"
:FL_INT
if defined FL set "FL=%FL%,"
set "FL=%FL%%INTCMD%"
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Применён деинтерлейсинг: %INTCMD%
:SKIP_DE
:: Добавляем fps, если задан
if defined FL_SKIP_FPS goto SKIP_FPS
if not defined FPS goto SKIP_FPS
if defined FL set "FL=%FL%,"
set "FL=%FL%fps=%FPS%"
:SKIP_FPS
:: Hardburn субтитров в MP4
if not defined SUBS_FILE goto SKIP_SB
if defined FL set "FL=%FL%,"
set "FL=%FL%subtitles=%SUBS_FILE%"
:SKIP_SB
:: Формируем итоговый флаг -vf
set "VF="
if defined FL set "VF=-vf "%FL%""





:: === Блок: КЛЮЧИ ===
:: Порядок ключей ffmpeg КРИТИЧЕН для правильной работы GPU-кодеков. Должно быть так:
:: -hide_banner -c:v codec [кодек-специфичные init-параметры] -profile:v [-preset]
:: [-vf] [-pix_fmt] [-crf] [-tune] [-level] -c:a -c:s [-metadata lng]
set "FINAL_KEYS=-hide_banner -c:v %CODEC%"
if /i "%CODEC:~-5%" == "nvenc" goto NV_OPTS
if /i "%CODEC:~-3%" == "amf" goto AMF_OPTS
if /i "%CODEC:~-3%" == "qsv" goto QSV_OPTS
:: Ну и остались libx* : tune film не задаём, т.к. libx265 его не умеет
set "FINAL_KEYS=%FINAL_KEYS% -preset slow"
goto KEYS_PROFILE_V
:NV_OPTS
if /i "%CODEC:~0,4%" == "hevc" set "FINAL_KEYS=%FINAL_KEYS% -preset p7 -tune uhq"
if /i "%CODEC:~0,4%" == "h264" set "FINAL_KEYS=%FINAL_KEYS% -preset p7 -tune hq"
:: По тестам эти ключи ниже вообще не влияют на результат - 
:: итоговый файл при любом их сочетании имеет тот же размер до байта. Но пусть будут.
set "FINAL_KEYS=%FINAL_KEYS% -rc-lookahead 53 -spatial_aq 1"
set "FINAL_KEYS=%FINAL_KEYS% -b_ref_mode 2"
goto KEYS_PROFILE_V
:AMF_OPTS
:: Не протестировано (нет железа) - тут только теория!
set "FINAL_KEYS=%FINAL_KEYS% -usage high_quality -vbaq 1 -preanalysis 1"
if /i "%CODEC%" == "h264_amf" set "FINAL_KEYS=%FINAL_KEYS% -coder cabac -bf 2"
if /i "%CODEC%" == "hevc_amf" goto CHECK_AMF_10BIT
goto KEYS_PROFILE_V
:CHECK_AMF_10BIT
if /i "%USE_PROFILE%" == "main10" set "FINAL_KEYS=%FINAL_KEYS% -bitdepth 10"
goto KEYS_PROFILE_V
:QSV_OPTS
:: Не протестировано (нет железа) - тут только теория!
set "FINAL_KEYS=%FINAL_KEYS% -scenario archive -async_depth 1"
set "FINAL_KEYS=%FINAL_KEYS% -extbrc 1 -rdo 1 -adaptive_i 1 -adaptive_b 1"
if not defined CRF (
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% QSV: включён look-ahead для VBR
    set "FINAL_KEYS=%FINAL_KEYS% -look_ahead 1 -look_ahead_depth 60"
)
goto KEYS_PROFILE_V
:KEYS_PROFILE_V
if /i not "%CODEC:~-5%" == "nvenc" set "FINAL_KEYS=%FINAL_KEYS% -profile:v %USE_PROFILE%"
:: Level для h264_* кодеков (совместимость с проигрывателями)
if /i "%CODEC:~0,5%" == "h264_" set "FINAL_KEYS=%FINAL_KEYS% -level 4.0"
if /i "%CODEC%" == "libx264" set "FINAL_KEYS=%FINAL_KEYS% -level 4.0"
:: Видеофильтр -vf
if defined VF set "FINAL_KEYS=%FINAL_KEYS% %VF%"
:: Формат пикселей (8 bit yuv420p или 10 bit yuv420p10le)
if defined PIX_FMT_ARGS set "FINAL_KEYS=%FINAL_KEYS% %PIX_FMT_ARGS%"
:: Параметры управления качеством (не битрейтом)
set "FINAL_CRF="
if not defined CRF goto KEYS_SKIP_CRF
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% CRF для %CODEC% установлен: %CRF%
:: У *NVENC есть ещё -multipass fullres (2pass), он несовместим с CRF-режимом -cq,
:: и по факту для архивных видео с низким битрейтом почему-то даёт качество хуже чем CRF.
if /i "%CODEC:~-5%" == "nvenc" set "FINAL_CRF=-cq %CRF%"
if /i "%CODEC:~-3%" == "amf" set "FINAL_CRF=-rc cqp -qp_i %CRF% -qp_p %CRF%"
if /i "%CODEC%" == "h264_amf" set "FINAL_CRF=%FINAL_CRF% -qp_b %CRF%"
if /i "%CODEC:~-3%" == "qsv" set "FINAL_CRF=-global_quality %CRF%"
if /i "%CODEC:~0,5%" == "libx2" set "FINAL_CRF=-crf %CRF%"
:KEYS_SKIP_CRF
if defined FINAL_CRF set "FINAL_KEYS=%FINAL_KEYS% %FINAL_CRF%"
:: Добавляем аудио если есть
if not defined AUDIO_ARGS goto KEYS_SKIP_AUD
set "FINAL_KEYS=%FINAL_KEYS% %AUDIO_ARGS%"
:: Устанавливаем язык аудио в "rus".
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:a:0 language=rus"
:: Удаляем старые аудио-теги "битрейт" и "размер потока" ТОЛЬКО при перекодировании,
:: так как при -c:a copy значения остаются корректными.
if "%AUDIO_ARGS%" == "-c:a copy" goto KEYS_SKIP_AUD
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:a BPS="
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:a BPS-eng="
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:a NUMBER_OF_BYTES="
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:a NUMBER_OF_BYTES-eng="
:KEYS_SKIP_AUD
:: Устанавливаем глобальный язык файла. Видеодорожку не трогаем -
:: ffmpeg делает это криво в MKV, а в MP4 пусть остаётся und/eng.
:: Язык видеодорожки устанавливается через mkvpropedit
:: Если включён full-range (COLOR_RANGE=1) - mkvpropedit также добавит цветовые метаданные.
set "FINAL_KEYS=%FINAL_KEYS% -metadata language=rus"
:: Добавляем субтитры если есть, устанавливаем их язык в "rus"
if not defined SUBS_TYPE goto KEYS_SKIP_SB
:: Если контейнер MP4 - выше уже сделано "вшивание" (hardburn) в ключе VF
if /i "%OUTPUT_EXT%" == "mp4" goto KEYS_SKIP_SB
set "FINAL_KEYS=%FINAL_KEYS% -c:s copy"
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:s:0 language=rus"
:KEYS_SKIP_SB
:: Копируем глобальные метаданные (Дата съемки, модель камеры, GPS)
set "FINAL_KEYS=%FINAL_KEYS% -map_metadata 0"
:: Для MP4 - быстрый старт воспроизведения (faststart) и теги стандарта Apple/Google
if /i "%OUTPUT_EXT%" == "mp4" set "FINAL_KEYS=%FINAL_KEYS% -movflags +faststart+use_metadata_tags"

:: Удаляем старые видео-теги "битрейт" и "размер потока", если они есть.
:: FFmpeg копирует их из исходника, но при перекодировании значения неактуальны.
if not defined TAGBPS goto KEYS_DONE
>>"%LOG%" echo([CMD] %DATE% %TIME:~0,8% Удаляем "мусорный" metadata-тег BPS %TAGBPS% и сопутствующие ему.
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:v BPS="
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:v BPS-eng="
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:v NUMBER_OF_BYTES="
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:v NUMBER_OF_BYTES-eng="
:KEYS_DONE





:: === Блок: ОБРАБОТКА ===
:: Пишем CMD_LINE в лог через set, так как есть ключи с кавычками и спецсимволами
set "CMD_LINE="%FFM%" -i "%FNF%" %FINAL_KEYS% "%OUTPUT%""
>>"%LOG%" echo([CMD] %DATE% %TIME:~0,8% Строка кодирования: %CMD_LINE%
:: Запуск кодирования. FFmpeg пишет лог в stderr, а не в stdout - поэтому 2>LOG
:: Не запускаем через %CMD_LINE%, т.к. могут быть ошибки при спецсимволах.
"%FFM%" -i "%FNF%" %FINAL_KEYS% "%OUTPUT%" 2>"%FFMPEG_LOG%"
:: Удаляем временный файл субтитров (если был):
if exist "%OUTPUT_DIR%%SUBS_FILE%" del "%OUTPUT_DIR%%SUBS_FILE%"
:: Проверяем, создан ли выходной видеофайл и ненулевой ли он
if not exist "%OUTPUT%" goto ENCODE_BAD
for %%F in ("%OUTPUT%") do set SIZE=%%~zF
if %SIZE% EQU 0 goto ENCODE_BAD
:: Если файл - MKV но не full-range - только меняем язык видео на русский
:: Остальные дорожки (аудио, субтитры) уже получили language=rus через ffmpeg -metadata (см. выше)
if not "%OUTPUT_EXT%" == "mkv" goto ENCODE_DONE
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% В MKV меняем язык видеодорожки на русский
if not defined COLOR_RANGE goto MKV_LANG_ONLY
:: Для MKV Full-range добавляем цветовые метаданные + меняем язык на русский
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Full color range: добавляем в MKV теги colour-range
"%MKVP%" "%OUTPUT%" --edit track:v1 --set "language=rus" --set "colour-range=1" --set "color-matrix-coefficients=1">nul
goto ENCODE_DONE
:MKV_LANG_ONLY
"%MKVP%" "%OUTPUT%" --edit track:v1 --set "language=rus">nul
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
:: Конвертируем OEM-лог в UTF-8:
:: %LOGE% - входной OEM-лог, %LOGU% - выходной UTF-8-лог.
:: Пути должны быть без кириллицы из-за разных кодировок CMD и VBS
:: Переходим в папку Logs
pushd "%OUTPUT_DIR%logs"
set "VT=%temp%\%CMDN%-oem2utf-%random%.vbs"
>"%VT%"  echo(With CreateObject("ADODB.Stream")
>>"%VT%" echo(.Type=2:.Charset="cp866":.Open:.LoadFromFile "%LOGE%":s=.ReadText:.Close
>>"%VT%" echo(.Type=2:.Charset="UTF-8":.Open:.WriteText s:.SaveToFile "%LOGU%",2:.Close:End With
cscript //nologo "%VT%"
del "%LOGE%"
if exist "%LOGN%" del "%LOGN%"
ren "%LOGU%" "%LOGN%"
del "%VT%"
popd
:: Переход к следующему файлу
:NEXT
shift
goto LOOP
:: Завершение работы скрипта
:END
echo(Все файлы обработаны.
echo(
set "EV=%temp%\%CMDN%-end-%random%.vbs"
set "EMSG=Пакетный файл %CMDN% закончил работу."
chcp 1251 >nul
>"%EV%" echo(MsgBox "%EMSG%",,"%CMDN%"
chcp 866 >nul
cscript //nologo "%EV%"
del "%EV%"
pause
exit