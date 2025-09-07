@echo off
set "DO=Video recode script"
set "VRS=Froz %DO% v07.09.2025"
:: ��४���஢���� �����䠩��� � 㬥��襭�� ࠧ��� � ��᮪��� ����ன���� - ��� �������娢�


:: === ����: ���� ===
:: ���� ����: 1 = 㬥����� �� 720, � ⮬ �᫥ �᫨ ��᫥ ������ ���� > 720
:: ���� - 㬥����� �� 1080 (�⠭����� FullHD ������), � ⮬ �᫥ �᫨ ��᫥ ������ ���� > 1080.
set "SCALE="

:: �஢��� ����⢠ (����� = ����). ���� - ����� �롨ࠥ� ᠬ (���筮 �롨��� �।��� ����⢮).
:: �᫨ ���� - ��� nvenc ����砥��� multipass � 楫���� ���३� 2.5� ��� 720 � 4.5� ��� 1080.
:: ���� ��⠭�������� CRF �ਭ㤨⥫쭮: nvenc: 18-30, amf/qsv: 1-51 (०�� cqp), libx264/5: 18-28.
:: ��� hevc_nvenc �� 30fps H720 CRF26 = 4,5 ����, H1080 CRF32 = 4,5 ����.
:: �� 㬮�砭�� hevc_nvenc �⠢��: H720 ~CRF32 = 2,5 ����, H1080 ~CRF38 = 2 ����.
set "CRF="

:: �㤨�: 㬥����� ࠧ���: set "AUDIO_ARGS=-c:a libopus -b:a 128k"
:: ���� ��� ���������஢��� (::) - �㤨� ��������� ��� ���������
set "AUDIO_ARGS=-c:a libopus -b:a 128k"

:: ������: -90 = �� �ᮢ��, 90 = ��⨢ �ᮢ��. �᫨ �� ������ - ������� �� ⥣� ������ (⮫쪮 MP4/MOV).
:: *qsv �� �����稢��� �����; *amf ����� ࠡ���� � �訡����. �� ��筮� ��⠭���� ⥣ �� 䠩�� ����������.
set "ROTATION="

:: ����������:
:: NVIDIA GPU: hevc_nvenc (४�����㥬�) � h264_nvenc.
::             �ॡ���� GeForce GTX 950+ (Maxwell 2nd Gen GM20x) (2014+) � �ࠩ��� Nvidia v.570+.
:: AMD GPU:    hevc_amf � h264_amf - Radeon RX 400 / R9 300 �ਨ � ����� (2015+)
::             �ॡ���� �ࠩ��� AMD Adrenalin Edition (�� Microsoft)
:: Intel GPU:  hevc_qsv � h264_qsv - Intel Skylake+ (2015+), �ࠩ��� Intel HD + Media Feature Pack
:: CPU:        libx265 - �祭� ��������, libx264 - ��������
:: �ਬ�砭��: HEVC - ����� ࠧ���, ��� ����⢮, H.264 - ᮢ���⨬����.
set "CODEC=hevc_amf"

:: ��䨫� ����஢���� ��� HEVC: main10 (10 bit) � main (8 bit). ��� H.264 - �ᥣ�� �㤥� ��⠭����� high.
:: �᫨ �� ������ - ��⠭���������� main10 �᫨ �����ন������ �������.
set "PROFILE=main10"

:: ����� ���஢. �᫨ ���� - ������� �� ��室����.
:: ������騩 FPS (VFR) �८�ࠧ���� � �⠭����� ������訩 �� ���祭�� (CFR), ���㣫���� �����
:: �ਬ���: 24, 25, 30, 50, 60, 24000/1001 (~23.976), 30000/1001 (~29.97)
:: ��� ������筮�� ����� (MPEG2 50/60i) - ����������, �����૥��� �८�ࠧ�� � 50/60p.
set "FPS="

:: ���⥩���: mkv - ����� �㭪権, mp4 - ���� ��� qsv/amf � �ந��뢠⥫��.
set "OUTPUT_EXT=mkv"

:: ���䨪� � �����: ���ਬ�� _sm -> ���_sm.mkv
set "NAME_APPEND=_sm"

:: ��ࠬ��� ᪮��� ����஢���� �� ��襣� GPU/CPU - �������� �ਯ�� ���᫨�� �ਬ�୮� �६� ����஢����.
:: ������ ����� ����: (ᥪ㭤 ����஢���� / ᥪ㭤 �����) � 100. �ਬ��: 0.3 -> �⠢�� 30
set "SPEED_NVENC=7"
set "SPEED_AMF=20"
set "SPEED_QSV=20"
set "SPEED_LIBX264=50"
set "SPEED_LIBX265=100"





:: === ����: �������� ===
title %DO%
echo(%VRS%
echo(
set "CMDN=%~n0"
:: �஢�ઠ ������ �室��� 䠩���
if "%~1" == "" (
    echo(�ᯮ�짮�����: �஢���� ����ன�� � ��砫� �ਯ� � �� ����室�����
    echo(��।������ � ।���� � �����প�� ����஢�� OEM,
    echo(���ਬ�� ������� � ���⮬ Terminal, Notepad++, ।����� 䠩����� �������஢.
    echo(
    echo(��⥬ ����ﭨ� ��� ��⠢�� �����䠩�� �� ��� 䠩�.
    echo(
    pause
    exit /b
)
:: �஢�ઠ ������ �⨫��
set "FFM=%~dp0bin\ffmpeg.exe"
set "FFP=%~dp0bin\ffprobe.exe"
set "MI=%~dp0bin\mediainfo.exe"
set "MKVP=%~dp0bin\mkvpropedit.exe"
if not exist "%FFM%" echo("%FFM%" �� ������, ��室��.& echo(& pause & exit /b
if not exist "%FFP%" echo("%FFP%" �� ������, ��室��.& echo(& pause & exit /b
if not exist "%MI%" echo("%MI%" �� ������, ��室��.& echo(& pause & exit /b
if not exist "%MKVP%" echo("%MKVP%" �� ������, ��室��.& echo(& pause & exit /b

:: �஢�ઠ: �����ন���� �� GPU ��࠭�� GPU-�����
if /i "%CODEC:~0,5%" == "libx2" goto SKIP_GCHK
:: ��������㥬 UTF-8 ��� ffmpeg � OEM (cp866) ��� ���४⭮� ࠡ��� findstr
:: ffmpeg ���� stderr � UTF-8, � findstr � cmd ࠡ�⠥� ⮫쪮 � OEM
set "GLOG=%temp%\%CMDN%-gpuchk-%random%%random%"
set "GLOGOEM=%GLOG%-oem"
set "VT=%GLOG%.vbs"
>"%VT%" echo(With CreateObject("ADODB.Stream"^)
>>"%VT%" echo(.Type=2:.Charset="UTF-8":.Open:.LoadFromFile "%GLOG%"
>>"%VT%" echo(s=.ReadText:.Close
>>"%VT%" echo(.Type=2:.Charset="cp866":.Open:.WriteText s
>>"%VT%" echo(.SaveToFile "%GLOGOEM%",2:.Close
>>"%VT%" echo(End With
:: ������ ����㠫�� ���⮩ �����䠩� ������ � 1 ᥪ㭤� � ��⠥��� ᦠ�� �������
"%FFM%" -hide_banner -v error -f lavfi -i nullsrc -c:v %CODEC% -t 1 -f null - 2>"%GLOG%"
cscript //nologo "%VT%"
:: �� ���뢠�� ��ப� findstr �� if errorlevel
findstr /i "Error while opening encoder" "%GLOGOEM%" >nul
if %ERRORLEVEL% EQU 0 (
    echo(�訡��: ��������� ��� �� �ࠩ��� �� �����ন���� ��࠭�� GPU-�����.
    echo(������� ���������� �/��� �ࠩ���, ��� ᬥ��� ����� � ����ன��� �ਯ�. ��室��.
    echo(
    pause
    exit /b
)
del "%GLOG%"
del "%GLOGOEM%"
del "%VT%"
:SKIP_GCHK

:: �������� set ��। FILE_LOOP
set "OUTPUT_DIR=%~dp1"
:: ���࠭塞 ��室�� user-���祭�� ����� ����� ���� ��१���ᠭ� �� ࠡ��
set "USER_ROTATION=%ROTATION%"
set "USER_OUTPUT_EXT=%OUTPUT_EXT%"
set "USER_FPS=%FPS%"





:: === ����: ����� ===
:FILE_LOOP
:: ����⠭�������� user-���祭�� ��� ������ 䠩��
set "ROTATION=%USER_ROTATION%"
set "OUTPUT_EXT=%USER_OUTPUT_EXT%"
set "FPS=%USER_FPS%"
:: �����뢠�� ��� 䠩�� � ��६���� �⮡� %1 �� ᫮������ � �����
set "FNF=%~1"
set "FNN=%~n1"
set "FNWE=%~nx1"
set "EXT=%~x1"
set "OUTPUT_NAME=%FNN%%NAME_APPEND%"
set "OUTPUT=%OUTPUT_DIR%%OUTPUT_NAME%.%OUTPUT_EXT%"

:: �᫨ ����� ��� 䠩��� - ��室��
if "%FNF%" == "" goto FILE_LOOP_END

:: �६����� ��� OEM-���� ��� ⥪�饣� �����䠩�� - �ᯮ��㥬 ����, � �� %random%.
:: �⮡� �� ������� �� ������ Windows ���� ⥪���� ����-�६� �१ VBS, 
:: � �� �१ %date% %time%. ��ଠ�: ����-��-��_������
set "TV=%temp%\%~n0-dtmp-%random%%random%.vbs"
>"%TV%" echo(s=Year(Now)^&"-"^&Right("0"^&Month(Now),2)^&"-"
>>"%TV%" echo(s=s^&Right("0"^&Day(Now),2)
>>"%TV%" echo(s=s^&"_"^&Right("0"^&Hour(Now),2)^&Right("0"^&Minute(Now),2)
>>"%TV%" echo(s=s^&Right("0"^&Second(Now),2):WScript.Echo s
for /f %%t in ('cscript //nologo "%TV%"') do set "DTMP=%%t"
del "%TV%"

:: ����� � ����� �����
set "LOGE=%DTMP%oem"
set "LOG=%OUTPUT_DIR%logs\%LOGE%"
set "LOGU=%DTMP%utf"
set "LOGN=%FNN%%NAME_APPEND%-log.txt"
:: ��������� ���� CMD+FFMpeg � ���� �� ��������, ⠪ ��� ffmpeg �뢮��� � UTF8, � CMD - � OEM
set "FFMPEG_LOG_NAME=%OUTPUT_NAME%-log_ffmpeg.txt"
set "FFMPEG_LOG=%OUTPUT_DIR%logs\%FFMPEG_LOG_NAME%"

:: ������ ����� ��� �����
if not exist "%OUTPUT_DIR%logs" md "%OUTPUT_DIR%logs"

:: �஢��塞 �� ������ 䠩� 㦥 ������� � ���㫥���� ࠧ���
if not exist "%OUTPUT%" goto DONE_SIZE_CHK
for %%F in ("%OUTPUT%") do set SIZE=%%~zF
if %SIZE% EQU 0 (
    del "%OUTPUT%"
    goto DONE_SIZE_CHK
)
echo("%OUTPUT_NAME%" 㦥 �������, �ய�᪠��.
echo(
goto NEXT
:DONE_SIZE_CHK

title ��ࠡ�⪠ %FNWE%...
echo(%DATE% %TIME:~0,8% ���� ��ࠡ�⪠ "%FNWE%"...
echo(
>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% ���� ��ࠡ�⪠ "%FNWE%"...





:: === ����: ���������� ===
:: ffprobe ���������: ࠧ���� ����, �ଠ� ���ᥫ��, ������筮���,
:: ����� ���஢ (������� � �।���), ������, ���⥫쭮���,
:: "�����" �����⥣� ��� �� 㤠����� �����.
set "SRC_W="
set "SRC_H="
set "PIX_FMT="
set "FIELD_ORDER="
set "R_FPS="
set "A_FPS="
set "ROTATION_TAG="
set "HAS_VIDEO_TAGS="
set "LENGTH_SECONDS="
set "FFP_DATA=%temp%\ffprobe_data_%random%%random%.txt"
"%FFP%" -v error ^
    -select_streams v:0 ^
    -show_entries stream=width,height,pix_fmt,field_order,r_frame_rate,avg_frame_rate ^
    -show_entries stream_side_data=rotation ^
    -show_entries stream_tags=BPS ^
    -show_entries format=duration ^
    -of default=nw=1 ^
    "%FNF%" > "%FFP_DATA%"
:: �᫨ ������ �����-⥣ BPS - �⠢�� 䫠�
for /f "tokens=1,2 delims==" %%a in ('type "%FFP_DATA%"') do (
    if "%%a"=="width"          set "SRC_W=%%b"
    if "%%a"=="height"         set "SRC_H=%%b"
    if "%%a"=="pix_fmt"        set "PIX_FMT=%%b"
    if "%%a"=="field_order"    set "FIELD_ORDER=%%b"
    if "%%a"=="r_frame_rate"   set "R_FPS=%%b"
    if "%%a"=="avg_frame_rate" set "A_FPS=%%b"
    if "%%a"=="rotation"       set "ROTATION_TAG=%%b"
    if "%%a"=="TAG:BPS"        set "HAS_VIDEO_TAGS=1"
    if "%%a"=="duration"       set "LENGTH_SECONDS=%%b"
)
del "%FFP_DATA%"
:: �஢��塞, �� ���� ��ࠬ��� "�ਭ� ����" �����祭 � �� ࠢ�� ���. ���� �� �� �����䠩�.
if not defined SRC_W goto BADFILE
if %SRC_W% EQU 0 goto BADFILE
goto FILE_VALID
:BADFILE
echo([ERROR] ffprobe �� ᬮ� ������� ��ࠬ���� �����. ���� �ய�饭.
echo(
>>"%LOG%" echo([ERROR] %DATE% %TIME:~0,8% ffprobe �� ᬮ� ������� ��ࠬ���� �����. ���� �ய�饭.
goto NEXT
:FILE_VALID






:: === ����: ����� ===
:: LENGTH_SECONDS ������� ࠭��
if not defined LENGTH_SECONDS (
    >>"%LOG%" echo([ERROR] %DATE% %TIME:~0,8% �� 㤠���� ������� ���⥫쭮��� �����
    goto DONE_LENGTH
)
:: ��⠢�塞 ⮫쪮 楫� ᥪ㭤�
for /f "tokens=1 delims=." %%a in ("%LENGTH_SECONDS%") do set "LENGTH_SECONDS=%%a"
:: ������塞 +1, �⮡� ���㣫��� �����
set /a LENGTH_SECONDS+=1
:: ��।��塞 �����樥�� x100 �� ������
set "SPEED_CENTI="
if /i "%CODEC:~-5%" == "nvenc" set "SPEED_CENTI=%SPEED_NVENC%"
if /i "%CODEC:~-3%" == "amf"   set "SPEED_CENTI=%SPEED_AMF%"
if /i "%CODEC:~-3%" == "qsv"   set "SPEED_CENTI=%SPEED_QSV%"
if /i "%CODEC%" == "libx264"   set "SPEED_CENTI=%SPEED_LIBX264%"
if /i "%CODEC%" == "libx265"   set "SPEED_CENTI=%SPEED_LIBX265%"
:: Fallback �� ��।����� ������⥫� ᪮���, �᫨ ����� �� �ᯮ����
if not defined SPEED_CENTI (
    >>"%LOG%" echo([WARNING] %DATE% %TIME:~0,8% ��������� �����: %CODEC%.
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% ��� ����� �६��� ����஢���� ��६ ᪮���� 50
    set "SPEED_CENTI=50"
)
:: ������뢠�� �ਬ�୮� �६� ����஢���� � ᥪ㭤��
set /a ENCODE_SECONDS = (LENGTH_SECONDS * SPEED_CENTI) / 100
:: ������ ���� ������ 1 ᥪ㭤�
if %ENCODE_SECONDS% LSS 1 set "ENCODE_SECONDS=1"
:: ��ॢ���� ᥪ㭤� � ������:ᥪ㭤�
set /a "MINUTES=ENCODE_SECONDS / 60"
set /a "SECONDS=ENCODE_SECONDS %% 60"
if %SECONDS% LSS 10 set "SECONDS=0%SECONDS%"
echo(�ਬ�୮� �६� ����஢����: %MINUTES% ����� %SECONDS% ᥪ㭤.
echo(
:DONE_LENGTH






:: === ����: ���� ===
:: ���� ������ ���� ��। ������ �������
:: ��।������ 梥⮢��� ��������� (Full Range / Limited Range)
::   - �᫨ ffprobe ����� pix_fmt=yuvj420p - ��⠥�, �� ����� ������ �⮡ࠦ����� � Full Range,
::     ��� ����� �� 䠪�� - Limited (16-235). �� �⠭���⭮� ��������� ⥫�䮭��:
::     ��� �ᯮ����� yuvj420p, �⮡� ������ "����㫨" �������� � ᤥ���� ����� ���.
::   - �⮡� ��࠭��� ��� ��䥪�, ��⠭�������� colour-range=1 �१ mkvpropedit � MKV.
::     ffmpeg �� ��࠭���� ������ �⮣� ⥣�, � mkvpropedit �� ࠡ�⠥� � MP4.
::     ���⮬� �� yuvj420p ���७�� ������� �� MKV, ���� �᫨ � ��ࠫ MP4.
::   - �����: colour-range �ਮ��⭥� rotate �� ������ *qsv - ���䫨�� �蠥��� � ����� �������.
:: �᫨ �祭� ���� ������� MP4 � Full Range (⥮��, �� �஢�७�), � ������ �����:
::   ffmpeg.exe -i input.mkv -c copy -map 0:v -map 0:a? -map 0:s? -f mp4 -tag:v hvc1 temp.mp4
::   MP4Box.exe -add temp.mp4 -new output.mp4 -color=1

:: PIX_FMT ������� ࠭�� - ��।��塞 JPEG FULL RANGE �� PIX_FMT
if /i "%PIX_FMT%" == "yuvj420p" set "COLOR_RANGE=1"

:: ����� ����� if (...) ⠪ ��� ��ன %OUTPUT_EXT% �� ��ன ��ப� �� ������ ���� set
if "%OUTPUT_EXT%" == "mkv" goto COLOR_RANGE_DONE
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% ��� ����� metadata full color � ������� mkvpropedit - ���塞 ���७�� �� mkv
set "OUTPUT_EXT=mkv"
set "OUTPUT=%OUTPUT_DIR%%OUTPUT_NAME%.%OUTPUT_EXT%"
:COLOR_RANGE_DONE







:: === ����: ������� ===
:: ��� ���� ������ ���� ��᫥ ����� ���� � ��। ������ �������
:: ��।���� ᯮᮡ ������:
:: - 䨧��᪨� (transpose), �᫨ ����� �����ন���� (*nvenc, *amf)
:: - ��� �१ metadata rotate � MP4 (��� *qsv)
:: ���뢠��: user ROTATION, ⥣ Rotate � MP4/MOV
:: ��⠭��������: ROTATION_FILTER, ROTATION_METADATA, EFFECTIVE_H

:: SRC_H, SRC_W � ROTATION_TAG �����祭� ࠭��
set "ROTATION_FILTER="
set "ROTATION_METADATA="
set "EFFECTIVE_H=%SRC_H%"

:: �஢��塞 user-set - �� �ਮ���
if defined ROTATION (
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% ���짮��⥫� ����� ROTATION=%ROTATION%
    goto APPLY_ROTATION
)

:: ���쪮 MP4/MOV �����ন���� ⥣ Rotate
set "SUPPORTS_ROTATE_TAG="
if /i "%EXT%" == ".mp4" set "SUPPORTS_ROTATE_TAG=1"
if /i "%EXT%" == ".mov" set "SUPPORTS_ROTATE_TAG=1"
if not defined SUPPORTS_ROTATE_TAG goto ROTATION_DONE
if not defined ROTATION_TAG goto ROTATION_DONE
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% � metadata ������ ⥣ Rotate: "%ROTATION_TAG%"
set "ROTATION=%ROTATION_TAG%"

:APPLY_ROTATION
:: ������ *qsv �� �����ন���� 䨫��� transpose - �ᯮ��㥬 metadata
if /i not "%CODEC:~-3%" == "qsv" goto TRY_TRANSPOSE
if not defined COLOR_RANGE goto CHANGE_EXT
:: ���䫨��: full-range (�ॡ�� MKV) � rotate tag (�ॡ�� MP4) �� ������ ��� transpose (qsv)
:: ��襭��: full-range ������ - 䠩� �ய�᪠����
echo([ERROR] ���䫨��: colour-range � rotate ��� "%CODEC%" - ���������� �����.
echo(colour-range ������. ����୨� ����� �� ����஢���� ��� ᬥ��� �����. ���� �ய�饭.
echo(
>>"%LOG%" echo([ERROR] %DATE% %TIME:~0,8% ���䫨��: colour-range � rotate. ������ �����. ���� �ய�饭.
goto NEXT

:CHANGE_EXT
:: ��� ����� ⥣� rotate � metadata �ॡ���� MP4
::   - ⥣ rotate �� ࠡ�⠥� � MKV (������ ��� ���������)
::   - ����� %CODEC% �� �����ন���� 䨫��� transpose (����� �������� 䨧��᪨)
:: ���⮬� �६���� ���塞 ���७�� �� mp4, ���� �᫨ ��࠭ mkv
if "%OUTPUT_EXT%" == "mp4" goto SKIP_CHANGE_EXT
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% ���塞 ���७�� �� mp4 ��� ����� ⥣� Rotate
set "OUTPUT_EXT=mp4"
set "OUTPUT=%OUTPUT_DIR%%OUTPUT_NAME%.%OUTPUT_EXT%"
:SKIP_CHANGE_EXT
:: ���࠭塞 ������ ��� metadata
set "ROTATION_METADATA=-metadata:s:v:0 rotate=%ROTATION%"
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% ������ ������� ���������� - �㤥� ��࠭� ��� ⥣ metadata � 䠩�� MP4
goto ROTATION_DONE

:TRY_TRANSPOSE
:: �� 䨧��᪮� ������ (transpose) �ਭ� �⠭������ ���⮩: EFFECTIVE_H = SRC_W
if "%ROTATION%" == "-90" (
    set "ROTATION_FILTER=transpose=1"
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% �ਬ��� ������ �� 90 �ࠤ�ᮢ �� �ᮢ�� ��५��
    set "EFFECTIVE_H=%SRC_W%"
    goto ROTATION_DONE
)
if "%ROTATION%" == "90" (
    set "ROTATION_FILTER=transpose=2"
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% �ਬ��� ������ �� 90 �ࠤ�ᮢ ��⨢ �ᮢ�� ��५��
    set "EFFECTIVE_H=%SRC_W%"
    goto ROTATION_DONE
)

:ROTATION_DONE






:: === ����: ������� ===
:: �ਭ����� �襭�� � ����⠡�஢����:
:: - SCALE=1: �� 720p, �᫨ ���� > 720
:: - SCALE=: �� 1080p, �᫨ 䨧��᪨ ������� � ���� > 1080
:: ��⠭��������: SET_SCALE_FILTER, SCALE_EXPR

set "SET_SCALE_FILTER="
set "SCALE_EXPR="
:: EFFECTIVE_H 㦥 ��⠭������ � ����� ROTATION_SETUP
:: ��� ROTATION_FILTER: EFFECTIVE_H = SRC_H. ����: EFFECTIVE_H = SRC_W

:: �᫨ SCALE �� ����� - ���室�� � ��ࠡ�⪥ ��� ����⠡�஢���� �� �������
if not defined SCALE goto CHECK_SCALE_EMPTY

:: SCALE=1 - ����� - 㬥��蠥� �� 720 ⮫쪮 �� �ॢ�襭�� �����
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% ����� SCALE=1: ���� ��᫥ ������ %EFFECTIVE_H% -
if %EFFECTIVE_H% LEQ 720 (
    >>"%LOG%" echo([INFO] 720 ��� ����� - �� ����⠡��㥬.
    goto SKIP_SCALE
)
>>"%LOG%" echo([INFO] ����� 720 - ����⠡��㥬 �� 720

:: �� 䨧��᪮� ������ (transpose) �ਭ� �⠭������ ���⮩ - ����⠡��㥬 �� �ਭ�
if defined ROTATION_FILTER (
    set "SCALE_EXPR=scale=720:-2"
    goto SET_SCALE_FLAG
)

:: �����᪮�� ������ ��� - ����⠡��㥬 �� ����
set "SCALE_EXPR=scale=-2:720"
goto SET_SCALE_FLAG

:: �᫨ SCALE �� ����� -> ����⠡��㥬 �� 1080 ������ �᫨ 䨧��᪨ ������� � ���� > 1080
:CHECK_SCALE_EMPTY
if not defined ROTATION_FILTER goto SKIP_SCALE

>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% ���� 䨧��᪨ �������, ���� ��᫥ ������ %EFFECTIVE_H%
if %EFFECTIVE_H% LEQ 1080 (
    >>"%LOG%" echo([INFO] 1080 ��� ����� - �� ����⠡��㥬.
    goto SKIP_SCALE
)
>>"%LOG%" echo([INFO] ����� 1080 - ����⠡��㥬 �� 1080.
set "SCALE_EXPR=scale=1080:-2"

:SET_SCALE_FLAG
set "SET_SCALE_FILTER=1"

:SKIP_SCALE






:: === ����: ������� ===
:: ����: �ਢ��� VFR (variable frame rate) � CFR (constant), �⮡�:
:: - �������� �஡��� � ������묨 �������� (������� �� �� ����),
:: - ������ ᮢ���⨬���� � �ந��뢠⥫ﬨ � ��.
:: r_frame_rate = ������� ���� (���ਬ��, 30000/1001)
:: avg_frame_rate = �।��� �� �����
:: �� ��ᮢ������� ����砥� VFR FPS.
:: FIELD_ORDER, R_FPS � A_FPS �����祭� ࠭��

:: �ய�᪠�� ������ FPS, �᫨ ����� ������筮�
if /i not "%FIELD_ORDER%" == "progressive" (
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% �����㦥�� ������筮� �����. �ய�᪠�� ������ FPS VFR.
    goto FPS_DONE
)

if defined FPS (
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% FPS ����� �ਭ㤨⥫쭮: %FPS%, �ய�᪠�� ��� ��ࠡ���
    goto FPS_DONE
)

if not defined R_FPS (
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% �� 㤠���� ������� r_frame_rate - ������ VFR �ய�饭
    goto FPS_DONE
)
:: ��� �஢��� ��⠢�塞 ⮫쪮 ��� ����, ⠪ ��� �᫨ ��� R_FPS, � � �� � 祬 �ࠢ������
if not defined A_FPS (
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% �� 㤠���� ������� avg_frame_rate - ������ VFR �ய�饭
    goto FPS_DONE
)

:: �᫨ r_frame_rate == avg_frame_rate - �� CFR, ��祣� �� ������
if "%R_FPS%" == "%A_FPS%" goto FPS_DONE

:: �᫨ ��諨 � - �����: progressive, R/A_FPS ����, �� �� ࠢ�� -> VFR
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% �����㦥� FPS VFR. ��������� max frame rate �� mediainfo
set "MAX_FPS="
set "TMPMI=%temp%\%CMDN%-mi-fps-%random%%random%.txt"
"%MI%" --Inform="Video;%%FrameRate_Maximum%%" "%FNF%" >"%TMPMI%"
set /p MAX_FPS= <"%TMPMI%"
del "%TMPMI%"
if not defined MAX_FPS (
    >>"%LOG%" echo([WARNING] %DATE% %TIME:~0,8% �� 㤠���� ������� max frame rate �� mediainfo
    goto FPS_DONE
)

>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% �����祭 max frame rate: %MAX_FPS%

:: ��⠢�塞 ⮫쪮 楫� ���祭�� FPS
for /f "tokens=1 delims=." %%m in ("%MAX_FPS%") do set "MAX_FPS=%%m"

:: �ਭ㤨⥫쭮 ��⠭�������� ������訩 FPS CFR
set "FPS=25"
if %MAX_FPS% GTR 25 set "FPS=30"
:: 35 - ᯥ樠�쭮 ��� 䠩��� � VFR ~31.4 fps
if %MAX_FPS% GTR 35 set "FPS=50"
if %MAX_FPS% GTR 50 set "FPS=60"
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% �� ���������� ��⠭����� FPS CFR: %FPS%
:FPS_DONE






:: === ����: ������� ===
:: ��䨫� ����஢���� profile: main/high - 8 bit, main10 - 10 bit. ��� ��� H.264 - ⮫쪮 high.
:: ��ଠ� ���ᥫ�� pix_fmt: � ����ᨬ��� �� ��䨫� � �����প� �������
set "USE_PROFILE=high"
set "PIX_FMT_ARGS=-pix_fmt yuv420p"
:: H.264 �ᯮ���� ��䨫� high �� 㬮�砭��
if /i "%CODEC:~0,5%" == "h264_" goto PROFILE_PIX_DONE
if /i "%CODEC%" == "libx264" goto PROFILE_PIX_DONE
:: ��� HEVC �ᯮ��㥬 main10, libx265 �ॡ�� yuv420p10le
set "USE_PROFILE=main10"
set "PIX_FMT_ARGS=-pix_fmt p010le"
if /i "%CODEC%" == "libx265" set "PIX_FMT_ARGS=-pix_fmt yuv420p10le"
:: �᫨ ���짮��⥫� � ����ᨫ ��� HEVC ��䨫� main - ���塞
if /i not "%PROFILE%" == "main" goto PROFILE_PIX_DONE
set "USE_PROFILE=main"
set "PIX_FMT_ARGS=-pix_fmt yuv420p"
:PROFILE_PIX_DONE
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% ��⠭����� ��䨫� ����஢����: %USE_PROFILE%
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% ��⠭����� �ଠ� ���ᥫ��: %PIX_FMT_ARGS%







:: === ����: ����������� ===
:: ��� ���� ������ ���� ��᫥ ������ �������, �������, �������
:: ���冷� 䨫��஢: scale -> transpose -> deinterlace -> fps
::   - scale �� ������ (ࠧ����), deinterlace ��᫥ (�ਥ����), fps � ���� (VFR)
set "FILTER_LIST="
:: ������塞 scale, �᫨ �� �ய�饭 � �����
if not defined SET_SCALE_FILTER goto SKIP_SCALE
if not defined SCALE_EXPR goto SKIP_SCALE
if defined FILTER_LIST (
    set "FILTER_LIST=%FILTER_LIST%,%SCALE_EXPR%"
    goto SKIP_SCALE
)
set "FILTER_LIST=%SCALE_EXPR%"
:SKIP_SCALE

:: ������塞 transpose, �᫨ �����
if not defined ROTATION_FILTER goto SKIP_TRANSPOSE
if defined FILTER_LIST (
    set "FILTER_LIST=%FILTER_LIST%,%ROTATION_FILTER%"
    goto SKIP_TRANSPOSE
)
set "FILTER_LIST=%ROTATION_FILTER%"
:SKIP_TRANSPOSE

:: ������塞 �����૥��, �᫨ ������
if /i "%FIELD_ORDER%" == "progressive" goto SKIP_DEINT
set "INTCMD=bwdif=1"
if defined FILTER_LIST (
    set "FILTER_LIST=%FILTER_LIST%,%INTCMD%"
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% �ਬ��� �����૥�ᨭ�: %INTCMD%
    goto SKIP_DEINT
)
set "FILTER_LIST=%INTCMD%"
:SKIP_DEINT

:: ������塞 fps, �᫨ �����
if not defined FPS goto SKIP_FPS
if defined FILTER_LIST (
    set "FILTER_LIST=%FILTER_LIST%,fps=%FPS%"
    goto SKIP_FPS
)
set "FILTER_LIST=fps=%FPS%"
:SKIP_FPS

:: ��ନ�㥬 �⮣��� 䫠� -vf
if not defined FILTER_LIST (
    set "VF="
    goto VF_DONE
)
set "VF=-vf "%FILTER_LIST%""
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% �����䨫���: %VF%
:VF_DONE







:: === ����: ����� ===
:: ���冷� ���祩 �������� (�ᮡ���� ��� qsv): ����� -> ��䨫� -> vf -> crf
:: ��騩 ���冷� ���祩 ffmpeg ������ ���� ⠪��:
:: -hide_banner -c:v codec [-profile:v] [-preset] [-vf] [-pix_fmt] [-crf] [-tune] [-level]
:: [-metadata rotate] -c:a -c:s [-metadata lng]
set "FINAL_KEYS=-hide_banner -c:v %CODEC%"
if /i not "%CODEC:~-5%" == "nvenc" set "FINAL_KEYS=%FINAL_KEYS% -profile:v %USE_PROFILE%"
if /i "%CODEC%" == "libx264" set "FINAL_KEYS=%FINAL_KEYS% -preset slow -tune film"

:: ��ࠡ�⪠ CRF/VBR ��� *nvenc:
if /i not "%CODEC:~-5%" == "nvenc" goto SKIP_NVENC_OPTS
set "FINAL_KEYS=%FINAL_KEYS% -preset p7 -tune uhq"
:: -multipass fullres ��ᮢ���⨬ � CRF, �� ���� ����⢮ ���
:: �� multipass �㦭� �������� ���३�: -b:v - 楫���� ���३� (average)
:: -maxrate - ������ ���३�, -bufsize - ࠧ��� ���� ������� (VBV)
:: bufsize ������ ���� �� ����� maxrate, ���� ����� ���� �஡���� � �ந��뢠⥫ﬨ
:: ��⨬����: 720: -b:v 2.5M -maxrate 3.5M -bufsize 4M. 1080: -b:v 4.5M -maxrate 6M -bufsize 7M
if defined CRF (
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% NVENC: �ᯮ������ CRF-०�� -cq %CRF%
    goto SKIP_BITRATE
)
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% NVENC: �ᯮ������ VBR-HQ � multipass, ���३� �� ���� %EFFECTIVE_H%p
:: ��⠭�������� ���३� �� EFFECTIVE_H
if %EFFECTIVE_H% LEQ 720 (
    set "BITRATE_V=2.5M"
    set "BITRATE_MAX=3.5M"
    set "BITRATE_BUF=4M"
)
if %EFFECTIVE_H% GTR 720 (
    set "BITRATE_V=4.5M"
    set "BITRATE_MAX=6M"
    set "BITRATE_BUF=7M"
)
set "FINAL_KEYS=%FINAL_KEYS% -multipass fullres"
set "FINAL_KEYS=%FINAL_KEYS% -b:v %BITRATE_V% -maxrate %BITRATE_MAX% -bufsize %BITRATE_BUF%"
:SKIP_BITRATE
set "FINAL_KEYS=%FINAL_KEYS% -rc-lookahead 32 -spatial_aq 1"
set "FINAL_KEYS=%FINAL_KEYS% -aq-strength 12 -temporal_aq 1 -b_ref_mode each"
:: �᫨ �㤥� �訡�� b_ref_mode 'each' is not supported - ������ -b_ref_mode middle
:SKIP_NVENC_OPTS

:: Level ��� h264_* ������� (ᮢ���⨬���� � �ந��뢠⥫ﬨ)
if /i "%CODEC:~0,5%" == "h264_" set "FINAL_KEYS=%FINAL_KEYS% -level 4.0"
if /i "%CODEC%" == "libx264" set "FINAL_KEYS=%FINAL_KEYS% -level 4.0"

:: �����䨫��� -vf
if defined VF set "FINAL_KEYS=%FINAL_KEYS% %VF%"

:: ��ଠ� ���ᥫ�� (8 bit yuv420p ��� 10 bit yuv420p10le)
if defined PIX_FMT_ARGS set "FINAL_KEYS=%FINAL_KEYS% %PIX_FMT_ARGS%"

:: ��ࠬ���� �ࠢ����� ����⢮� (�� ���३⮬)
set "FINAL_CRF="
if not defined CRF goto SKIP_CRF
if /i "%CODEC:~-5%" == "nvenc"  set "FINAL_CRF=-cq %CRF%"
if /i "%CODEC:~-3%" == "amf"    set "FINAL_CRF=-rc cqp -qp_i %CRF% -qp_p %CRF% -quality quality"
if /i "%CODEC:~-3%" == "qsv"    set "FINAL_CRF=-global_quality %CRF%"
if /i "%CODEC:~0,5%" == "libx2" set "FINAL_CRF=-crf %CRF%"
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% CRF ��⠭�����: %CRF%
:SKIP_CRF
if defined FINAL_CRF set "FINAL_KEYS=%FINAL_KEYS% %FINAL_CRF%"

:: Metadata - Rotate �᫨ �� �����稢��� ����� ��-�� �������ন������� �����⭮�� ������
if defined ROTATION_METADATA set "FINAL_KEYS=%FINAL_KEYS% %ROTATION_METADATA%"

:: �㤨� � ������
if not defined AUDIO_ARGS set "AUDIO_ARGS=-c:a copy"
set "FINAL_KEYS=%FINAL_KEYS% %AUDIO_ARGS% -c:s copy"

:: ��⠭�������� �� �㤨� � ����஢ � "rus". ��� ����� - �� �ண���: 
:: ffmpeg ������ �� �ਢ� � MKV, � � MP4 ����� ������� und/eng.
:: ��� �������஦�� ��⠭���������� �१ mkvpropedit - ffmpeg ������ �� �����४⭮ � MKV.
:: �᫨ ������ full-range (COLOR_RANGE=1) - mkvpropedit ⠪�� ������� 梥⮢� ��⠤����.
set "FINAL_KEYS=%FINAL_KEYS% -metadata language=rus"
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:a:0 language=rus"
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:s:0 language=rus"

:: ����塞 ���� �����-⥣� "���३�" � "ࠧ��� ��⮪�", �᫨ ��� ����.
:: FFmpeg ������� �� �� ��室����, �� �� ��४���஢���� ���祭�� �����㠫��.
if not defined HAS_VIDEO_TAGS goto SKIP_CLEAN
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:v BPS="
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:v BPS-eng="
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:v NUMBER_OF_BYTES="
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:v NUMBER_OF_BYTES-eng="
:: ����塞 ���� �㤨�-⥣� "���३�" � "ࠧ��� ��⮪�" ������ �� ��४���஢����,
:: ⠪ ��� �� -c:a copy ���祭�� ������� ���४�묨.
if "%AUDIO_ARGS%" == "-c:a copy" goto SKIP_CLEAN
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:a BPS="
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:a BPS-eng="
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:a NUMBER_OF_BYTES="
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:a NUMBER_OF_BYTES-eng="
:SKIP_CLEAN





:: === ����: ��������� ===
:: ��襬 CMD_LINE � ��� �१ set, ⠪ ��� ���� ���� � ����窠�� � ᯥ�ᨬ������
set "CMD_LINE="%FFM%" -i "%FNF%" %FINAL_KEYS% "%OUTPUT%""
>>"%LOG%" echo([CMD] %DATE% %TIME:~0,8% ��ப� ����஢����: %CMD_LINE%
:: ����� ����஢����. FFmpeg ���� ��� � stderr, � �� � stdout - ���⮬� 2>LOG
:: �� ����᪠�� �१ %CMD_LINE%, �.�. ����� ���� �訡�� �� ᯥ�ᨬ�����.
"%FFM%" -i "%FNF%" %FINAL_KEYS% "%OUTPUT%" 2>"%FFMPEG_LOG%"

:: ��������㥬 ��� � OEM ��� findstr (�. ���� GPU-�஢�ન)
:: ��� ������ ���� ��� ��ਫ���� ��-�� ࠧ��� ����஢�� CMD � VBS
:: ���室�� � ����� Logs
set "VT=%temp%\%CMDN%-utf2oem-%random%%random%.vbs"
pushd "%OUTPUT_DIR%logs"
set "TMPFLUTF=flogutf_%random%%random%"
set "TMPFLOEM=flogoem_%random%%random%"
if exist "%TMPFLUTF%" del "%TMPFLUTF%"
if exist "%TMPFLOEM%" del "%TMPFLOEM%"
copy "%FFMPEG_LOG_NAME%" "%TMPFLUTF%">nul
>"%VT%" echo(With CreateObject("ADODB.Stream"^)
>>"%VT%" echo(.Type=2:.Charset="UTF-8":.Open:.LoadFromFile "%TMPFLUTF%"
>>"%VT%" echo(s=.ReadText:.Close
>>"%VT%" echo(.Type=2:.Charset="cp866":.Open:.WriteText s
>>"%VT%" echo(.SaveToFile "%TMPFLOEM%",2:.Close
>>"%VT%" echo(End With
cscript //nologo "%VT%"
del "%TMPFLUTF%"
set "FFERR="
:: �� ���뢠�� ��ப� findstr �� if errorlevel
findstr /i "error failed" "%TMPFLOEM%">nul
if %ERRORLEVEL% EQU 0 (
    set "FFERR=1"
    echo(FFmpeg �����訫�� � �訡���! C�. "%FFMPEG_LOG_NAME%"
    echo(
    >>"%LOG%" echo([ERROR] %DATE% %TIME:~0,8% FFmpeg �����訫�� � �訡��� - �. "%FFMPEG_LOG_NAME%"
)
del "%TMPFLOEM%"
popd
del "%VT%"
if not exist "%OUTPUT%" goto FINISH
if defined FFERR goto CLEAN

:: �᫨ 䠩� - MKV �� �� full-range - ⮫쪮 ���塞 �� ����� �� ���᪨�
:: ��⠫�� ��஦�� (�㤨�, ������) 㦥 ����稫� language=rus �१ ffmpeg -metadata (�. ���)
if not "%OUTPUT_EXT%" == "mkv" goto SUCCESS
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% � MKV ���塞 �� �������஦�� �� ���᪨�
if defined COLOR_RANGE goto MKVFULLRANGE
"%MKVP%" "%OUTPUT%" --edit track:v1 --set "language=rus">nul
goto SUCCESS

:MKVFULLRANGE
:: ��� MKV Full-range ������塞 梥⮢� ��⠤���� + ���塞 �� �� ���᪨�
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Full color range: ������塞 � MKV ⥣� colour-range
"%MKVP%" "%OUTPUT%" --edit track:v1 --set "language=rus" --set "colour-range=1" --set "color-matrix-coefficients=1">nul

:SUCCESS
echo(������ "%OUTPUT_NAME%.%OUTPUT_EXT%".
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% ������ "%OUTPUT_NAME%.%OUTPUT_EXT%"
>>"%LOG%" echo(---
goto FINISH

:CLEAN
:: �᫨ ffmpeg ��᫥ �訡�� ᮧ��� �㫥��� 䠩� - 㤠�塞 ���
for %%F in ("%OUTPUT%") do set SIZE=%%~zF
if %SIZE% EQU 0 del "%OUTPUT%"

:FINISH
echo(%DATE% %TIME:~0,8% ��ࠡ�⪠ "%FNWE%" �����襭�.
echo(C�. ���� � ����� "%OUTPUT_DIR%logs".
echo(---

:: ��������㥬 OEM-��� � UTF-8:
:: %LOGE% - �室��� OEM-���, %LOGU% - ��室��� UTF-8-���.
:: ��� ������ ���� ��� ��ਫ���� ��-�� ࠧ��� ����஢�� CMD � VBS
:: ���室�� � ����� Logs
set "VT=%temp%\%CMDN%-oem2utf-%random%%random%.vbs"
pushd "%OUTPUT_DIR%logs"
>"%VT%" echo(With CreateObject("ADODB.Stream"^)
>>"%VT%" echo(.Type=2:.Charset="cp866":.Open:.LoadFromFile "%LOGE%"
>>"%VT%" echo(s=.ReadText:.Close
>>"%VT%" echo(.Type=2:.Charset="UTF-8":.Open:.WriteText s
>>"%VT%" echo(.SaveToFile "%LOGU%",2:.Close
>>"%VT%" echo(End With
cscript //nologo "%VT%"
del "%LOGE%"
if exist "%LOGN%" del "%LOGN%"
ren "%LOGU%" "%LOGN%"
popd
del "%VT%"

:: ���室 � ᫥���饬� 䠩��
:NEXT
shift
goto FILE_LOOP

:: �����襭�� ࠡ��� �ਯ�
:FILE_LOOP_END
echo(�� 䠩�� ��ࠡ�⠭�.
echo(
set "EV=%temp%\%CMDN%-end-%random%%random%.vbs"
set "EMSG=������ 䠩� %CMDN% �����稫 ࠡ���."
chcp 1251 >nul
>"%EV%" echo(MsgBox "%EMSG%",,"%CMDN%"
chcp 866 >nul
cscript //nologo "%EV%"
del "%EV%"
pause
exit