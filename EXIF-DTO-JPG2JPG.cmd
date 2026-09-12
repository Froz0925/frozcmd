@echo off
set "DO=Copy EXIF JPG to JPG"
title %DO%
set "VRS=Froz %DO% v21.08.2025"
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
if not exist "%EX%" echo("%EX%" не найден, выходим.& echo(& pause & exit /b
if "%~1"=="" echo(Задайте Файл-1.jpg и Файл-2.jpg для копирования EXIF из 1 в 2. Выходим.& echo(& pause & exit /b
if "%~2"=="" echo(Не указан второй файл, выходим.& echo(& pause & exit /b
set "ETMP=_exifdto-%random%%random%"
"%EX%" -g Exif.Photo.DateTimeOriginal -Pv "%~1">"%ETMP%"
set /p "DT="<"%ETMP%"
del "%ETMP%"
"%EX%" -M"set Exif.Photo.DateTimeOriginal %DT%" "%~2"
echo(Скопирован EXIF DTO: "%~nx1" -^> "%~nx2"