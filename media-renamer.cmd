@echo off
set "DO=Media Renamer"
title Froz %DO%
set "VRS=Froz %DO% v06.01.2026"
echo(%VRS%
echo(
if not "%~1"=="" goto exchk
echo(Пакетное переименование файлов по маске: ГГГГ-ММ-ДД_ЧЧММСС_имя.ext
echo(
echo(Перетащите папку или файлы на скрипт.
echo(Если первый аргумент - папка, обработает все файлы в ней.
echo(
echo(Работает с:
echo(  - EXIF в JPG (DTO) - приоритет
echo(  - Датой в имени файла (разные форматы, пробелы, разделители)
echo(  - Датой изменения файла (DLM)
echo(
echo(Особенности:
echo(  - Удаляет префиксы: IMG_, VID_, DSC_, PIC_
echo(  - Не переименовывает файлы, уже соответствующие маске
echo(  - При конфликтах имён добавляет _1, _2 и т.д.
echo(  - Приоритет: EXIF ^> имя ^> DLM
echo(
echo(
pause
exit /b

:: === КОММЕНТАРИИ К ЛОГИКЕ РАБОТЫ ===
:: Приоритет дат: EXIF.DTO > имя (дата_время) > имя (дата) + DLM > DLM
:: DTOALL: флаг после [a] - автоматически пишет EXIF в JPG без DTO
:: Конфликты: добавляет _1, _2...

:exchk
set "CMDN=%~n0"
set "EX=%~dp0bin\exiv2.exe"
if exist "%EX%" goto exok
echo(
echo(Ошибка: Не найден "%EX%".
echo(Положите exiv2.exe и exiv2.dll в папку bin рядом с cmd-файлом
echo(
pause
exit /b
:exok





:: Создаём один раз VBS-код для запроса DLM в отдельные переменные, способом не зависящим от локали
:: Формат выдачи VBS: ГГГГ ММ ДД ЧЧ ММ СС
set "DLMV=%temp%\%CMDN%-dlm-%random%%random%.vbs"
>"%DLMV%"  echo(With CreateObject("Scripting.FileSystemObject")
>>"%DLMV%" echo(Set f=.GetFile(WScript.Arguments.Item(0)):dt=f.DateLastModified
>>"%DLMV%" echo(Y=Year(dt):M=Right("0"^&Month(dt),2):D=Right("0"^&Day(dt),2)
>>"%DLMV%" echo(H=Right("0"^&Hour(dt),2):N=Right("0"^&Minute(dt),2):S=Right("0"^&Second(dt),2)
>>"%DLMV%" echo(WScript.Echo Y^&" "^&M^&" "^&D^&" "^&H^&" "^&N^&" "^&S:End With

:: Глобальные счётчики: CNT=переименовано, CNTALL=всего, CNTT=EXIF записано
:: DTOALL - флаг диалога с юзером "записать DTO во все последующие файлы без DTO"
set "CNT=0"
set "CNTALL=0"
set "CNTT=0"
set "DTOALL="

:: Определение режима работы - 'папка' или 'файлы'
set "ATTR=%~a1"
if /i "%ATTR:~0,1%"=="d" goto mode_folder

:: Режим работы: Список файлов
:: Проверка длины аргументов CMD через VBS
:: так как в CMD нет безопасного способа парсить строку с &)(
:: Проверка на "%~1"=="" выше - гарантирует a.Count >= 1, значит ReDim безопасен
set "CTV=%temp%\%CMDN%-len-%random%%random%.vbs"
set "CTO=%temp%\%CMDN%-out-%random%%random%.txt"
>"%CTV%" echo(Set a=WScript.Arguments.Unnamed:ReDim b(a.Count-1)
>>"%CTV%" echo(For i=0To a.Count-1:b(i)=a(i):Next:WScript.Echo Len(Join(b," "))
cscript //nologo "%CTV%" %* >"%CTO%"
set "ALEN=0"
set /p "ALEN=" <"%CTO%"
del "%CTV%" & del "%CTO%"
if %ALEN% GTR 7500 (
    echo(ВНИМАНИЕ: слишком длинная команда.
    echo(Общая длина путей к файлам больше 7500 символов - возможна потеря данных.
    echo(Ограничение Windows - 8191 символ, остальное будет обрезано.
    echo(
    echo(Перетащите папку вместо отдельных файлов, или подавайте частями. Выходим.
    echo(
    pause
    exit /b
)

set "FLD=%~dp1"
pushd "%FLD%"
echo(Обработка списка файлов...
echo(

:: Цикл работы по файлам
:loop
if "%~1"=="" goto done
:: Если среди файлов встретится папка - пропускаем её
set "ATTR=%~a1"
if /i "%ATTR:~0,1%"=="d" goto next
set "FN=%~nx1"
call :process_file
:next
shift
goto loop

:: Режим работы: Папка
:mode_folder
pushd "%~f1"
echo(Обработка папки "%~f1"...
echo(
:: Обработка файлов в папке (папок среди них быть не может - это исключает dir /a-d)
for /f "delims=" %%i in ('dir /b /a-d') do (
    set "FN=%%i"
    call :process_file    
)
goto done
:: Подпрограммы должны быть до done - иначе CMD не найдёт метки при вызове из for /f.
:: === ЗАВЕРШЕНИЕ ОСНОВНОГО КОДА ===







:: === ПОДПРОГРАММЫ ===
:process_file
:: Обнуление переменных:
set "BASE="
set "EXT="
set "DTO="
set "Y=" & set "M=" & set "D=" & set "HH=" & set "MM=" & set "SS="
set "NAME_Y=" & set "NAME_M=" & set "NAME_D=" & set "NAME_HH=" & set "NAME_MM=" & set "NAME_SS="
set "Y_DLM=" & set "M_DLM=" & set "D_DLM=" & set "HH_DLM=" & set "MM_DLM=" & set "SS_DLM="
set "JPG_MATCH="
set "DTO_COMP="
set "DTO_DATE="

for %%f in ("%FN%") do (
    set "BASE=%%~nf"
    set "EXT=%%~xf"
)

if "%EXT%"=="" exit /b

set /a CNTALL+=1

:: Используем флаг, т.к. он будет нужен ещё несколько раз
set "ISJPG="
if /i "%EXT%"==".jpg" set "ISJPG=1"
if /i "%EXT%"==".jpeg" set "ISJPG=1"
if defined ISJPG goto jpg_file
goto choose_date

:jpg_file
:: Для JPEG пробуем извлечь EXIF
:: 1. Читаем EXIF.DateTimeOriginal
:: 2. Если нет - идём в choose_date
:: 3. Если есть - сравниваем с датой из имени
:: 4. Если не совпадает - переименовываем
:: 5. Если совпадает - оставляем
:: Пытаемся использовать EXIF.DateTimeOriginal как приоритетный источник
:: Извлекаем EXIF DTO с помощью exiv2

set "TDTO=%temp%\%CMDN%-dto-%random%%random%.txt"
"%EX%" -q -g Exif.Photo.DateTimeOriginal -Pv "%FN%" >"%TDTO%"
set /p "DTO=" <"%TDTO%"
if exist "%TDTO%" del "%TDTO%"

if not defined DTO goto choose_date

:: Извлекаем дату из EXIF в отдельные переменные
:: DTO имеет приоритет над именем - если совпадает, файл пропускается
set "Y=%DTO:~0,4%"
set "M=%DTO:~5,2%"
set "D=%DTO:~8,2%"
set "HH=%DTO:~11,2%"
set "MM=%DTO:~14,2%"
set "SS=%DTO:~17,2%"

:: Проверка корректности EXIF-даты. Если дата невалидна - используем DLM
:: Битые EXIF: 0000:00:00, 2023:00:45, 9999:99:99 - отбрасываем, используем имя или DLM
if "%Y%"=="" goto choose_date
if "%M%"=="" goto choose_date
if "%D%"=="" goto choose_date
if %M% LSS 1 goto choose_date
if %M% GTR 12 goto choose_date
if %D% LSS 1 goto choose_date
if %D% GTR 31 goto choose_date
if %HH% GTR 23 goto choose_date
if %MM% GTR 59 goto choose_date
if %SS% GTR 59 goto choose_date

set "DTO_COMP=%Y%-%M%-%D% %HH%:%MM%:%SS%"
set "DTO_DATE=%Y%-%M%-%D%"
call :try_name_date

:: Проверка - совпадает ли полная дата и время с EXIF и форматом маски
call :check_jpg_match full
if defined JPG_MATCH goto file_skip

:: Проверка - совпадает ли только дата без времени и формат
call :check_jpg_match date
if defined JPG_MATCH goto file_skip

:: Ничего не совпадает - переходим к переименованию
goto build_name





:check_jpg_match
:: Проверяем, соответствует ли ИСХОДНОЕ имя файла (с префиксами) маске ГГГГ-ММ-ДД_ЧЧММСС
:: И совпадает ли дата/время с EXIF. Если ДА - пропускаем.
:: Если в начале есть IMG_, VID_ и т.д. - имя НЕ соответствует маске - не пропускаем.

:: Проверяем, соответствует ли имя файла EXIF-дате и маске ГГГГ-ММ-ДД_ЧЧММСС - если да, пропускаем
:: %1 = full (требуется дата+время в имени) или date (достаточно даты)
if not defined NAME_Y exit /b
:: Если режим НЕ "full" (т.е. "date") - пропускаем проверку времени
if /i not "%~1"=="full" goto check_time_skip
:: В режиме "full" время в имени обязательно
if not defined NAME_HH exit /b
:check_time_skip

:: ВАЖНО: эти проверки дублируют часть логики из try_name_date,
:: но здесь они нужны ТОЛЬКО для подтверждения, что файл уже в целевом формате.
:: Если не соответствует - не пропускаем, даже если дата совпадает с EXIF.
:: Используем FN (а не BASE), чтобы префиксы вроде IMG_
:: ломали проверку формата и заставляли переименовывать файл, даже если дата совпадает с EXIF.

:: Проверка формата даты в имени: YYYY-MM-DD
set "PART=%FN:~0,10%"

:: Проверяем длину и разделители
if "%PART:~4,1%" NEQ "-" exit /b
if "%PART:~7,1%" NEQ "-" exit /b

:: Минимальная проверка: первый символ каждой части - цифра
:: (остальные символы отсеятся позже в check_date_format, если потребуется)
if "%PART:~0,1%" GTR "9" exit /b
if "%PART:~0,1%" LSS "0" exit /b
if "%PART:~5,1%" GTR "9" exit /b
if "%PART:~5,1%" LSS "0" exit /b
if "%PART:~8,1%" GTR "9" exit /b
if "%PART:~8,1%" LSS "0" exit /b

:: Проверка: после даты - подчёркивание
set "UNDERSCORE=%FN:~10,1%"
if not defined UNDERSCORE exit /b
if not "%UNDERSCORE%"=="_" exit /b

:: Проверка совпадения даты с EXIF
set "NAME_DATE=%NAME_Y%-%NAME_M%-%NAME_D%"
if not "%NAME_DATE%"=="%DTO_DATE%" exit /b

:: Если режим "только дата" - совпадение найдено
if /i "%~1"=="date" (
    set "JPG_MATCH=1"
    exit /b
)

:: Режим "full": проверяем время
set "TIME_PART=%FN:~11,6%"
:: Проверяем длину времени (должно быть 6 символов)
if "%TIME_PART:~5,1%"=="" exit /b

:: Проверяем, что первый символ времени - цифра
if "%TIME_PART:~0,1%" GTR "9" exit /b
if "%TIME_PART:~0,1%" LSS "0" exit /b

:: Проверка совпадения полной даты+времени с EXIF
set "NAME_COMP=%NAME_Y%-%NAME_M%-%NAME_D% %NAME_HH%:%NAME_MM%:%NAME_SS%"
if not "%NAME_COMP%"=="%DTO_COMP%" exit /b

:: Полное совпадение
set "JPG_MATCH=1"
exit /b




:try_name_date
:: Вся нормализация BASE (префиксы, обрезка, YYYYMMDD_, YYYY-MM-DDHHMMSS) отложена сюда.
:: Выполняется ТОЛЬКО если файл не пропущен.
:: "Нормализация" = приведение BASE к единому формату.
:: "Попытка" = извлечение даты/времени из уже нормализованного BASE.

:: Обнуление переменных
set "DATE_VALID="
set "TIME_VALID="

:: Удаляем префиксы (регистронезависимо) если имя начинается не с цифры
if "%BASE:~0,1%" GTR "9" goto do_prefixes
if "%BASE:~0,1%" LSS "0" goto do_prefixes
goto skip_prefixes
:do_prefixes
if /i "%BASE:IMG_=%" NEQ "%BASE%" set "BASE=%BASE:IMG_=%" & goto skip_prefixes
if /i "%BASE:VID_=%" NEQ "%BASE%" set "BASE=%BASE:VID_=%" & goto skip_prefixes
if /i "%BASE:DSC_=%" NEQ "%BASE%" set "BASE=%BASE:DSC_=%" & goto skip_prefixes
if /i "%BASE:PIC_=%" NEQ "%BASE%" set "BASE=%BASE:PIC_=%" & goto skip_prefixes
:skip_prefixes

:: Пытаемся извлечь дату и время из имени файла.

:: --- Нормализация 1: если имя начинается с YYYYMMDD и за ним следует валидное HHMMSS,
:: то приводим к YYYY-MM-DD_HHMMSS (удаляя мусорные разделители между датой и временем)
:: Эта нормализация нужна ТОЛЬКО для парсинга - она НЕ означает,
:: что файл уже в правильной маске. Проверка формата будет позже в check_jpg_match.
:: Приводим разделитель между датой и временем к '_', чтобы парсер мог надёжно выделить HHMMSS
set "TEST=%BASE:~0,8%"

:: Быстрая проверка: первый символ должен быть цифрой, и строка должна быть длиной 8
if "%TEST:~7,1%"=="" goto check_yyyymmdd_try
if "%TEST:~0,1%" GTR "9" goto check_yyyymmdd_try
if "%TEST:~0,1%" LSS "0" goto check_yyyymmdd_try

:: Проверяем остальные символы минимально (только первый символ каждой пары)
if "%TEST:~1,1%" GTR "9" goto check_yyyymmdd_try
if "%TEST:~1,1%" LSS "0" goto check_yyyymmdd_try
if "%TEST:~2,1%" GTR "9" goto check_yyyymmdd_try
if "%TEST:~2,1%" LSS "0" goto check_yyyymmdd_try
if "%TEST:~3,1%" GTR "9" goto check_yyyymmdd_try
if "%TEST:~3,1%" LSS "0" goto check_yyyymmdd_try
if "%TEST:~4,1%" GTR "9" goto check_yyyymmdd_try
if "%TEST:~4,1%" LSS "0" goto check_yyyymmdd_try
if "%TEST:~5,1%" GTR "9" goto check_yyyymmdd_try
if "%TEST:~5,1%" LSS "0" goto check_yyyymmdd_try
if "%TEST:~6,1%" GTR "9" goto check_yyyymmdd_try
if "%TEST:~6,1%" LSS "0" goto check_yyyymmdd_try
if "%TEST:~7,1%" GTR "9" goto check_yyyymmdd_try
if "%TEST:~7,1%" LSS "0" goto check_yyyymmdd_try

:: Если после YYYYMMDD ничего нет - не пытаемся вставлять _
set "REST=%BASE:~8%"
if not defined REST goto check_yyyymmdd_try

:: Пропускаем пробелы, _, - в начале REST
set "JUNK=%REST%"
:skip_junk_try
if not defined JUNK goto check_yyyymmdd_try
if "%JUNK:~0,1%"==" " set "JUNK=%JUNK:~1%" & goto skip_junk_try
if "%JUNK:~0,1%"=="_" set "JUNK=%JUNK:~1%" & goto skip_junk_try
if "%JUNK:~0,1%"=="-" set "JUNK=%JUNK:~1%" & goto skip_junk_try

:: Проверяем, начинается ли остаток с 6 цифр
set "HMSCAND=%JUNK:~0,6%"
if "%HMSCAND:~5,1%"=="" goto check_yyyymmdd_try
if "%HMSCAND:~0,1%" GTR "9" goto check_yyyymmdd_try
if "%HMSCAND:~0,1%" LSS "0" goto check_yyyymmdd_try

:: Всё ок - вставляем _ после YYYYMMDD, но очищаем REST от начальных пробелов/символов
set "CLEAN_REST=%REST%"
:clean_rest_junk_try
if not defined CLEAN_REST goto after_date_fix_try
if "%CLEAN_REST:~0,1%"==" " set "CLEAN_REST=%CLEAN_REST:~1%" & goto clean_rest_junk_try
if "%CLEAN_REST:~0,1%"=="_" set "CLEAN_REST=%CLEAN_REST:~1%" & goto clean_rest_junk_try
if "%CLEAN_REST:~0,1%"=="-" set "CLEAN_REST=%CLEAN_REST:~1%" & goto clean_rest_junk_try

:: Преобразуем YYYYMMDD в YYYY-MM-DD и вставляем _ после даты
set "BASE=%BASE:~0,4%-%BASE:~4,2%-%BASE:~6,2%_%CLEAN_REST%"
goto after_date_fix_try

:: --- Нормализация 2: YYYY-MM-DDHHMMSS (без разделителя) -> YYYY-MM-DD_HHMMSS ---
:check_yyyymmdd_try
set "TEST=%BASE:~0,10%"
if not defined TEST goto after_date_fix_try
if not "%TEST:~4,1%"=="-" goto after_date_fix_try
if not "%TEST:~7,1%"=="-" goto after_date_fix_try

:: Проверяем, что после даты есть как минимум 6 символов
if "%BASE:~15,1%"=="" goto after_date_fix_try

:: Проверяем, что первые 6 символов после даты - цифры
set "TIME_CAND=%BASE:~10,6%"
if "%TIME_CAND:~5,1%"=="" goto after_date_fix_try
if "%TIME_CAND:~0,1%" GTR "9" goto after_date_fix_try
if "%TIME_CAND:~0,1%" LSS "0" goto after_date_fix_try

:: Проверяем, что это валидное время (HH:MM:SS)
set "HH_TMP=%TIME_CAND:~0,2%"
set "MM_TMP=%TIME_CAND:~2,2%"
set "SS_TMP=%TIME_CAND:~4,2%"

:: CMD не понимает "08" как число - ошибка из-за ведущего нуля.
:: Приписываем "100" спереди, затем %% 100.
:: В CMD %% - это "остаток от ЦЕЛОЧИСЛЕННОГО деления" (только целые, без дробей!).
:: Пример: 10008 / 100 = 100 раз по 100 = 10000, остаток = 8 -> получаем число 8.
:: Работает для "8", "08", "23" - всегда даёт правильный результат.
set /a HH_CHK=100%HH_TMP% %% 100
set /a MM_CHK=100%MM_TMP% %% 100
set /a SS_CHK=100%SS_TMP% %% 100

if %HH_CHK% GTR 23 goto after_date_fix_try
if %MM_CHK% GTR 59 goto after_date_fix_try
if %SS_CHK% GTR 59 goto after_date_fix_try

:: Всё ок - вставляем _ после даты
set "BASE=%BASE:~0,10%_%BASE:~10%"
:after_date_fix_try
:: --- Вспомогательная метка для перехода из try_name_date ---
:: Используется только если BASE был изменён в попытке 1 или 2
:: После нормализации в YYYY-MM-DD_... - извлекаем дату и время
set "NAME_Y=%BASE:~0,4%"
set "NAME_M=%BASE:~5,2%"
set "NAME_D=%BASE:~8,2%"
call :check_date_format
:: Обнуляем NAME_* при невалидной дате, иначе мусор вроде "0110"/"no"/"TO"
:: обманет choose_date и подставит Y=0110 вместо DLM -> битое имя.
if not defined DATE_VALID (
    set "NAME_Y="
    set "NAME_M="
    set "NAME_D="
    exit /b
)

:: Дата валидна - пробуем извлечь время из позиции 11 (после YYYY-MM-DD_) только если это цифра
set "HMSCAND=%BASE:~11,6%"
if "%HMSCAND:~5,1%"=="" exit /b
if "%HMSCAND:~0,1%" GTR "9" exit /b
if "%HMSCAND:~0,1%" LSS "0" exit /b
call :check_time_format
if not defined TIME_VALID exit /b

:: Всё ОК - дата и время валидны
set "NAME_HH=%HH%"
set "NAME_MM=%MM%"
set "NAME_SS=%SS%"
exit /b





:check_date_format
:: Проверяем, что первые символы - цифры (минимальная защита)
if "%NAME_Y:~0,1%" GTR "9" exit /b
if "%NAME_Y:~0,1%" LSS "0" exit /b
if "%NAME_M:~0,1%" GTR "9" exit /b
if "%NAME_M:~0,1%" LSS "0" exit /b
if "%NAME_D:~0,1%" GTR "9" exit /b
if "%NAME_D:~0,1%" LSS "0" exit /b

set "Y_CHK="
set "M_CHK="
set "D_CHK="

:: CMD не понимает "08" как число - выдаёт ошибку из-за ведущего нуля.
:: Чтобы обойти: приписываем 10000 к году или 100 к месяцу/дню, затем %% N.
:: В CMD %% - это "остаток от ЦЕЛОЧИСЛЕННОГО деления" (дробей нет!).
:: Пример: 10008 / 100 = 100 раз по 100 (итого 10000), остаток = 8.
:: Так "08" -> 8, "2023" -> 2023, "7" -> 7 - всегда правильное число.
set /a Y_CHK=10000%NAME_Y% %% 10000
set /a M_CHK=100%NAME_M% %% 100
set /a D_CHK=100%NAME_D% %% 100

:: Минимальный и максимальный год
if %Y_CHK% LSS 1900 exit /b
if %Y_CHK% GTR 2100 exit /b
if %M_CHK% LSS 1 exit /b
if %M_CHK% GTR 12 exit /b
if %D_CHK% LSS 1 exit /b
if %D_CHK% GTR 31 exit /b

set "DATE_VALID=1"
exit /b






:check_time_format
:: Извлечение часов/минут/секунд из 6-символьной строки (например, 081234)
:: Проверяем длину - должно быть минимум 6 символов
if "%HMSCAND:~5,1%"=="" exit /b

:: Минимальная проверка - первый символ каждой пары должен быть цифрой
if "%HMSCAND:~0,1%" GTR "9" exit /b
if "%HMSCAND:~0,1%" LSS "0" exit /b
if "%HMSCAND:~2,1%" GTR "9" exit /b
if "%HMSCAND:~2,1%" LSS "0" exit /b
if "%HMSCAND:~4,1%" GTR "9" exit /b
if "%HMSCAND:~4,1%" LSS "0" exit /b

:: Извлекаем HH, MM, SS с обходом ведущих нулей
set "HH_CHK="
set "MM_CHK="
set "SS_CHK="

:: CMD не понимает "08" как число - ошибка из-за ведущего нуля.
:: Приписываем "100" к 2-символьному фрагменту, затем %% 100.
:: В CMD %% - это "остаток от ЦЕЛОЧИСЛЕННОГО деления" (дробей нет, только целые!).
:: Пример: 10008 / 100 = 100 раз по 100 = 10000, остаток = 8 -> число 8.
:: Безопасно: HMSCAND содержит только цифры, длина = 2.
set /a HH_CHK=100%HMSCAND:~0,2% %% 100
set /a MM_CHK=100%HMSCAND:~2,2% %% 100
set /a SS_CHK=100%HMSCAND:~4,2% %% 100

:: Проверяем диапазоны
if %HH_CHK% GTR 23 exit /b
if %MM_CHK% GTR 59 exit /b
if %SS_CHK% GTR 59 exit /b

:: Форматируем с ведущими нулями
set "HH=%HH_CHK%"
if %HH_CHK% LSS 10 set "HH=0%HH_CHK%"
set "MM=%MM_CHK%"
if %MM_CHK% LSS 10 set "MM=0%MM_CHK%"
set "SS=%SS_CHK%"
if %SS_CHK% LSS 10 set "SS=0%SS_CHK%"

set "TIME_VALID=1"
exit /b





:choose_date
:: Источники по приоритету: имя, DLM
:: При DTOALL=1: автоматически записываем EXIF в JPG без DTO и пропускаем диалог

:: Извлекаем дату и время из имени
call :try_name_date

:: --- DTOALL: флаг для автоматической обработки ---
:: Устанавливается в [a], но EXIF записывается ТОЛЬКО в handle_a_choice
:: Здесь - не вызываем :do_write, только проверяем, нужно ли показывать диалог
if not defined DTOALL goto check_jpg
:: DTOALL=1: все последующие JPG без DTO будут обработаны автоматически (после [a])
if not defined ISJPG goto check_jpg
if defined DTO goto check_jpg
:: Если DTOALL=1 и это JPG без DTO - записываем EXIF и используем DLM
call :do_write
call :load_dlm_vars
goto build_name

:: --- JPG: решаем, спрашивать ли пользователя ---
:check_jpg
if not defined ISJPG goto use_name_or_dlm

:: Если это JPG без EXIF и с полной датой в имени - используем её, не спрашивая
if not defined DTO goto ask_user
if not defined NAME_Y goto ask_user
if not defined NAME_HH goto ask_user
goto use_name_full

:: --- Основная логика выбора даты (для не-JPG и некоторых JPG) ---
:use_name_or_dlm
:: Если в имени есть полная дата и время - используем их
if not defined NAME_Y goto use_dlm
if not defined NAME_HH goto use_name_date_dlm_time
goto use_name_full

:: --- Полная дата и время найдены в имени файла - используем их ---
:: Пример: 2021-07-04_174724.txt - Y=2021, M=07, D=04, HH=17, MM=47, SS=24
:use_name_full
set "Y=%NAME_Y%"
set "M=%NAME_M%"
set "D=%NAME_D%"
set "HH=%NAME_HH%"
set "MM=%NAME_MM%"
set "SS=%NAME_SS%"
goto build_name

:: --- Дата в имени есть, но времени нет - подставляем время из DLM ---
:: Пример: 2021-07-04_Photo.txt - Y=2021, M=07, D=04, HH=12, MM=34, SS=56 (из DLM)
:use_name_date_dlm_time
call :get_dlm
set "Y=%NAME_Y%"
set "M=%NAME_M%"
set "D=%NAME_D%"
set "HH=%HH_DLM%"
set "MM=%MM_DLM%"
set "SS=%SS_DLM%"
goto build_name

:: --- Ни даты, ни времени не найдено в имени - используем полный DLM ---
:: Пример: Photo_001.jpg - всё из DateLastModified
:use_dlm
call :load_dlm_vars
goto build_name






:ask_user
:: Извлекаем DLM текущего файла в отдельные переменнные через VBS-код созданный в начале работы
:: Цель: гарантировать доступность Y_DLM, HH_DLM и т.д. в ask_user и других блоках
call :get_dlm

:: --- Формируем строку для отображения пользователю ---
:: Варианты:
:: 1. Полная дата и время в имени - берём всё из имени
:: 2. Только дата в имени - дата из имени, время из DLM
:: 3. Ничего не извлечено - только DLM
:: Переменная YMDHMS_NAME используется ТОЛЬКО для вывода, не влияет на переименование
echo(--- Нет EXIF.DateTimeOriginal (DTO) в "%FN%" ---
echo(
set "YMDHMS_NAME="

:: Ни даты, ни времени не извлечено из имени - показываем DLM
if not defined NAME_Y (
    set "YMDHMS_NAME=%Y_DLM%-%M_DLM%-%D_DLM% %HH_DLM%:%MM_DLM%:%SS_DLM%"
    goto show_user
)

:: --- Дата в имени есть, но времени нет - показываем: дата из имени, время из DLM
if not defined NAME_HH (
    set "YMDHMS_NAME=%NAME_Y%-%NAME_M%-%NAME_D% %HH_DLM%:%MM_DLM%:%SS_DLM%"
    goto show_user
)

:: Есть и дата, и время в имени - показываем их
set "YMDHMS_NAME=%NAME_Y%-%NAME_M%-%NAME_D% %NAME_HH%:%NAME_MM%:%NAME_SS%"

:: YMDHMS_NAME - только для отображения, не влияет на логику
:show_user
echo(Предлагаемая дата-время: %YMDHMS_NAME%
echo(Дата изменения файла (DLM): %Y_DLM%-%M_DLM%-%D_DLM% %HH_DLM%:%MM_DLM%:%SS_DLM%
echo(
echo([a] - записать предложенное в EXIF для всех JPG без DTO
echo([w] - записать предложенное в EXIF
echo([m] - ввести DTO вручую
echo(Любая другая клавиша - пропустить
set /p "USRCHOICE=Выбор: "

if /i "%USRCHOICE%"=="a" goto handle_a_choice
if /i "%USRCHOICE%"=="w" (
    call :do_write
    goto build_name
)
if /i "%USRCHOICE%"=="m" goto manual_input_start
echo(Отменена запись в EXIF.
goto file_skip

:manual_input_start
:: Ручной ввод пользователя
set "MANUAL="
echo(
echo(Введите дату ГГГГ-ММ-ДД ЧЧ:ММ:СС или [q] для отмены
set /p "MANUAL=Дата: "
if /i not "%MANUAL%"=="q" goto chk_man
echo(Отменён ручной ввод.
goto file_skip

:chk_man
:: Проверка формата через временный файл
set "MAN=%temp%\%CMDN%-man-%random%%random%.tmp"
echo(%MANUAL%>"%MAN%"
:: Не отрывать строку findstr от errorlevel
findstr /r "^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]$" "%MAN%" >nul
if %ERRORLEVEL% EQU 1 (
    echo(
    echo(Неверный формат. Пример: 2023-12-31 23:59:59
    echo(
    goto manual_input_start
)
if exist "%MAN%" del "%MAN%"

:: --- Начало обработки ручного ввода ---
:: Проверяем, что дата в формате ГГГГ-ММ-ДД ЧЧ:ММ:СС
:: Удаляем кавычки и проверяем формат через временный файл
set "DT_VALID=1"
set "Y=%MANUAL:~0,4%"
set "M=%MANUAL:~5,2%"
set "D=%MANUAL:~8,2%"
set "H_TMP=%MANUAL:~11,2%"
set "MM=%MANUAL:~14,2%"
set "S_TMP=%MANUAL:~17,2%"

:: Часы и секунды - удаляем пробелы: " 8" -> "8" - чтобы обработать ввод без ведущих нулей
set "H_TMP=%H_TMP: =%"
set "S_TMP=%S_TMP: =%"

:: Проверяем - если второй символ отсутствует - значит, число однозначное
:: Восстанавливаем ведущий ноль для однозначных часов: "8" -> "08", "12" -> "12"
if "%H_TMP:~1,1%"=="" set "HH=0%H_TMP%" & goto after_hh_manual
set "HH=%H_TMP%"
:after_hh_manual

:: --- Добавляем ведущий ноль для однозначных секунд ---
:: Аналогично часам
if "%S_TMP:~1,1%"=="" set "SS=0%S_TMP%" & goto after_ss_manual
set "SS=%S_TMP%"
:after_ss_manual
:: --- Проверка корректности даты и времени ---
:: Месяц: 1-12, день: 1-31, час: 0-23, минуты/секунды: 0-59
:: Не проверяем високосные года или дни в месяце - слишком сложно для CMD
:: Достаточно проверки диапазонов: 1-31 день, 1-12 месяц
if %M% LSS 1 set "DT_VALID=0"
if %M% GTR 12 set "DT_VALID=0"
if %D% LSS 1 set "DT_VALID=0"
if %D% GTR 31 set "DT_VALID=0"
if %HH% GTR 23 set "DT_VALID=0"
if %MM% GTR 59 set "DT_VALID=0"
if %SS% GTR 59 set "DT_VALID=0"

:: --- Если дата некорректна - возвращаемся к вводу ---
:: Пользователь может исправить ошибку
if %DT_VALID% EQU 0 (
    echo(Недопустимые значения даты/времени.
    echo(
    goto manual_input_start
)
:: Ввод успешен и проверен - переходим к записи EXIF и переименованию файла
call :do_write
goto build_name

:: --- Обработка юзер-выбора [a] ---
:handle_a_choice
:: После [a] - DTOALL=1, и все последующие JPG без DTO будут обработаны автоматически
set "DTOALL=1"
if not defined ISJPG goto skip_a_write
if defined DTO goto skip_a_write
call :do_write
:skip_a_write
call :load_dlm_vars
goto build_name








:do_write
echo(Записываем DateTimeOriginal=%Y%-%M%-%D% %HH%:%MM%:%SS% в %FN%
"%EX%" -M"set Exif.Photo.DateTimeOriginal %Y%-%M%-%D% %HH%:%MM%:%SS%" "%FN%"
set /a CNTT+=1
exit /b







:build_name
:: --- Формирование YMDHMS ---
:: К этому моменту Y, M, D, HH, MM, SS гарантированно валидны:
::  - из EXIF (с проверкой диапазонов)
::  - из имени (через check_date_format и check_time_format )
::  - из DLM (через VBS)
set "YMDHMS=%Y%-%M%-%D%_%HH%%MM%%SS%"

:: Удаление исходных "дублей" - дата + 1 символ (любой разделитель), затем время
:: Эти условия работают ТОЛЬКО ПОСЛЕ того, как дата/время уже утверждены
:: как валидные и использованы в YMDHMS. Не путать с парсингом в try_name_date!
if "%BASE:~0,10%"=="%Y%-%M%-%D%" set "BASE=%BASE:~11%"
if "%BASE:~0,6%"=="%HH%%MM%%SS%" set "BASE=%BASE:~6%"

:: Если BASE пуст - не добавляем _
if not defined BASE (
    set "NAMEBASE=%YMDHMS%"
    goto after_base
)

:: Обработка первого символа BASE: только одна ветка срабатывает
if "%BASE:~0,1%"=="_" goto plain_base
if "%BASE:~0,1%"==" " (
    set "BASE=_%BASE:~1%"
    goto plain_base
)
if "%BASE:~0,1%"=="-" (
    set "BASE=_%BASE:~1%"
    goto plain_base
)
:: По умолчанию - добавляем _ между датой и именем
set "NAMEBASE=%YMDHMS%_%BASE%"
goto after_base
:plain_base
set "NAMEBASE=%YMDHMS%%BASE%"
:after_base

:: Если имя не изменилось - пропускаем
set "FINALNAME=%NAMEBASE%%EXT%"
if /i "%FINALNAME%"=="%FN%" goto file_skip
if not exist "%FINALNAME%" goto do_rename

:: Если имя занято - ищем _1, _2 и т.д. до свободного
set "I=1"
:conflict_loop
set "FINALNAME=%NAMEBASE%_%I%%EXT%"
if exist "%FINALNAME%" (
    set /a I+=1
    goto conflict_loop
)

:do_rename
ren "%FN%" "%FINALNAME%"
echo(%FN% -^> %FINALNAME%
set /a CNT+=1
exit /b






:load_dlm_vars
call :get_dlm
set "Y=%Y_DLM%"
set "M=%M_DLM%"
set "D=%D_DLM%"
set "HH=%HH_DLM%"
set "MM=%MM_DLM%"
set "SS=%SS_DLM%"
exit /b






:get_dlm
:: Извлечение DateLastModified через VBS, независимо от локали ОС
:: Проверяем задан ли уже год - это защита от повторного вызова VBS
if defined Y_DLM exit /b
for /f "tokens=1-6" %%a in ('cscript //nologo "%DLMV%" "%FN%"') do (
    set "Y_DLM=%%a"
    set "M_DLM=%%b"
    set "D_DLM=%%c"
    set "HH_DLM=%%d"
    set "MM_DLM=%%e"
    set "SS_DLM=%%f"
)
exit /b






:file_skip
:: Единая точка выхода для всех случаев пропуска файла
echo(%FN% - пропущен, переименование не требуется.
exit /b
:: === ЗАВЕРШЕНИЕ БЛОКА ПОДПРОГРАММ ===






:: === ПРОДОЛЖЕНИЕ ОСНОВНОГО КОДА ===
:done
:: Метка done основного кода перемещена в конец, чтобы CMD "увидел" все метки подпрограмм до их вызова
:: Это ограничение интерпретатора CMD - метки для вызова должны быть объявлены до их вызова.
popd
if exist "%DLMV%" del "%DLMV%"
set "TXT_ALL="
set "TXT_DTO="
echo(
echo(--- Готово ---
if %CNT% gtr 0 set "TXT_ALL=Переименовано файлов: %CNT% из %CNTALL%"
if %CNTT% gtr 0 set "TXT_DTO=Добавлено EXIF-дат в файлы: %CNTT%"
if %CNT% gtr 0 echo(%TXT_ALL%
if %CNTT% gtr 0 echo(%TXT_DTO%
set "HF=%temp%\%CMDN%-hlp-%random%%random%.txt"
set "VB=%temp%\%CMDN%-hlp-%random%%random%.vbs"
>"%HF%" echo(%VRS%
>>"%HF%" echo(%CMDN% закончил работу.
>>"%HF%" echo(
>>"%HF%" echo(%TXT_ALL%
>>"%HF%" echo(
>>"%HF%" echo(%TXT_DTO%
>"%VB%" echo(With CreateObject("ADODB.Stream"):.Type=2:.Charset="cp866"
>>"%VB%" echo(.Open:.LoadFromFile"%HF%":MsgBox .ReadText,,"%CMDN%":.Close:End With
cscript //nologo "%VB%"
del "%VB%" & del "%HF%"
pause
exit /b
