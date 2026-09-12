@echo off
set "DO=Media Renamer"
title Froz %DO%
set "VRS=Froz %DO% v04.08.2026"
echo(%VRS%
echo(
set "VCR=%~dp0bin\VC_redist.x64.exe"
if exist "%SystemRoot%\System32\vcruntime140_1.dll" goto vcok
if not exist "%VCR%" (
    echo("%VCR%" не найден, выходим.
    echo(Ссылка для скачивания - в readme.txt.
    echo(& pause & exit /b
)
echo(Компоненты Visual C++ не найдены.
echo(Начата установка "%VCR%"...
echo(Потребуется подтверждение администратором в окне повышения прав!
echo(
rem Запуск установки в тихом режиме с ожиданием завершения
start /wait "" "%VCR%" /q /norestart
rem Повторная проверка после установки
if not exist "%SystemRoot%\System32\vcruntime140_1.dll" (
    echo(Установка "%VCR%" завершилась с ошибкой или требует перезагрузки, выходим.
    echo(& pause & exit /b
)
echo(Компоненты Visual C++ успешно установлены.
echo(
:vcok
set "EX=%~dp0bin\exiv2.exe"
if exist "%EX%" goto exok
echo(
echo(Не найден "%EX%". Положите exiv2.exe и exiv2.dll в папку bin.
echo(
pause
exit /b
:exok
if not "%~1"=="" goto work
echo(Пакетное переименование файлов по маске: ГГГГ-ММ-ДД_ЧЧММСС_имя.ext
echo(
echo(Перетащите папку или файлы на скрипт.
echo(Если первый аргумент - папка, обработает все файлы в ней.
echo(
echo(ВНИМАНИЕ! cmd.exe ограничивает командную строку 8191 символом (путь к скрипту + файлы).
echo(При превышении лимита скрипт молча закроется при старте. В лимит влезает 100-200 файлов.
echo(Надёжнее перетаскивать папку с файлами.
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

:work
rem === КОММЕНТАРИИ К ЛОГИКЕ РАБОТЫ ===
rem Приоритет дат - EXIF.DTO > имя (дата_время) > имя (дата) + DLM > DLM
rem DTOALL - флаг после [a] - автоматически пишет EXIF в JPG без DTO
rem Конфликты - добавляет _1, _2...
set "CMDN=%~n0"

rem Создаём один раз VBS-код для запроса DLM в отдельные переменные, способом не зависящим от локали
rem Формат выдачи VBS - ГГГГ ММ ДД ЧЧ ММ СС
set "DLMV=%temp%\%CMDN%-dlm-%random%%random%.vbs"
>"%DLMV%"  echo(With CreateObject("Scripting.FileSystemObject")
>>"%DLMV%" echo(Set f=.GetFile(WScript.Arguments.Item(0)):dt=f.DateLastModified
>>"%DLMV%" echo(Y=Year(dt):M=Right("0"^&Month(dt),2):D=Right("0"^&Day(dt),2)
>>"%DLMV%" echo(H=Right("0"^&Hour(dt),2):N=Right("0"^&Minute(dt),2):S=Right("0"^&Second(dt),2)
>>"%DLMV%" echo(WScript.Echo Y^&" "^&M^&" "^&D^&" "^&H^&" "^&N^&" "^&S:End With

rem Глобальные счётчики - CNT=переименовано, CNTALL=всего, CNTT=EXIF записано
rem DTOALL - флаг диалога с юзером "записать DTO во все последующие файлы без DTO"
set "CNT=0" & set "CNTALL=0" & set "CNTT=0" & set "DTOALL="

rem Определение режима работы - 'папка' или 'файлы'
set "ATTR=%~a1"
if /i "%ATTR:~0,1%"=="d" goto mode_folder

rem Режим работы - Список файлов
set "FLD=%~dp1"
pushd "%FLD%"
echo(Обработка списка файлов...
echo(

rem Цикл работы по файлам
:loop
if "%~1"=="" goto done
rem Если среди файлов встретится папка - пропускаем её
set "ATTR=%~a1"
if /i "%ATTR:~0,1%"=="d" goto next
set "FN=%~nx1"
call :process_file
:next
shift
goto loop

rem Режим работы - Папка
:mode_folder
pushd "%~f1"
echo(Обработка папки "%~f1"...
echo(
rem Обработка файлов в папке (папок среди них быть не может - это исключает dir /a-d)
for /f "delims=" %%i in ('dir /b /a-d') do (
    set "FN=%%i"
    call :process_file    
)

:done
popd
if exist "%DLMV%" del "%DLMV%"
set "TXT_ALL="
set "TXT_DTO="
echo(
echo(--- Готово ---
if %CNT% GTR 0 set "TXT_ALL=Переименовано файлов: %CNT% из %CNTALL%"
if %CNTT% GTR 0 set "TXT_DTO=Добавлено EXIF-дат в файлы: %CNTT%"
if %CNT% GTR 0 echo(%TXT_ALL%
if %CNTT% GTR 0 echo(%TXT_DTO%
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
rem === ОКОНЧАНИЕ РАБОТЫ И ВЫХОД ===




rem === ПОДПРОГРАММЫ ===
:process_file
rem Обнуление переменных
set "BASE=" & set "EXT=" & set "DTO="
set "Y=" & set "M=" & set "D=" & set "HH=" & set "MM=" & set "SS="
set "NAME_Y=" & set "NAME_M=" & set "NAME_D=" & set "NAME_HH=" & set "NAME_MM=" & set "NAME_SS="
set "Y_DLM=" & set "M_DLM=" & set "D_DLM=" & set "HH_DLM=" & set "MM_DLM=" & set "SS_DLM="
set "JPG_MATCH=" & set "DTO_COMP=" & set "DTO_DATE="

for %%f in ("%FN%") do (
    set "BASE=%%~nf"
    set "EXT=%%~xf"
)

if "%EXT%"=="" exit /b

set /a CNTALL+=1

rem Используем флаг, т.к. он будет нужен ещё несколько раз
set "ISJPG="
if /i "%EXT%"==".jpg" set "ISJPG=1"
if /i "%EXT%"==".jpeg" set "ISJPG=1"
if not defined ISJPG goto choose_date

rem === Блок обработки EXIF ===
rem Для JPEG пробуем извлечь EXIF...
rem 1. Читаем EXIF.DateTimeOriginal
rem 2. Если нет - идём в choose_date
rem 3. Если есть - сравниваем с датой из имени
rem 4. Если не совпадает - переименовываем
rem 5. Если совпадает - оставляем
rem Пытаемся использовать EXIF.DateTimeOriginal как приоритетный источник
rem Извлекаем EXIF DTO с помощью exiv2
set "TDTO=%temp%\%CMDN%-dto-%random%%random%.txt"
"%EX%" -q -g Exif.Photo.DateTimeOriginal -Pv "%FN%" >"%TDTO%"
set /p "DTO=" <"%TDTO%"
if exist "%TDTO%" del "%TDTO%"

if not defined DTO goto choose_date

rem Извлекаем дату из EXIF в отдельные переменные
rem DTO имеет приоритет над именем - если совпадает, файл пропускается
rem Формат EXIF DateTimeOriginal - "YYYY:MM:DD HH:MM:SS" (именно двоеточия в дате, не дефисы -
rem но т.к. разделитель везде 1 символ, смещения не отличаются от "YYYY-MM-DD ...")
set "Y=%DTO:~0,4%" & set "M=%DTO:~5,2%" & set "D=%DTO:~8,2%"
set "HH=%DTO:~11,2%" & set "MM=%DTO:~14,2%" & set "SS=%DTO:~17,2%"

rem Проверка корректности EXIF-даты. Если дата невалидна - используем DLM
rem Битые EXIF: 0000:00:00, 2023:00:45, 9999:99:99 - отбрасываем, используем имя или DLM
call :validate_date_range
if not defined RANGE_VALID goto choose_date

set "DTO_COMP=%Y%-%M%-%D% %HH%:%MM%:%SS%"
set "DTO_DATE=%Y%-%M%-%D%"
call :try_name_date

rem Проверка - совпадает ли полная дата и время с EXIF и форматом маски
call :check_jpg_match full
if defined JPG_MATCH goto file_skip

rem Проверка - совпадает ли только дата без времени и формат
call :check_jpg_match date
if defined JPG_MATCH goto file_skip

rem Ничего не совпадает - переходим к переименованию
goto build_name

:choose_date
rem Источники по приоритету - имя, DLM
rem Извлекаем дату и время из имени
call :try_name_date

rem --- Не-JPG сразу используют обычный источник даты (имя или DLM), без диалога ---
if not defined ISJPG (
    call :apply_suggested_date
    goto build_name
)

rem --- JPG - DTOALL-автопуть (после [a] на предыдущем файле) ---
rem Устанавливается в [a], но EXIF реально пишется только здесь и в handle_a_choice
if not defined DTOALL goto check_jpg_dto_known
if defined DTO goto check_jpg_dto_known
call :apply_suggested_date
call :do_write
goto build_name

rem --- JPG без автопути - если в имени есть полная дата+время - используем её без диалога ---
:check_jpg_dto_known
if not defined DTO goto ask_user
if not defined NAME_Y goto ask_user
if not defined NAME_HH goto ask_user
call :use_name_full
goto build_name




:validate_date_range
rem CMD трактует "08"/"09" как восьмеричные и обрубает разбор до "0".
rem Чтобы обойти - приписываем 100/10000 спереди, затем берём остаток от деления (%%).
rem В CMD %% - это "остаток от ЦЕЛОЧИСЛЕННОГО деления" (только целые, без дробей!).
rem Пример: 10008 / 100 = 100 раз по 100 = 10000, остаток = 8 -> получаем число 8.
rem Так мы убираем ведущий ноль через SET /A.
set "RANGE_VALID=1"
if "%Y%"=="" (set "RANGE_VALID=" & exit /b)
if "%M%"=="" (set "RANGE_VALID=" & exit /b)
if "%D%"=="" (set "RANGE_VALID=" & exit /b)

set /a Y_CHK=10000%Y% %% 10000
set /a M_CHK=100%M% %% 100
set /a D_CHK=100%D% %% 100

if %Y_CHK% LSS 1900 set "RANGE_VALID="
if %Y_CHK% GTR 2100 set "RANGE_VALID="
if %M_CHK% LSS 1 set "RANGE_VALID="
if %M% GTR 12 set "RANGE_VALID="
if %D_CHK% LSS 1 set "RANGE_VALID="
if %D% GTR 31 set "RANGE_VALID="
if %HH% GTR 23 set "RANGE_VALID="
if %MM% GTR 59 set "RANGE_VALID="
if %SS% GTR 59 set "RANGE_VALID="
exit /b




:try_name_date
rem Нормализация BASE (приведение к единому формату для извлечения даты).
rem Норм-1: YYYYMMDD + HHMMSS -> приводим к YYYY-MM-DD_HHMMSS (удаляя мусорные разделители).
rem Норм-2: YYYY-MM-DDHHMMSS -> приводим к YYYY-MM-DD_HHMMSS.
rem Это нужно только для парсинга, проверка самого формата будет позже в check_jpg_match

rem Обнуление переменных
set "DATE_VALID="
set "TIME_VALID="

rem Удаляем префиксы (регистронезависимо) если имя начинается не с цифры
if "%BASE:~0,1%" GTR "9" goto do_prefixes
if "%BASE:~0,1%" LSS "0" goto do_prefixes
goto skip_prefixes
:do_prefixes
if /i "%BASE:IMG_=%" NEQ "%BASE%" set "BASE=%BASE:IMG_=%" & goto skip_prefixes
if /i "%BASE:VID_=%" NEQ "%BASE%" set "BASE=%BASE:VID_=%" & goto skip_prefixes
if /i "%BASE:DSC_=%" NEQ "%BASE%" set "BASE=%BASE:DSC_=%" & goto skip_prefixes
if /i "%BASE:PIC_=%" NEQ "%BASE%" set "BASE=%BASE:PIC_=%" & goto skip_prefixes
:skip_prefixes

rem Пытаемся извлечь дату и время из имени файла.

rem --- Выполнение Норм-1 ---
set "TEST=%BASE:~0,8%"

rem Быстрая проверка: первый символ должен быть цифрой, и строка должна быть длиной 8
if "%TEST:~7,1%"=="" goto check_yyyymmdd_try
if "%TEST:~0,1%" GTR "9" goto check_yyyymmdd_try
if "%TEST:~0,1%" LSS "0" goto check_yyyymmdd_try

rem Проверяем остальные символы минимально (только первый символ каждой пары)
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

rem Если после YYYYMMDD ничего нет - не пытаемся вставлять _
set "REST=%BASE:~8%"
if not defined REST goto check_yyyymmdd_try

rem Пропускаем пробелы, _, - в начале REST
set "JUNK=%REST%"
rem Здесь серия if вместо обратного goto-цикла для обхода бага парсера cmd.
rem Прыжки назад при вызове из-под цикла for при переполнении буфера cmd-парсера приводят к ошибке "метка не найдена".
if "%JUNK:~0,1%"==" " set "JUNK=%JUNK:~1%"
if "%JUNK:~0,1%"=="_" set "JUNK=%JUNK:~1%"
if "%JUNK:~0,1%"=="-" set "JUNK=%JUNK:~1%"
if "%JUNK:~0,1%"==" " set "JUNK=%JUNK:~1%"
if "%JUNK:~0,1%"=="_" set "JUNK=%JUNK:~1%"
if "%JUNK:~0,1%"=="-" set "JUNK=%JUNK:~1%"
if "%JUNK:~0,1%"==" " set "JUNK=%JUNK:~1%"
if "%JUNK:~0,1%"=="_" set "JUNK=%JUNK:~1%"
if "%JUNK:~0,1%"=="-" set "JUNK=%JUNK:~1%"
if "%JUNK:~0,1%"==" " set "JUNK=%JUNK:~1%"
if "%JUNK:~0,1%"=="_" set "JUNK=%JUNK:~1%"
if "%JUNK:~0,1%"=="-" set "JUNK=%JUNK:~1%"
if not defined JUNK goto check_yyyymmdd_try

rem Проверяем, начинается ли остаток с 6 цифр
set "HMSCAND=%JUNK:~0,6%"
if "%HMSCAND:~5,1%"=="" goto check_yyyymmdd_try
if "%HMSCAND:~0,1%" GTR "9" goto check_yyyymmdd_try
if "%HMSCAND:~0,1%" LSS "0" goto check_yyyymmdd_try

rem Всё ок - вставляем _ после YYYYMMDD, но очищаем REST от начальных пробелов/символов
set "CLEAN_REST=%REST%"
rem Здесь серия if вместо обратного goto-цикла для обхода бага парсера cmd.
rem Прыжки назад при вызове из-под цикла for при переполнении буфера cmd-парсера приводят к ошибке "метка не найдена".
if "%CLEAN_REST:~0,1%"==" " set "CLEAN_REST=%CLEAN_REST:~1%"
if "%CLEAN_REST:~0,1%"=="_" set "CLEAN_REST=%CLEAN_REST:~1%"
if "%CLEAN_REST:~0,1%"=="-" set "CLEAN_REST=%CLEAN_REST:~1%"
if "%CLEAN_REST:~0,1%"==" " set "CLEAN_REST=%CLEAN_REST:~1%"
if "%CLEAN_REST:~0,1%"=="_" set "CLEAN_REST=%CLEAN_REST:~1%"
if "%CLEAN_REST:~0,1%"=="-" set "CLEAN_REST=%CLEAN_REST:~1%"
if "%CLEAN_REST:~0,1%"==" " set "CLEAN_REST=%CLEAN_REST:~1%"
if "%CLEAN_REST:~0,1%"=="_" set "CLEAN_REST=%CLEAN_REST:~1%"
if "%CLEAN_REST:~0,1%"=="-" set "CLEAN_REST=%CLEAN_REST:~1%"
if "%CLEAN_REST:~0,1%"==" " set "CLEAN_REST=%CLEAN_REST:~1%"
if "%CLEAN_REST:~0,1%"=="_" set "CLEAN_REST=%CLEAN_REST:~1%"
if "%CLEAN_REST:~0,1%"=="-" set "CLEAN_REST=%CLEAN_REST:~1%"
if not defined CLEAN_REST goto after_date_fix_try

rem Преобразуем YYYYMMDD в YYYY-MM-DD и вставляем _ после даты
set "BASE=%BASE:~0,4%-%BASE:~4,2%-%BASE:~6,2%_%CLEAN_REST%"
goto after_date_fix_try

rem --- Выполнение Норм-2 ---
:check_yyyymmdd_try
set "TEST=%BASE:~0,10%"
if not defined TEST goto after_date_fix_try
if not "%TEST:~4,1%"=="-" goto after_date_fix_try
if not "%TEST:~7,1%"=="-" goto after_date_fix_try

rem Проверяем, что после даты есть как минимум 6 символов
if "%BASE:~15,1%"=="" goto after_date_fix_try

rem Проверяем, что первые 6 символов после даты - цифры
set "TIME_CAND=%BASE:~10,6%"
if "%TIME_CAND:~5,1%"=="" goto after_date_fix_try
if "%TIME_CAND:~0,1%" GTR "9" goto after_date_fix_try
if "%TIME_CAND:~0,1%" LSS "0" goto after_date_fix_try

rem Проверяем, что это валидное время (HH:MM:SS)
set "HH_TMP=%TIME_CAND:~0,2%"
set "MM_TMP=%TIME_CAND:~2,2%"
set "SS_TMP=%TIME_CAND:~4,2%"

rem Обход бага CMD с ведущим нулём ("08" и "09"). Подробно см. в validate_date_range
set /a HH_CHK=100%HH_TMP% %% 100
set /a MM_CHK=100%MM_TMP% %% 100
set /a SS_CHK=100%SS_TMP% %% 100

if %HH_CHK% GTR 23 goto after_date_fix_try
if %MM_CHK% GTR 59 goto after_date_fix_try
if %SS_CHK% GTR 59 goto after_date_fix_try

rem Всё ок - вставляем _ после даты
set "BASE=%BASE:~0,10%_%BASE:~10%"
:after_date_fix_try
rem --- Вспомогательная метка для перехода из try_name_date ---
rem Используется только если BASE был изменён в попытке 1 или 2
rem После нормализации в YYYY-MM-DD_... - извлекаем дату и время
set "NAME_Y=%BASE:~0,4%"
set "NAME_M=%BASE:~5,2%"
set "NAME_D=%BASE:~8,2%"
call :check_date_format
rem Обнуляем NAME_* при невалидной дате, иначе мусор вроде "0110"/"no"/"TO"
rem обманет choose_date и подставит Y=0110 вместо DLM -> битое имя.
if not defined DATE_VALID (
    set "NAME_Y="
    set "NAME_M="
    set "NAME_D="
    exit /b
)

rem Дата валидна - пробуем извлечь время из позиции 11 (после YYYY-MM-DD_) только если это цифра
set "HMSCAND=%BASE:~11,6%"
if "%HMSCAND:~5,1%"=="" exit /b
if "%HMSCAND:~0,1%" GTR "9" exit /b
if "%HMSCAND:~0,1%" LSS "0" exit /b
call :check_time_format
if not defined TIME_VALID exit /b

rem Всё ОК - дата и время валидны
set "NAME_HH=%HH%" & set "NAME_MM=%MM%" & set "NAME_SS=%SS%"
exit /b




:check_jpg_match
rem Проверяем, соответствует ли ИСХОДНОЕ имя файла (с префиксами) маске ГГГГ-ММ-ДД_ЧЧММСС
rem И совпадает ли дата/время с EXIF. Если ДА - пропускаем.
rem Если в начале есть IMG_, VID_ и т.д. - имя НЕ соответствует маске - не пропускаем.

rem Проверяем, соответствует ли имя файла EXIF-дате и маске ГГГГ-ММ-ДД_ЧЧММСС - если да, пропускаем
rem %1 = full (требуется дата+время в имени) или date (достаточно даты)
if not defined NAME_Y exit /b
rem Если режим НЕ "full" (т.е. "date") - пропускаем проверку времени
if /i not "%~1"=="full" goto check_time_skip
rem В режиме "full" время в имени обязательно
if not defined NAME_HH exit /b
:check_time_skip

rem ВАЖНО: эти проверки дублируют часть логики из try_name_date,
rem но здесь они нужны ТОЛЬКО для подтверждения, что файл уже в целевом формате.
rem Если не соответствует - не пропускаем, даже если дата совпадает с EXIF.
rem Используем FN (а не BASE), чтобы префиксы вроде IMG_
rem ломали проверку формата и заставляли переименовывать файл, даже если дата совпадает с EXIF.

rem Проверка формата даты в имени: YYYY-MM-DD
set "PART=%FN:~0,10%"

rem Проверяем длину и разделители
if "%PART:~4,1%" NEQ "-" exit /b
if "%PART:~7,1%" NEQ "-" exit /b

rem Минимальная проверка: первый символ каждой части - цифра
rem (остальные символы отсеятся позже в check_date_format, если потребуется)
if "%PART:~0,1%" GTR "9" exit /b
if "%PART:~0,1%" LSS "0" exit /b
if "%PART:~5,1%" GTR "9" exit /b
if "%PART:~5,1%" LSS "0" exit /b
if "%PART:~8,1%" GTR "9" exit /b
if "%PART:~8,1%" LSS "0" exit /b

rem Проверка: после даты - подчёркивание
set "UNDERSCORE=%FN:~10,1%"
if not defined UNDERSCORE exit /b
if not "%UNDERSCORE%"=="_" exit /b

rem Проверка совпадения даты с EXIF
set "NAME_DATE=%NAME_Y%-%NAME_M%-%NAME_D%"
if not "%NAME_DATE%"=="%DTO_DATE%" exit /b

rem Если режим "только дата" - совпадение найдено
if /i "%~1"=="date" (
    set "JPG_MATCH=1"
    exit /b
)

rem Режим "full" - проверяем время
set "TIME_PART=%FN:~11,6%"
rem Проверяем длину времени (должно быть 6 символов)
if "%TIME_PART:~5,1%"=="" exit /b

rem Проверяем, что первый символ времени - цифра
if "%TIME_PART:~0,1%" GTR "9" exit /b
if "%TIME_PART:~0,1%" LSS "0" exit /b

rem Проверка совпадения полной даты+времени с EXIF
set "NAME_COMP=%NAME_Y%-%NAME_M%-%NAME_D% %NAME_HH%:%NAME_MM%:%NAME_SS%"
if not "%NAME_COMP%"=="%DTO_COMP%" exit /b

rem Полное совпадение
set "JPG_MATCH=1"
exit /b




:apply_suggested_date
rem Выбирает источник даты по приоритету: имя(дата+время) > имя(дата)+DLM > DLM.
rem Переиспользует те же use_name_full/use_name_date_dlm_time/use_dlm,
rem что и основной поток (use_name_or_dlm) - логика не дублируется.
if not defined NAME_Y (
    call :use_dlm
    exit /b
)
if not defined NAME_HH (
    call :use_name_date_dlm_time
    exit /b
)
call :use_name_full
exit /b




:use_name_full
rem --- Полная дата и время найдены в имени файла - используем их ---
set "Y=%NAME_Y%" & set "M=%NAME_M%" & set "D=%NAME_D%"
set "HH=%NAME_HH%" & set "MM=%NAME_MM%" & set "SS=%NAME_SS%"
exit /b




:use_name_date_dlm_time
rem --- Дата в имени есть, но времени нет - подставляем время из DLM ---
rem Пример: 2021-07-04_Photo.txt - Y=2021, M=07, D=04, HH=12, MM=34, SS=56 (из DLM)
call :get_dlm
set "Y=%NAME_Y%" & set "M=%NAME_M%" & set "D=%NAME_D%"
set "HH=%HH_DLM%" & set "MM=%MM_DLM%" & set "SS=%SS_DLM%"
exit /b




:use_dlm
rem --- Ни даты, ни времени не найдено в имени - используем полный DLM ---
rem Пример: Photo_001.jpg - всё из DateLastModified
call :get_dlm
set "Y=%Y_DLM%" & set "M=%M_DLM%" & set "D=%D_DLM%"
set "HH=%HH_DLM%" & set "MM=%MM_DLM%" & set "SS=%SS_DLM%"
exit /b




:ask_user
rem --- Формируем строку для отображения пользователю ---
rem Варианты:
rem 1. Полная дата и время в имени - берём всё из имени
rem 2. Только дата в имени - дата из имени, время из DLM
rem 3. Ничего не извлечено - только DLM
rem Переменная YMDHMS_NAME используется ТОЛЬКО для вывода, не влияет на переименование
echo(--- Нет EXIF.DateTimeOriginal (DTO) в "%FN%" ---
echo(
set "YMDHMS_NAME="

rem get_dlm нужен отдельно от диспетчера - use_name_full не трогает Y_DLM,
rem а строка "Дата изменения файла (DLM)" ниже показывается всегда.
call :get_dlm

rem Заполняем РЕАЛЬНЫЕ Y/M/D/HH/MM/SS - те же значения уйдут в EXIF при [w]/[a]
call :apply_suggested_date
set "YMDHMS_NAME=%Y%-%M%-%D% %HH%:%MM%:%SS%"
echo(Предлагаемая дата-время: %YMDHMS_NAME%
echo(Дата изменения файла (DLM): %Y_DLM%-%M_DLM%-%D_DLM% %HH_DLM%:%MM_DLM%:%SS_DLM%
echo(
echo([a] - записать предложенное в EXIF для всех JPG без DTO
echo([w] - записать предложенное в EXIF
echo([m] - ввести DTO вручную
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
rem Ручной ввод пользователя
set "MANUAL="
echo(
echo(Введите дату ГГГГ-ММ-ДД ЧЧ:ММ:СС или [q] для отмены
set /p "MANUAL=Дата: "
if /i not "%MANUAL%"=="q" goto chk_man
echo(Отменён ручной ввод.
goto file_skip

:chk_man
rem Проверка формата через временный файл
set "MAN=%temp%\%CMDN%-man-%random%%random%.tmp"
echo(%MANUAL%>"%MAN%"
rem Не отрывать строку findstr от errorlevel
findstr /r "^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]$" "%MAN%" >nul
if %ERRORLEVEL% EQU 1 (
    echo(
    echo(Неверный формат. Пример: 2023-12-31 23:59:59
    echo(
    goto manual_input_start
)
if exist "%MAN%" del "%MAN%"

rem --- Начало обработки ручного ввода ---
rem Удаляем кавычки и проверяем формат через временный файл
set "Y=%MANUAL:~0,4%" & set "M=%MANUAL:~5,2%" & set "D=%MANUAL:~8,2%"
set "HH=%MANUAL:~11,2%" & set "MM=%MANUAL:~14,2%" & set "SS=%MANUAL:~17,2%"
call :validate_date_range
if not defined RANGE_VALID (
    echo(Недопустимые значения даты/времени.
    echo(
    goto manual_input_start
)

rem Ввод успешен и проверен - переходим к записи EXIF и переименованию файла
call :do_write
goto build_name

rem --- Обработка юзер-выбора [a] ---
:handle_a_choice
rem Проверка флага DTOALL для автоматической обработки (описание см. в начале файла)
set "DTOALL=1"
if not defined ISJPG goto skip_a_write
if defined DTO goto skip_a_write
call :do_write
:skip_a_write
goto build_name




:do_write
echo(Записываем DateTimeOriginal=%Y%-%M%-%D% %HH%:%MM%:%SS% в %FN%
"%EX%" -M"set Exif.Photo.DateTimeOriginal %Y%-%M%-%D% %HH%:%MM%:%SS%" "%FN%"
set /a CNTT+=1
exit /b




:build_name
rem --- Формирование YMDHMS ---
rem К этому моменту Y, M, D, HH, MM, SS гарантированно валидны:
rem  - из EXIF (с проверкой диапазонов)
rem  - из имени (через check_date_format и check_time_format )
rem  - из DLM (через VBS)
set "YMDHMS=%Y%-%M%-%D%_%HH%%MM%%SS%"

rem Убираем задублированную дату из BASE - подробности в :dedup_date
call :dedup_date
if "%BASE:~0,6%"=="%HH%%MM%%SS%" set "BASE=%BASE:~6%"

rem Если BASE пуст - не добавляем _
if not defined BASE (
    set "NAMEBASE=%YMDHMS%"
    goto after_base
)

rem Обработка первого символа BASE: только одна ветка срабатывает
if "%BASE:~0,1%"=="_" goto plain_base
if "%BASE:~0,1%"==" " (
    set "BASE=_%BASE:~1%"
    goto plain_base
)
if "%BASE:~0,1%"=="-" (
    set "BASE=_%BASE:~1%"
    goto plain_base
)
rem По умолчанию - добавляем _ между датой и именем
set "NAMEBASE=%YMDHMS%_%BASE%"
goto after_base
:plain_base
set "NAMEBASE=%YMDHMS%%BASE%"
:after_base

rem Если имя не изменилось - пропускаем
set "FINALNAME=%NAMEBASE%%EXT%"
if /i "%FINALNAME%"=="%FN%" goto file_skip
if not exist "%FINALNAME%" goto do_rename

rem Если имя занято - ищем _1, _2 и т.д. до свободного
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




:dedup_date
rem Убираем задублированную дату из начала BASE.
rem Если сразу после даты идёт НАСТОЯЩИЙ разделитель (_, пробел, -) - убираем и его
rem (было "ДАТА_остаток" - именно так выглядит BASE после try_name_date в норме).
rem Если разделителя там нет (try_name_date распознал только дату, а время в имени
rem было невалидным - Норм-2 не вставляла "_") - убираем ТОЛЬКО дату,
rem не трогая первый символ остатка. Раньше здесь терялась цифра
rem (пример: "2022-08-047747245.jpg" -> "747245" вместо "7747245").
if not "%BASE:~0,10%"=="%Y%-%M%-%D%" exit /b
if "%BASE:~10,1%"=="_" set "BASE=%BASE:~11%" & exit /b
if "%BASE:~10,1%"==" " set "BASE=%BASE:~11%" & exit /b
if "%BASE:~10,1%"=="-" set "BASE=%BASE:~11%" & exit /b
set "BASE=%BASE:~10%"
exit /b




:get_dlm
rem Извлечение DateLastModified через VBS, независимо от локали ОС
rem Проверяем задан ли уже год - это защита от повторного вызова VBS
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
rem Единая точка выхода для всех случаев пропуска файла
echo(%FN% - пропущен, переименование не требуется.
exit /b




:check_date_format
rem Проверяем, что первые символы - цифры (минимальная защита)
if "%NAME_Y:~0,1%" GTR "9" exit /b
if "%NAME_Y:~0,1%" LSS "0" exit /b
if "%NAME_M:~0,1%" GTR "9" exit /b
if "%NAME_M:~0,1%" LSS "0" exit /b
if "%NAME_D:~0,1%" GTR "9" exit /b
if "%NAME_D:~0,1%" LSS "0" exit /b

set "Y_CHK=" & set "M_CHK=" & set "D_CHK="

rem Обход бага CMD с ведущим нулём ("08" и "09"). Подробно см. в validate_date_range
set /a Y_CHK=10000%NAME_Y% %% 10000
set /a M_CHK=100%NAME_M% %% 100
set /a D_CHK=100%NAME_D% %% 100

rem Минимальный и максимальный год
if %Y_CHK% LSS 1900 exit /b
if %Y_CHK% GTR 2100 exit /b
if %M_CHK% LSS 1 exit /b
if %M_CHK% GTR 12 exit /b
if %D_CHK% LSS 1 exit /b
if %D_CHK% GTR 31 exit /b

set "DATE_VALID=1"
exit /b






:check_time_format
rem Извлечение часов/минут/секунд из 6-символьной строки (например, 081234)
rem Проверяем длину - должно быть минимум 6 символов
if "%HMSCAND:~5,1%"=="" exit /b

rem Минимальная проверка - первый символ каждой пары должен быть цифрой
if "%HMSCAND:~0,1%" GTR "9" exit /b
if "%HMSCAND:~0,1%" LSS "0" exit /b
if "%HMSCAND:~2,1%" GTR "9" exit /b
if "%HMSCAND:~2,1%" LSS "0" exit /b
if "%HMSCAND:~4,1%" GTR "9" exit /b
if "%HMSCAND:~4,1%" LSS "0" exit /b

rem Извлекаем HH, MM, SS с обходом ведущих нулей
set "HH_CHK=" & set "MM_CHK=" & set "SS_CHK="

rem Обход бага CMD с ведущим нулём ("08" и "09"). Подробно см. в validate_date_range
set /a HH_CHK=100%HMSCAND:~0,2% %% 100
set /a MM_CHK=100%HMSCAND:~2,2% %% 100
set /a SS_CHK=100%HMSCAND:~4,2% %% 100

rem Проверяем диапазоны
if %HH_CHK% GTR 23 exit /b
if %MM_CHK% GTR 59 exit /b
if %SS_CHK% GTR 59 exit /b

rem Форматируем с ведущими нулями
set "HH=%HH_CHK%"
if %HH_CHK% LSS 10 set "HH=0%HH_CHK%"
set "MM=%MM_CHK%"
if %MM_CHK% LSS 10 set "MM=0%MM_CHK%"
set "SS=%SS_CHK%"
if %SS_CHK% LSS 10 set "SS=0%SS_CHK%"

set "TIME_VALID=1"
exit /b