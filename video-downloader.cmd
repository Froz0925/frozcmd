@echo off
set "DO=Video Downloader"
set "VRS=Froz %DO% v21.08.2025"

:: ���᮪ �������⨭��� ��� Help � Title:
set "SERV=RuTube, VK Video, Dzen, OK, Boosty, YouTube (���� �� ࠡ�⠥�)."
set "ERRC=�����४�� �����, ������ ������."
set "ERRL=����ୠ� ��뫪�, ������ ������."

:: ����� ��� ᪠稢����:
set "OUTD=%USERPROFILE%\Downloads\Froz_%~n0"


:: �஢��塞 ����稥 �⨫��:
set "VDL=%~dp0bin\yt-dlp.exe"
set "VDLN=%~dp0bin\yt-dlp.exe.new"
if not exist "%VDL%" echo(�� ������ %VDL%, ��室��.& echo(& pause & exit /b
set "FFM=%~dp0bin\FFMpeg.exe"
if not exist "%FFM%" echo(�� ������ %FFM%, ��室��.& echo(& pause & exit /b

:: Intro:
title %DO%
echo(%VRS%
echo(
echo(���稢���� ����� � �㤨�䠩��� ��
echo(%SERV%
echo(� %OUTD%\
echo(

:inp
:: ���� ��뫪�:
echo(
set /p "LNKF=��⠢�� https-��뫪�, q - ��室: "
for /f "tokens=1 delims=?" %%n in ("%LNKF%") do set "LNK=%%n"
if "%LNK%"=="" (
    echo(%ERRL%
    goto inp
)
if "%LNK%"=="q" echo(��室��.& exit /b
if not "%LNK%"=="%LNK:https://=%" goto get
echo(%ERRL%
goto inp

:get
:: �஢��塞 ����������:
"%VDL%" -U
:waitclose
if exist "%VDLN%" (
  ping 127.0.0.1 -n 1>nul
  goto waitclose
)
:: ��������� �������� �������⨭��:
"%VDL%" -F "%LNKF%"|more
if not "%LNK%"=="%LNK:youtu=%" goto yu-in
if not "%LNK%"=="%LNK:rutu=%" goto ru-in
if not "%LNK%"=="%LNK:vkvideo=%" goto vk-in
if not "%LNK%"=="%LNK:vk.com=%" goto vk-in
if not "%LNK%"=="%LNK:dzen=%" goto dz-in
if not "%LNK%"=="%LNK:ok.ru=%" goto ok-in
if not "%LNK%"=="%LNK:boosty=%" goto bo-in
echo(�������⨭� �� ��।���, ��室��.& pause & exit /b



:yu-in
set /p "VID=YouTube: ������ ����� �����, r - ����� ᯨ᪠, q - ��室: "
if "%VID%"=="" (
    echo(%ERRC%
    goto yu-in
)
if "%VID%"=="q" echo(��室��.& exit /b
if "%VID%"=="r" "%VDL%" -F "%LNKF%"|more
if /i %VID% LSS 100 set "FMT=%VID%" & goto dl
if /i %VID% GTR 100 goto yu-aud
echo(%ERRC%
goto yu-in

:yu-aud
set /p "AUD=������ ����� �㤨���஦��: 1 - AAC 128k, 2 - OPUS 128k, q - ��室: "
if "%AUD%"=="" (
    echo(%ERRC%
    goto yu-aud
)
if "%AUD%"=="q" echo(��室��.& exit /b
if "%AUD%"=="1" set "FMT=%VID%+140"& goto dl
if "%AUD%"=="2" set "FMT=%VID%+251"& goto dl
echo(%ERRC%
goto yu-aud



:ru-in
echo(RuTube: ������ ����� ����� XXX �� default-XXX-0, r - ����� ᯨ᪠ ��஦��, q - ��室.
set /p "VID=����: "
if "%VID%"=="" (
    echo(%ERRC%
    goto ru-in
)
if "%VID%"=="q" echo(��室��.& exit /b
if "%VID%"=="r" "%VDL%" -F %LNKF%|more
set "FMT=default-%VID%-0"
goto dl



:vk-in
echo(VK Video: ������ ����� ����� XXX �� urlXXX, ��� 1-8 ��� dash_sep-X (�᫨ �㦭� �⤥�쭠� �㤨���஦��)
echo(r - ����� ᯨ᪠, q - ��室.
set /p "VID=����: "
if "%VID%"=="" (
    echo(%ERRC%
    goto vk-in
)
if "%VID%"=="q" echo(��室��.& exit /b
if "%VID%"=="r" "%VDL%" -F %LNKF%|more
if /i %VID% LSS 11 goto vk-aud
set "FMT=url%VID%"
goto dl

:vk-aud
set /p "AUD=������ ����� �㤨���஦�� XX �� dash_sep-XX audio only, q - ��室: "
if "%AUD%"=="" (
    echo(%ERRC%
    goto vk-aud
)
if "%AUD%"=="q" echo(��室��.& exit /b
set "FMT=dash_sep-%VID%+dash_sep-%AUD%"
goto dl



:dz-in
echo(Dzen: ������ ����� ����� XXX �� XXX-0. Dash-��ਠ��� �� ����� ��᫠ �.�. �㤨� ⮫쪮 ����, 
echo(r - ����� ᯨ᪠ ��஦��, q - ��室.
set /p "VID=����: "
if "%VID%"=="" (
    echo(%ERRC%
    goto dz-in
)
if "%VID%"=="q" echo(��室��.& exit /b
if "%VID%"=="r" "%VDL%" -F %LNKF%|more
set "FMT=%VID%-0"
goto dl


:ok-in
set /p "VID=OK.ru: ������ ��� �����, r - ����� ᯨ᪠, q - ��室: "
if "%VID%"=="" (
    echo(%ERRC%
    goto ok-in
)
if "%VID%"=="q" echo(��室��.& exit /b
if "%VID%"=="r" "%VDL%" -F %LNKF%|more
set "FMT=%VID%"
goto dl



:bo-in
echo(Boosty: ������ ��� ����� �� ������� ᯨ᪠ "tiny-ultra_hd", r - ����� ᯨ᪠ ��஦��, q - ��室.
set /p "VID=����: "
if "%VID%"=="" (
    echo(%ERRC%
    goto bo-in
)
if "%VID%"=="q" echo(��室��.& exit /b
if "%VID%"=="r" "%VDL%" -F %LNKF%|more
set "FMT=%VID%"
goto dl



:dl
echo(���稢���...
if not exist "%OUTD%" md "%OUTD%">nul
"%VDL%" %LNKF% -f %FMT% -o "%OUTD%\%%(upload_date>%%Y-%%m-%%d)s_%%(title)s_%%(id)s.%%(ext)s" --console-title -w -x -k --write-subs --sub-langs ru --convert-subtitles srt
start "" "%OUTD%"



:done
chcp 866 >nul
set "EV=%temp%\$%~n0$.vbs"
set "EMSG=��⮢�."
chcp 1251 >nul
>"%EV%" echo(MsgBox "%EMSG%",,"%~nx0"
chcp 866 >nul
cscript //nologo "%EV%"
del "%EV%"