@echo off
set "DO=Copy EXIF JPG to JPG"
title %DO%
set "VRS=Froz %DO% v21.08.2025"
echo(%VRS%
echo(
set "EX=%~dp0bin\exiv2.exe"
if not exist "%EX%" echo("%EX%" не найден, выходим.& echo(& pause & exit /b
if "%~1"=="" echo(Задайте Файл-1.jpg и Файл-2.jpg для копирования EXIF из 1 в 2. Выходим.& echo(& pause & exit /b
if "%~2"=="" echo(Не указан второй файл, выходим.& echo(& pause & exit /b
set "ETMP=_exifdto-%random%"
"%EX%" -g Exif.Photo.DateTimeOriginal -Pv "%~1">"%ETMP%"
set /p "DT="<"%ETMP%"
del "%ETMP%"
"%EX%" -M"set Exif.Photo.DateTimeOriginal %DT%" "%~2"
echo(Скопирован EXIF DTO: "%~nx1" -^> "%~nx2"