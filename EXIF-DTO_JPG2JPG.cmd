@echo off
set "DO=Copy EXIF JPG to JPG"
title %DO%
set "VRS=Froz %DO% v21.08.2025"
echo(%VRS%
echo(
set "EX=%~dp0bin\exiv2.exe"
if not exist "%EX%" echo("%EX%" �� ������, ��室��.& echo(& pause & exit /b
if "%~1"=="" echo(������ ����-1.jpg � ����-2.jpg ��� ����஢���� EXIF �� 1 � 2. ��室��.& echo(& pause & exit /b
if "%~2"=="" echo(�� 㪠��� ��ன 䠩�, ��室��.& echo(& pause & exit /b
set "ETMP=_exifdto-%random%"
"%EX%" -g Exif.Photo.DateTimeOriginal -Pv "%~1">"%ETMP%"
set /p "DT="<"%ETMP%"
del "%ETMP%"
"%EX%" -M"set Exif.Photo.DateTimeOriginal %DT%" "%~2"
echo(�����஢�� EXIF DTO: "%~nx1" -^> "%~nx2"