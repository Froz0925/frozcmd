@echo off
set "VERS=Froz media renamer v09.08.2025"

if not "%~1"=="" goto chk
echo(%VERS%
echo.
echo Пакетное переименование файлов по маске: YYYY-MM-DD_HHMMSS_имя_[PROGR].ext
echo.
echo Работает с:
echo   - EXIF в JPG ^(DTO^) - приоритет
echo   - Датой в имени файла ^(разные форматы, пробелы, разделители^)
echo   - Датой изменения файла ^(DLM^)
echo.
echo Особенности:
echo   - Помечает Progressive JPEG как _PROGR
echo   - Удаляет префиксы: IMG_, VID_, DSC_, PIC_
echo   - Не переименовывает файлы, уже соответствующие маске
echo   - При конфликтах имён добавляет _1, _2 и т.д.
echo   - Приоритет: EXIF ^> имя ^> DLM
echo.
echo Как использовать:
echo   Перетащите папку или файлы на скрипт.
echo   Если первый аргумент - папка, обработает все файлы в ней.
echo.
echo.
pause
exit /b

:chk
set "CMD=%*"
if "%CMD:~7000,1%" neq "" (
    echo.
    echo ВНИМАНИЕ: передано очень много файлов - лимит 8100 символов.
    echo Windows может обрезать список - часть файлов не будет обработана.
    echo.
    echo Рекомендуется перетащить папку с файлами, а не отдельные файлы.
    echo.
    pause
)

set "EXV=%~dp0bin\exiv2.exe"
if not exist "%EXV%" (
    echo.
    echo(Ошибка: Не найден "%EXV%".
    echo Положите exiv2.exe и exiv2.dll в папку bin рядом с cmd-файлом
    echo.
    pause
    exit /b
)

set "TV=%temp%\dltm$.vbs"
> "%TV%" echo Wscript.Echo CreateObject("Scripting.FileSystemObject").GetFile(WScript.Arguments.Item(0)).DateLastModified

set "CNT=0"
set "CNTALL=0"
set "CNTP=0"
set "CNTT=0"
set "DTOALL="

set "CMDN=%~nx0"
set "ATTR=%~a1"
set "ATTR=%ATTR:~,1%"
if /i "%ATTR%"=="d" goto mode_folder
goto mode_files


:: Режим работы: Список файлов
:mode_files
set "FLD=%~dp1"
pushd "%FLD%"
echo Обработка списка файлов...
echo --------------------------
goto start_loop



:: Цикл по файлам
:start_loop
if "%~1"=="" goto done
set "ATTR=%~a1"
set "ATTR=%ATTR:~,1%"
if /i "%ATTR%"=="d" goto next_arg
set "FN=%~nx1"
set /a CNTALL+=1
call :process_file
:next_arg
shift
goto start_loop


:: Режим работы: Папка
:mode_folder
set "FLD=%~f1"
pushd "%FLD%"
echo(Обработка папки "%FLD%"...
echo --------------------------------------------
echo.
set "LIST=%temp%\list_%random%.tmp"
dir /b /a-d "%FLD%\*" > "%LIST%" 2>nul
if not exist "%LIST%" goto done
for /f "usebackq delims=" %%i in ("%LIST%") do call :process_file_in_folder "%%i"
del "%LIST%"
goto done

:: Эту подпрограмму пришлось врезать в тело основного потока выше метки done иначе скрипт не видит эту метку
:process_file_in_folder
set "FN=%~1"
set /a CNTALL+=1
call :process_file
exit /b




:: === ПРОДОЛЖЕНИЕ ОСНОВНОГО ПОТОКА ===
:done
popd
if exist "%TV%" del "%TV%" >nul

set "TXT_ALL="
set "TXT_PROGR="
set "TXT_DTO="
echo.
echo(--- Готово ---
if %CNT% gtr 0 set "TXT_ALL=Переименовано: %CNT% из %CNTALL% файлов."
if %CNTP% gtr 0 set "TXT_PROGR=Помечено как PROGR: %CNTP% файлов."
if %CNTT% gtr 0 set "TXT_DTO=Добавлено EXIF-дат: %CNTT% файлов."
if %CNT% gtr 0 echo(%TXT_ALL%
if %CNTP% gtr 0 echo(%TXT_PROGR%
if %CNTT% gtr 0 echo(%TXT_DTO%

set "HF=%temp%\%CMDN%-hlp_%random%.txt"
set "VB=%temp%\%CMDN%-hlp_%random%.vbs"
if exist "%HF%" del "%HF%"
if exist "%VB%" del "%VB%"
>nul chcp 1251&>>"%HF%" (
  cmd /c echo(%CMDN% закончил работу.
  cmd /c echo.
  cmd /c echo(%TXT_ALL%
  cmd /c echo.
  cmd /c echo(%TXT_PROGR%
  cmd /c echo(%TXT_DTO%
)&>nul chcp 866
echo MsgBox CreateObject("Scripting.FileSystemObject").OpenTextFile("%HF%").ReadAll,,"%CMDN%">"%VB%"
start "" /wait "%VB%"
if exist "%VB%" del "%VB%"
if exist "%HF%" del "%HF%"
pause
exit /b 0
:: === КОНЕЦ ОСНОВНОГО ПОТОКА ===






:: === ПОДПРОГРАММЫ ===
:process_file
:: Инициализация переменных
set "BASE="
set "EXT="
set "DTO="
set "ISJPG="
set "Y=" & set "M=" & set "D=" & set "HH=" & set "MM=" & set "SS="

:: Получаем базовое имя и расширение
for %%f in ("%FN%") do set "BASE=%%~nf"
for %%f in ("%FN%") do set "EXT=%%~xf"

:: Пропускаем файлы без расширения
if "%EXT%"=="" exit /b

:: Удаляем префиксы (регистронезависимо)
if /i "%BASE:IMG_=%" neq "%BASE%" set "BASE=%BASE:IMG_=%"
if /i "%BASE:VID_=%" neq "%BASE%" set "BASE=%BASE:VID_=%"
if /i "%BASE:DSC_=%" neq "%BASE%" set "BASE=%BASE:DSC_=%"
if /i "%BASE:PIC_=%" neq "%BASE%" set "BASE=%BASE:PIC_=%"

:: --- Попытка вставить _ между датой и временем ---
:: Формат: YYYYMMDD[разделитель]HHMMSS
set "TEST=%BASE:~0,8%"
echo(%TEST%| findstr /r "^[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]$" >nul
if errorlevel 1 goto check_yyyymmdd

set "REST=%BASE:~8%"
if not defined REST goto check_yyyymmdd

:: Пропускаем пробелы, _, - в начале REST
set "JUNK=%REST%"
:skip_junk
if not defined JUNK goto check_yyyymmdd
if "%JUNK:~0,1%"==" " set "JUNK=%JUNK:~1%" & goto skip_junk
if "%JUNK:~0,1%"=="_" set "JUNK=%JUNK:~1%" & goto skip_junk
if "%JUNK:~0,1%"=="-" set "JUNK=%JUNK:~1%" & goto skip_junk

:: Проверяем, начинается ли остаток с 6 цифр
if "%JUNK:~5,1%"=="" goto check_yyyymmdd
set "HMSCAND=%JUNK:~0,6%"
echo(%HMSCAND%| findstr /r "^[0-9][0-9][0-9][0-9][0-9][0-9]$" >nul
if errorlevel 1 goto check_yyyymmdd

:: Всё ок - вставляем _ после YYYYMMDD, но очищаем REST от начальных пробелов/символов
set "CLEAN_REST=%REST%"
:clean_rest_junk
if not defined CLEAN_REST goto after_clean_rest
if "%CLEAN_REST:~0,1%"==" " set "CLEAN_REST=%CLEAN_REST:~1%" & goto clean_rest_junk
if "%CLEAN_REST:~0,1%"=="_" set "CLEAN_REST=%CLEAN_REST:~1%" & goto clean_rest_junk
if "%CLEAN_REST:~0,1%"=="-" set "CLEAN_REST=%CLEAN_REST:~1%" & goto clean_rest_junk
:after_clean_rest
set "BASE=%BASE:~0,8%_%CLEAN_REST%"
goto after_date_fix

:check_yyyymmdd
:: Формат: YYYY-MM-DDHHMMSS
set "TEST=%BASE:~0,10%"
if not "%TEST:~4,1%"=="-" goto after_date_fix
if not "%TEST:~7,1%"=="-" goto after_date_fix
set "REST=%BASE:~10%"
if not defined REST goto after_date_fix
set "FIRST=%REST:~0,1%"
echo(%FIRST%| findstr "^[0-9]$" >nul
if errorlevel 1 goto after_date_fix
set "BASE=%BASE:~0,10%_%REST%"

:after_date_fix
:: Удаляем начальные символы: пробел, _, -
:trim_start
if "%BASE:~0,1%"==" " set "BASE=%BASE:~1%" & goto trim_start
if "%BASE:~0,1%"=="_" set "BASE=%BASE:~1%" & goto trim_start
if "%BASE:~0,1%"=="-" set "BASE=%BASE:~1%" & goto trim_start

:: Устанавливаем SUFFIX
set "SUFFIX=%BASE%"

:: Для JPEG пробуем извлечь EXIF данные
if /i "%EXT%"==".jpg" set "ISJPG=1"
if /i "%EXT%"==".jpeg" set "ISJPG=1"
if defined ISJPG goto ext_jpg

:: Для остальных файлов используем дату изменения
goto choose_date




:ext_jpg
:: Как это работает:
:: 1. Читаем EXIF.DateTimeOriginal
:: 2. Если нет - goto choose_date
:: 3. Если есть - сравниваем с датой из имени
:: 4. Если не совпадает - переименовываем
:: 5. Если совпадает - оставляем
set "TMP=%temp%\dto_%random%.txt"
"%EXV%" -q -g Exif.Photo.DateTimeOriginal -Pv "%FN%" > "%TMP%"
set /p "DTO=" < "%TMP%"
if exist "%TMP%" del "%TMP%" >nul

:: Если DTO нет - переходим к DLM
if not defined DTO goto choose_date

:: Извлекаем дату из EXIF
set "Y=%DTO:~0,4%"
set "M=%DTO:~5,2%"
set "D=%DTO:~8,2%"
set "HH=%DTO:~11,2%"
set "MM=%DTO:~14,2%"
set "SS=%DTO:~17,2%"

:: Проверка корректности EXIF-даты
:: Пример битых значений: 0000:00:00, 2023:00:45, 9999:99:99
:: Если дата невалидна - используем DLM
if "%Y%"=="" goto choose_date
if "%M%"=="" goto choose_date
if "%D%"=="" goto choose_date
if %M% lss 1 goto choose_date
if %M% gtr 12 goto choose_date
if %D% lss 1 goto choose_date
if %D% gtr 31 goto choose_date
if %HH% gtr 23 goto choose_date
if %MM% gtr 59 goto choose_date
if %SS% gtr 59 goto choose_date

set "DTO_COMP=%Y%-%M%-%D% %HH%:%MM%:%SS%"
set "DTO_DATE=%Y%-%M%-%D%"

call :extract_date_from_name

:: Если дата в имени извлечена - сравниваем
if not defined NAME_Y goto build_name
:: Если время в имени не извлечено - сравниваем только дату
if not defined NAME_HH goto ext_jpg_compare_date_only

:: --- Проверка: совпадает ли имя с главной маской? ---
:: Формат: YYYY-MM-DD_HHMMSS_...
set "MASK_PATTERN=____-__-__"
set "PART=%FN:~0,10%"
if not "%PART:~4,1%"=="-" goto build_name
if not "%PART:~7,1%"=="-" goto build_name
echo(%PART%| findstr /r "^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$" >nul
if errorlevel 1 goto build_name

:: Проверяем, что после даты - подчёркивание
if "%FN:~10,1%" neq "_" goto build_name

:: Проверяем, что после даты - 6 цифр времени
set "TIME_PART=%FN:~11,6%"
echo(%TIME_PART%| findstr /r "^[0-9][0-9][0-9][0-9][0-9][0-9]$" >nul
if errorlevel 1 goto build_name

:: --- Теперь проверяем совпадение даты ---
set "NAME_COMP=%NAME_Y%-%NAME_M%-%NAME_D% %NAME_HH%:%NAME_MM%:%NAME_SS%"
if not "%NAME_COMP%"=="%DTO_COMP%" goto build_name

:: --- Файл уже соответствует маске ---
echo(%FN% - пропущен, переименование не требуется.
echo.
exit /b



:ext_jpg_compare_date_only
:: Сравниваем только дату (время из имени не извлечено)
set "NAME_DATE=%NAME_Y%-%NAME_M%-%NAME_D%"
if not "%NAME_DATE%"=="%DTO_DATE%" goto build_name

:: --- Проверка формата маски для случая без времени ---
set "PART=%FN:~0,10%"
if not "%PART:~4,1%"=="-" goto build_name
if not "%PART:~7,1%"=="-" goto build_name
echo(%PART%| findstr /r "^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$" >nul
if errorlevel 1 goto build_name
if "%FN:~10,1%" neq "_" goto build_name

:: --- Файл уже соответствует маске ---
echo(%FN% - пропущен, переименование не требуется.
echo.
exit /b





:choose_date
:: Источники по приоритету: имя, DLM
:: При DTOALL=1: автоматически записываем EXIF в JPG без DTO и пропускаем диалог

:: Извлекаем DLM
for /f "delims=" %%t in ('cscript //nologo "%TV%" "%FN%"') do set "DT=%%t"

:: Парсим DLM: DD.MM.YYYY H:MM:SS или HH:MM:SS
set "D=%DT:~0,2%"
set "M=%DT:~3,2%"
set "Y=%DT:~6,4%"
set "HH=%DT:~11,2%"
set "MM=%DT:~14,2%"
set "SS=%DT:~17,2%"
:: Если однозначный час (например, "8:08:08")
if not "%HH%"=="%HH::=%" (
    set "HH=0%HH:~0,1%"
    set "MM=%DT:~13,2%"
    set "SS=%DT:~16,2%"
)

:: Сохраняем DLM
set "Y_DLM=%Y%"
set "M_DLM=%M%"
set "D_DLM=%D%"
set "HH_DLM=%HH%"
set "MM_DLM=%MM%"
set "SS_DLM=%SS%"

:: Извлекаем дату и время из имени
call :extract_date_from_name

:: --- DTOALL: флаг для автоматической обработки ---
:: Устанавливается в [a], но EXIF записывается ТОЛЬКО в handle_a_choice
:: Здесь - не вызываем :do_write, только проверяем, нужно ли показывать диалог
if not defined DTOALL goto check_jpg_dialog
if not defined ISJPG goto check_jpg_dialog
if defined DTO goto check_jpg_dialog

:: Если DTOALL=1 и это JPG без DTO - записываем EXIF и используем DLM
call :do_write
set "Y=%Y_DLM%"
set "M=%M_DLM%"
set "D=%D_DLM%"
set "HH=%HH_DLM%"
set "MM=%MM_DLM%"
set "SS=%SS_DLM%"
goto build_name

:check_jpg_dialog
:: --- Определяем, нужно ли показывать диалог для JPG ---
if not defined ISJPG goto use_name_or_dlm

:: Если это JPG и нет полной даты в имени - показываем диалог
if not defined NAME_Y goto ask_user
if not defined NAME_HH goto ask_user

:: У JPG есть полная дата в имени - используем её, не показываем диалог
goto use_name_full

:: --- Основная логика выбора даты ---
:use_name_or_dlm
:: Если есть полная дата и время в имени - используем их
if not defined NAME_Y goto use_name_date_dlm_time
if not defined NAME_HH goto use_name_date_dlm_time

:use_name_full
:: --- Полная дата и время найдены в имени файла - используем их ---
:: Пример: 2021-07-04_174724.txt - Y=2021, M=07, D=04, HH=17, MM=47, SS=24
set "Y=%NAME_Y%"
set "M=%NAME_M%"
set "D=%NAME_D%"
set "HH=%NAME_HH%"
set "MM=%NAME_MM%"
set "SS=%NAME_SS%"
goto build_name

:use_name_date_dlm_time
:: --- Дата в имени есть, но времени нет - комбинируем: дата из имени, время из DLM ---
:: Пример: 2021-07-04_Photo.txt - Y=2021, M=07, D=04, HH=12, MM=34, SS=56 (из DLM)
:: А если нет и года - переходим к использованию полного DLM
if not defined NAME_Y goto use_dlm
set "Y=%NAME_Y%"
set "M=%NAME_M%"
set "D=%NAME_D%"
set "HH=%HH_DLM%"
set "MM=%MM_DLM%"
set "SS=%SS_DLM%"
goto build_name

:: --- Формируем строку для отображения пользователю ---
:: Варианты:
:: 1. Полная дата и время в имени - берём всё из имени
:: 2. Только дата в имени - дата из имени, время из DLM
:: 3. Ничего не извлечено - только DLM
:: Переменная YMDHMS_NAME используется ТОЛЬКО для echo, не влияет на переименование
:ask_user
echo(--- Нет EXIF.DateTimeOriginal ^(DTO^) в %FN% ---
echo.
set "YMDHMS_NAME="

if not defined NAME_Y goto show_user_use_dlm_fallback
if not defined NAME_HH goto show_user_use_name_date_dlm_time

set "YMDHMS_NAME=%NAME_Y%-%NAME_M%-%NAME_D% %NAME_HH%:%NAME_MM%:%NAME_SS%"
goto show_user_suggestion

:show_user_use_name_date_dlm_time
:: --- Дата в имени есть, но времени нет - используем для отображения: дата из имени, время из DLM ---
:: Только для показа пользователю; реальное присвоение - в use_name_date_dlm_time
set "YMDHMS_NAME=%NAME_Y%-%NAME_M%-%NAME_D% %HH_DLM%:%MM_DLM%:%SS_DLM%"
goto show_suggestion

:show_user_use_dlm_fallback
:: --- Ни даты, ни времени не извлечено из имени - используем только DLM ---
:: Пример: Photo123.txt - всё берётся из даты изменения файла
set "YMDHMS_NAME=%Y_DLM%-%M_DLM%-%D_DLM% %HH_DLM%:%MM_DLM%:%SS_DLM%"

:show_user_suggestion
echo(Предлагаемая дата-время: %YMDHMS_NAME%
echo(Дата изменения файла ^(DLM^): %Y_DLM%-%M_DLM%-%D_DLM% %HH_DLM%:%MM_DLM%:%SS_DLM%
echo.
echo([a] - записать предложенное в EXIF для всех JPG без DTO
echo([w] - записать предложенное в EXIF
echo([m] - ввести DTO вручую
echo(Любая другая клавиша - пропустить
set /p "USRCHOICE=Выбор: "
if /i "%USRCHOICE%"=="a" goto handle_a_choice
if /i "%USRCHOICE%"=="w" goto handle_w_choice
if /i not "%USRCHOICE%"=="m" (
    echo.
    echo Отменена запись в EXIF.
    echo(%FN% пропущен.
    echo.
    exit /b
)
goto manual_input_start

:manual_input_start
set "MANUAL="
echo.
echo(Введите дату ГГГГ-ММ-ДД ЧЧ:ММ:СС или [q] для отмены
set /p "MANUAL=Дата: "
set "MANUAL=%MANUAL:"=%"
if /i "%MANUAL%"=="q" (
    echo.
    echo Отменён ручной ввод.
    echo(%FN% пропущен.
    echo.
    exit /b
)

set "TMP=%temp%\man_%random%.tmp"
echo(%MANUAL%>"%TMP%"
findstr /r "^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]$" "%TMP%" >nul
set "ERR=%errorlevel%"
if exist "%TMP%" del "%TMP%" >nul
if %ERR% equ 1 (
    echo.
    echo(Неверный формат. Пример: 2023-12-31 23:59:59
    echo.
    goto manual_input_start
)
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
:: --- Удаляем пробелы в часах и секундах (на случай " 8" или " 5") ---
:: Чтобы корректно обрабатывать ввод с однозначными часами/секундами
set "H_TMP=%H_TMP: =%"
set "S_TMP=%S_TMP: =%"
:: --- Добавляем ведущий ноль для однозначных часов (например, "8" - "08") ---
:: Если второй символ отсутствует - значит, число однозначное
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
:: Не проверяем високосные года или точное количество дней в месяце
if %M% LSS 1 set "DT_VALID=0"
if %M% GTR 12 set "DT_VALID=0"
if %D% LSS 1 set "DT_VALID=0"
if %D% GTR 31 set "DT_VALID=0"
if %HH% GTR 23 set "DT_VALID=0"
if %MM% GTR 59 set "DT_VALID=0"
if %SS% GTR 59 set "DT_VALID=0"
:: --- Если дата некорректна - возвращаемся к вводу ---
:: Пользователь может исправить ошибку
if %DT_VALID% equ 0 (
    echo(Недопустимые значения даты/времени.
    echo.
    goto manual_input_start
)

call :do_write
goto build_name

:: --- Обработка [a] ---
:handle_a_choice
:: После [a] - DTOALL=1, и все последующие JPG без DTO будут обработаны автоматически
set "DTOALL=1"
if not defined ISJPG goto skip_a_write
if defined DTO goto skip_a_write
call :do_write
:skip_a_write
goto use_dlm

:: --- Обработка [w] ---
:handle_w_choice
call :do_write
goto build_name

:use_dlm
set "Y=%Y_DLM%"
set "M=%M_DLM%"
set "D=%D_DLM%"
set "HH=%HH_DLM%"
set "MM=%MM_DLM%"
set "SS=%SS_DLM%"
goto build_name






:do_write
echo(Записываем DateTimeOriginal=%Y%-%M%-%D% %HH%:%MM%:%SS% в %FN%
"%EXV%" -M"set Exif.Photo.DateTimeOriginal %Y%-%M%-%D% %HH%:%MM%:%SS%" "%FN%"
set /a CNTT+=1
exit /b





:extract_date_from_name
:: Пытаемся извлечь дату и время из имени файла.
:: HMSCAND - "HMS Candidate" - может быть битым, нецифровым, вне диапазона
set "NAME_Y=" & set "NAME_M=" & set "NAME_D=" & set "NAME_HH=" & set "NAME_MM=" & set "NAME_SS="

:: --- Попытка 1: формат YYYYMMDD_HHMMSS (с подчёркиванием)
set "YMD=%BASE:~0,8%"
set "HMSCAND=%BASE:~9,6%"
echo(%YMD%| findstr /r "^[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]$" >nul
if errorlevel 1 goto try_yyyymmdd_hhmmss
if not "%BASE:~8,1%"=="_" goto try_yyyymmdd_hhmmss
echo(%HMSCAND%| findstr /r "^[0-9][0-9][0-9][0-9][0-9][0-9]$" >nul
if errorlevel 1 goto try_yyyymmdd_hhmmss
set "NAME_Y=%YMD:~0,4%"
set "NAME_M=%YMD:~4,2%"
set "NAME_D=%YMD:~6,2%"
call :check_date_format
if errorlevel 1 goto try_yyyymmdd_hhmmss
call :check_time_format
if %TIME_VALID% equ 1 (
    set "NAME_HH=%HH%"
    set "NAME_MM=%MM%"
    set "NAME_SS=%SS%"
)
exit /b

:try_yyyymmdd_hhmmss
:: --- Попытка 2: формат YYYY-MM-DD_HHMMSS
echo(%BASE%| findstr "^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]_[0-9][0-9][0-9][0-9][0-9][0-9]" >nul
if errorlevel 1 goto try_yyyymmdd_only
set "NAME_Y=%BASE:~0,4%"
set "NAME_M=%BASE:~5,2%"
set "NAME_D=%BASE:~8,2%"
set "HMSCAND=%BASE:~11,6%"
call :check_date_format
if errorlevel 1 goto try_yyyymmdd_only
call :check_time_format
if %TIME_VALID% equ 1 (
    set "NAME_HH=%HH%"
    set "NAME_MM=%MM%"
    set "NAME_SS=%SS%"
)
exit /b

:try_yyyymmdd_only
:: --- Попытка 3: формат YYYY-MM-DD_ (только дата)
echo(%BASE%| findstr "^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]_" >nul
if errorlevel 1 exit /b
set "NAME_Y=%BASE:~0,4%"
set "NAME_M=%BASE:~5,2%"
set "NAME_D=%BASE:~8,2%"
call :check_date_format
if errorlevel 1 exit /b
exit /b

:try_yyyymmdd_no_sep
:: --- Попытка 4: формат YYYY-MM-DDhhmmss (без разделителя)
echo(%BASE%| findstr "^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]" >nul
if errorlevel 1 exit /b
set "NAME_Y=%BASE:~0,4%"
set "NAME_M=%BASE:~5,2%"
set "NAME_D=%BASE:~8,2%"
set "HMSCAND=%BASE:~10,6%"
call :check_date_format
if errorlevel 1 exit /b
call :check_time_format
if %TIME_VALID% equ 1 (
    set "NAME_HH=%HH%"
    set "NAME_MM=%MM%"
    set "NAME_SS=%SS%"
)
exit /b





:check_date_format
set "DATE_VALID=0"
:: Проверяем, что Y - 4 цифры, M и D - 2 цифры
echo(%NAME_Y%| findstr /r "^[0-9][0-9][0-9][0-9]$" >nul
if errorlevel 1 exit /b
echo(%NAME_M%| findstr /r "^[0-9][0-9]$" >nul
if errorlevel 1 exit /b
echo(%NAME_D%| findstr /r "^[0-9][0-9]$" >nul
if errorlevel 1 exit /b
:: Диапазоны
set "Y_CHK=" & set "M_CHK=" & set "D_CHK="
set /a Y_CHK=1%NAME_Y% %% 10000
set /a M_CHK=1%NAME_M% %% 100
set /a D_CHK=1%NAME_D% %% 100
:: Минимальный и максимальный год
if %Y_CHK% lss 1900 exit /b
if %Y_CHK% gtr 2100 exit /b
if %M_CHK% lss 1 exit /b
if %M_CHK% gtr 12 exit /b
if %D_CHK% lss 1 exit /b
if %D_CHK% gtr 31 exit /b
set "DATE_VALID=1"
exit /b





:check_time_format
:: Извлечение часов/минут/секунд из 6-символьной строки (например, 081234)
:: Проблема: set /a не принимает "08" как число (ведь 08 - ошибка в восьмеричной системе)
:: Решение: приписываем 100 спереди - "10008", берём mod 100 (делим на 100) - 8
:: Так обходим ведущие нули без if и без ошибок
:: Пример: %HMSCAND:~0,2% = "08" - 10008 %% 100 = 8
set "TIME_VALID=0"
:: Проверяем, что HMSCAND - ровно 6 цифр
echo(%HMSCAND%|findstr /r "^[0-9][0-9][0-9][0-9][0-9][0-9]$" >nul
if errorlevel 1 exit /b
:: Извлекаем HH, MM, SS с обходом ведущих нулей
set "HH_CHK=" & set "MM_CHK=" & set "SS_CHK="
set /a HH_CHK=100%HMScand:~0,2% %% 100
set /a MM_CHK=100%HMScand:~2,2% %% 100
set /a SS_CHK=100%HMScand:~4,2% %% 100
:: Проверяем диапазоны
if %HH_CHK% gtr 23 exit /b
if %MM_CHK% gtr 59 exit /b
if %SS_CHK% gtr 59 exit /b
:: Форматируем с ведущими нулями
set "HH=%HH_CHK%" & if %HH_CHK% lss 10 set "HH=0%HH_CHK%"
set "MM=%MM_CHK%" & if %MM_CHK% lss 10 set "MM=0%MM_CHK%"
set "SS=%SS_CHK%" & if %SS_CHK% lss 10 set "SS=0%SS_CHK%"
set "TIME_VALID=1"
exit /b





:build_name
set "YMDHMS=%Y%-%M%-%D%_%HH%%MM%%SS%"

:: --- Универсальная очистка SUFFIX от лишних символов и __ ---
:clean_suffix
if not defined SUFFIX goto skip_suffix_processing
:clean_loop
:: Удаляем _ и пробелы только в начале
if "%SUFFIX:~0,1%"=="_" set "SUFFIX=%SUFFIX:~1%" & goto clean_loop
if "%SUFFIX:~0,1%"==" " set "SUFFIX=%SUFFIX:~1%" & goto clean_loop
:: Удаляем _ и пробелы только в конце
if "%SUFFIX:~-1%"=="_" set "SUFFIX=%SUFFIX:~0,-1%" & goto clean_loop
if "%SUFFIX:~-1%"==" " set "SUFFIX=%SUFFIX:~0,-1%" & goto clean_loop
:: Заменяем двойные подчёркивания на одинарные
set "OLD=%SUFFIX%"
set "SUFFIX=%SUFFIX:__=_%"
if not "%SUFFIX%"=="%OLD%" goto clean_loop

:: --- Удаление дублирования времени HHMMSS ---
set "TIME_PART=%HH%%MM%%SS%"
if "%SUFFIX:~0,6%"=="%TIME_PART%" (
    set "SUFFIX=%SUFFIX:~6%"
    goto clean_suffix
)

:: --- Удаление дублирования даты YYYYMMDD ---
set "DT_PART=%Y%%M%%D%"
if "%SUFFIX:~0,8%"=="%DT_PART%" (
    set "SUFFIX=%SUFFIX:~8%"
    goto clean_suffix
)

:: --- Удаление дублирования даты YYYY-MM-DD ---
set "DATE_PART=%YMDHMS:~0,10%"
if "%SUFFIX:~0,10%"=="%DATE_PART%" (
    set "SUFFIX=%SUFFIX:~11%"
    goto clean_suffix
)

:skip_suffix_processing

:: --- Проверка Progressive JPEG ---
if not defined ISJPG goto after_check_prog
:: Проверяем, есть ли _PROGR в SUFFIX - чтобы не добавлять дважды
set "SUFFIX_PROGR="
echo(%SUFFIX%| findstr /i "_PROGR$" >nul
if not errorlevel 1 set "SUFFIX_PROGR=1"
if defined SUFFIX_PROGR goto after_check_prog
set "PJPG=0"
"%EXV%" -pS "%FN%" | find "SOF2" >nul
if not errorlevel 1 set "PJPG=1"
if %PJPG% equ 1 (
    set "SUFFIX_PROGR=1"
    set "SUFFIX=%SUFFIX%_PROGR"
    set /a CNTP+=1
)
:after_check_prog

:: --- Формируем новое имя ---
set "NEWNAME=%YMDHMS%"
if defined SUFFIX set "NEWNAME=%NEWNAME%_%SUFFIX%"
set "NEWNAME=%NEWNAME%%EXT%"

:: --- Если имя уже правильное - отмечаем и выходим через общую метку ---
if /i "%NEWNAME%"=="%FN%" (
    echo(%FN% - пропущен, переименование не требуется.
    echo.
    exit /b
)

:: --- Проверка на конфликт имён ---
if not exist "%NEWNAME%" goto do_rename

set "I=1"
:conflict_loop
set "TESTNAME=%YMDHMS%"
if defined SUFFIX set "TESTNAME=%TESTNAME%_%SUFFIX%"
set "TESTNAME=%TESTNAME%_%I%%EXT%"
if exist "%TESTNAME%" (
    set /a I+=1
    goto conflict_loop
)
set "NEWNAME=%TESTNAME%"

:do_rename
ren "%FN%" "%NEWNAME%"
echo(%FN% -^> %NEWNAME%
echo.
set /a CNT+=1
exit /b