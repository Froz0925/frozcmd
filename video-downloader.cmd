@echo off
set "CMDN=%~n0"
:: ----------------------------------------------------
:: ����� ��� ᪠稢����:
set "OUTD=%USERPROFILE%\Downloads\Froz-%CMDN%"
:: ----------------------------------------------------

set "DO=Video Downloader"
set "VRS=Froz %DO% v03.09.2025"
set "SERV=RuTube, VK Video, Dzen, OK, Boosty, YouTube"
set "ERRC=�����४�� �����, ������ ������."
set "ERRL=����ୠ� ��뫪�, ������ ������."
set "VDL=%~dp0bin\yt-dlp.exe"
if not exist "%VDL%" echo(�� ������ %VDL%, ��室��.& echo(& pause & exit /b
set "FFM=%~dp0bin\FFMpeg.exe"
if not exist "%FFM%" echo(�� ������ %FFM%, ��室��.& echo(& pause & exit /b
title %DO%
echo(%VRS%
echo(
echo(���稢���� ����� � �㤨�䠩��� ��
echo(%SERV%
echo(� %OUTD%\
echo(
echo(��ଠ�� ���⥩��஢ �� �롮� ��஦��:
echo(AVC1+AAC = MP4+M4A, AVC1+OPUS = MKV+OPUS, AV01+AAC = MP4+M4A, AV01+OPUS = WEBM+OPUS
echo(

:inp
set "LNKF="
set /p "LNKF=��⠢�� https-��뫪�, Enter - ��室: "
if "%LNKF%"=="" echo(��室��.& exit /b
:: ��१��� �� &
for /f "delims=&" %%n in ("%LNKF%") do set "LNK=%%n"
:: ��稭����� �� � https://
set "LNKC=%LNK:~0,8%"
if /i not "%LNKC%"=="https://" echo(%ERRL%& goto inp

:get
:: �஢��塞 ����������
"%VDL%" -U
:waitloop
set "VDLN=%~dp0bin\yt-dlp.exe.new"
:: ��� ��祧������� 䠩�� .new - �� ᨣ���, �� yt-dlp ���������
if exist "%VDLN%" (
  ping 127.0.0.1 -n 1>nul
  goto waitloop
)
"%VDL%" -F "%LNK%"|more
:: �������⨭�: �᫨ 㤠����� �����ப� �த� "youtu" ����� ��뫪�, ����� ��� ⠬ �뫠 - ���室�� � �㦭� ����
if not "%LNK%"=="%LNK:youtu=%" goto yu-in
if not "%LNK%"=="%LNK:rutu=%" goto ru-in
if not "%LNK%"=="%LNK:vkvideo=%" goto vk-in
if not "%LNK%"=="%LNK:vk.com=%" goto vk-in
if not "%LNK%"=="%LNK:dzen=%" goto dz-in
if not "%LNK%"=="%LNK:ok.ru=%" goto ok-in
if not "%LNK%"=="%LNK:boosty=%" goto bo-in
echo(�������⨭� �� ��।���, ��室��.& pause & exit /b


:yu-in
set "VID="
set /p "VID=YouTube: ������ ����� �����, r - ����� ᯨ᪠, Enter - ��室: "
if "%VID%"=="" echo(��室��.& exit /b
if "%VID%"=="r" "%VDL%" -F "%LNK%"|more
:: �஢�ઠ �� ������� ⮫쪮 ����
echo(%VID%|findstr "^[0-9]*$" >nul
if errorlevel 1 echo(%ERRC%& goto yu-in
if /i %VID% LSS 100 set "FMT=%VID%" & goto dl
if /i %VID% GTR 100 goto yu-aud

:yu-aud
set "AUD="
echo(������ ����� �㤨���஦��: 1 - AAC 128k (ᮢ���⨬��), 2 - OPUS 128k (����⢥����), Enter - ��室: 
:yi
set /p "AUD=����: "
if "%AUD%"=="" echo(��室��.& exit /b
if "%AUD%"=="1" set "FMT=%VID%+140" & goto dl
if "%AUD%"=="2" set "FMT=%VID%+251" & goto dl
echo(%ERRC%& goto yi


:ru-in
set "VID="
echo(RuTube: ������ ����� ����� XXX �� default-XXX-0, r - ����� ᯨ᪠ ��஦��, Enter - ��室.
set /p "VID=����: "
if "%VID%"=="" echo(��室��.& exit /b
if "%VID%"=="r" "%VDL%" -F "%LNK%"|more
:: �஢�ઠ �� ������� ⮫쪮 ����
echo(%VID%|findstr "^[0-9]*$" >nul
if errorlevel 1 echo(%ERRC%& echo(& goto ru-in
if /i %VID% GEQ 100 set "FMT=default-%VID%-0" & goto dl


:vk-in
set "VID="
echo(VK Video: ������ ����� ����� XXX �� urlXXX, ��� 1-8 �� dash_sep-X �᫨ �㦥� �⤥��� �㤨�䠩�, r - ����� ᯨ᪠, Enter - ��室.
:vi
set /p "VID=����: "
if "%VID%"=="" echo(��室��.& exit /b
if "%VID%"=="r" "%VDL%" -F "%LNK%"|more
echo(%VID%|findstr "^[0-9]*$" >nul
if errorlevel 1 echo(%ERRC%& goto vi
if /i %VID% LSS 11 goto vk-aud
if /i %VID% GEQ 100 set "FMT=url%VID%" & goto dl

:vk-aud
set "AUD="
set /p "AUD=������ ����� �㤨���஦�� X �� dash_sep-X audio only, q - ��室: "
if "%AUD%"=="" echo(��室��.& exit /b
echo(%VID%|findstr "^[0-9]*$" >nul
if errorlevel 1 echo(%ERRC%& goto vk-aud
if /i %VID% LSS 10 set "FMT=dash_sep-%VID%+dash_sep-%AUD%" & goto dl


:dz-in
set "VID="
echo(Dzen: ������ ����� ����� XXX �� XXX-0. Dash-��ਠ��� �� ����� ��᫠ �.�. �㤨� ⮫쪮 ����, 
echo(r - ����� ᯨ᪠ ��஦��, Enter - ��室.
:di
set /p "VID=����: "
if "%VID%"=="" echo(��室��.& exit /b
if "%VID%"=="r" "%VDL%" -F "%LNK%"|more
echo(%VID%|findstr "^[0-9]*$" >nul
if errorlevel 1 echo(%ERRC%& goto di
if /i %VID% GEQ 100 set "FMT=%VID%-0" & goto dl


:ok-in
set "VID="
set /p "VID=OK.ru: ������ ��� �����, r - ����� ᯨ᪠, Enter - ��室: "
if "%VID%"=="" echo(��室��.& exit /b
if "%VID%"=="r" "%VDL%" -F "%LNK%"|more
set "FMT=%VID%" & goto dl


:bo-in
set "VID="
echo(Boosty: ������ ��� ����� �� ������� ᯨ᪠ "tiny-ultra_hd", r - ����� ᯨ᪠ ��஦��, Enter - ��室.
set /p "VID=����: "
if "%VID%"=="" echo(��室��.& exit /b
if "%VID%"=="r" "%VDL%" -F "%LNK%"|more
set "FMT=%VID%" & goto dl


:dl
echo(���稢���...
if not exist "%OUTD%" md "%OUTD%">nul
:: ���� -k 㡨��� �����, ⠪ ��� �� ࠧ���쭮� 㪠����� ����� � �㤨���஦�� yt-dlp �१ ���� -x ��������� �㤨���஦�� � �⤥��� 䠩�,
:: � �஬� �६����� DASH-䠩��� �� 㤠��� � ᠬ �����䠩� ���� ��� ⮦� �६����
"%VDL%" ^
    -f %FMT% --console-title -w -x -k --write-subs --sub-langs ru --convert-subtitles srt ^
    --windows-filenames -o "%OUTD%\%%(upload_date>%%Y-%%m-%%d)s_%%(title)s_%%(id)s.%%(ext)s" ^
    "%LNK%"
:: ����塞 DASH-�ࠣ����� ������: yt-dlp �� -x 㤠��� � �����, ���⮬� �ᯮ��㥬 -k � ��⨬ ᠬ�
set "VATMP=%OUTD%\*.f*.*"
if exist "%VATMP%" del "%VATMP%"
start "" "%OUTD%"
chcp 866 >nul
set "EV=%temp%\%CMDN%-%random%%random%.vbs"
set "EMSG=��⮢� - �. %OUTD%"
chcp 1251 >nul
>"%EV%" echo(MsgBox "%EMSG%",,"%CMDN%"
chcp 866 >nul
cscript //nologo "%EV%"
del "%EV%"