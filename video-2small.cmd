@echo off
set "DO=Video recode script"
set "VRS=Froz %DO% v27.08.2025"
:: ���� �ਯ�: ��४���஢���� �����䠩��� � ⥫�䮭��/�⮠����⮢
:: � 㬥��襭�� ࠧ��� ��� �������娢� ��� ����⢥���� ���� ����⢠.


:: === ����: ����ன�� ===

:: ���� ���� (���.). �ਬ��: 720. �� 1080->720 ᫠�� ����� �� ࠧ��� 䠩��
set "SCALE="

:: ������: 90 (�� ��), 180, 270 (90 ��⨢ ��). �᫨ ���� - ������ �� ⥣�.
:: *qsv � *d3d12va - �� �����ন���� ������! *amf - ����� ������.
set "ROTATION="

:: �������:
:: HEVC (H.265):
::    hevc_nvenc   - NVIDIA GPU - ४�����㥬�. �ॡ���� GeForce GTX 950 � ��� + �ࠩ��� 570+
::    hevc_amf     - AMD GPU
::    hevc_qsv     - Intel Quick Sync Video
::    hevc_d3d12va - Windows Direct 12 (DXVA2), �����⭠� �����প�
::    libx265      - software ����஢���� HEVC (�祭� �������� - CPU)
:: H.264: h264_nvenc (४�����㥬�), h264_amf, h264_qsv, libx264 (�������� - CPU)
set "CODEC=hevc_nvenc"

:: ���� ��� ������ hevc_nvenc. ���祭��: p1 -> p7 (᪮���� -> ����⢮).
:: �� 㬮�砭�� hevc_nvenc �롨ࠥ� p4 (~CRF20, �� 720p ~2,5 ����/�)
set "PRESET="

:: ��䨫� ����஢����: ⮫쪮 ��� HEVC: main10 (10 bit) ��� main (8 bit).
:: H.264 - �ᥣ�� �㤥� �ਬ��� high, ������ᨬ� �� 㪠������� �����.
:: �᫨ �� ������ - �롨ࠥ� �����.
:: �����প� main10 �������� HEVC: nvenc, amf, libx265. ����� �� ࠡ���� �� ����� ���ன�⢠�!
set "PROFILE=main10"

:: CRF: �஢��� ����⢠ (४. 20-24). �᫨ �� ����� - ����� �롨ࠥ� ᠬ.
:: ��� libx265/264: ���� 㪠���� CRF20, ���� �㤥� CRF28 (������ ����⢮).
:: hevc_nvenc �� 㬮�砭�� �롨ࠥ� ~CRF20. �� ~2.5 ����/� ��� 720p.
set "CRF="

:: �㤨�: -c:a copy (�� 㬮�砭��). ��� 㬥��襭�� ࠧ���: -c:a libopus -b:a 128k
:: ��᪮�������� �㦭� ��ਠ��, � ��㣮� ������������ �१ ::
set "AUDIO_ARGS=-c:a copy"
::set "AUDIO_ARGS=-c:a libopus -b:a 128k"

:: 1 - �ਭ㤨⥫쭮 full range, �᫨ ����� Full Range JPEG, �� �� YUVJ420P. �ࠩ�� ।��.
set "FORCE_FULL_RANGE="

:: FPS - ��⠭���� 楫���� ����� ���஢ (����易⥫쭮)
:: �ਬ���: 24, 25, 30, 50, 60, 24000/1001 (~23.976), 30000/1001 (~29.97) � �.�.
:: �᫨ �� ������ - ���� ���஢ ������� �� ��室���� (FPS CFR ��� VFR).
:: �ਬ��: set "FPS=30000/1001"


:: ������� ���� ���஢ (���.). �᫨ ���� - ������� �� ��室����.
:: �ਬ��: 24, 25, 30, 50, 60, 24000/1001 (~23.976), 30000/1001 (~29.97)
set "FPS="

:: ���⥩���: mkv (㭨���ᠫ쭥�) ��� mp4. ��� �������� ������� H.264 - ���� mp4.
set "OUTPUT_EXT=mkv"

:: ���䨪� � ����� 䠩�� �� ��室�
set "NAME_APPEND=_sm"

:: �業�� �६��� ����஢���� ��� ��襣� GPU/CPU.
:: ��� �������: (ᥪ㭤_����஢���� / ᥪ㭤_�����) x 100. �ਬ��: 0.3 -> �⠢�� 30.
:: �������� �ਯ�� ����� �筮 �������� �ਬ�୮� �६�.
:: ���� ���祭�� ��� �ࠢ�����: GTX 1050 � i3-2120: SPEED_NVENC=30, SPEED_LIBX265=500
set "SPEED_NVENC=10"
set "SPEED_AMF=20"
set "SPEED_QSV=20"
set "SPEED_LIBX264=50"
set "SPEED_LIBX265=100"
:: === ����砭�� ����� ����஥� ===





:: === ����: �஢�ન ===
title %DO%
echo(%VRS%
echo(
set "CMDN=%~n0"
:: �஢�ઠ ������ �室��� 䠩���
if "%~1" == "" (
    echo(�ᯮ�짮�����: �஢���� ���� ��⠭���� SET � ��砫� �ਯ�.
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
if not exist "%MKVP%" echo"(%MKVP%" �� ������, ��室��.& echo(& pause & exit /b





:: === ����: ���� ===
:FILE_LOOP
:: �����뢠�� ��� 䠩�� � ��६���� �⮡� %1 �� ᫮������ � �����
set "FNF=%~1"
set "FNN=%~n1"
set "FNWE=%~nx1"
set "EXT=%~x1"

:: �᫨ ����� ��� 䠩��� - ��室��
if "%FNF%" == "" goto FILE_LOOP_END

:: �६����� ��� OEM-���� - �ᯮ��㥬 ����, � �� %random%
set "TH=%time:~0,2%"
if "%TH:~0,1%"==" " set "TH=0%TH:~1,1%"
set "TYMDHMS=%date:~6,4%-%date:~3,2%-%date:~0,2%_%TH%-%time:~3,2%-%time:~6,2%"

:: ����� � ����� �����
set "OUTPUT_DIR=%~dp1"
set "OUTPUT_NAME=%FNN%%NAME_APPEND%"
set "OUTPUT=%OUTPUT_DIR%%OUTPUT_NAME%.%OUTPUT_EXT%"
set "LOGE=%TYMDHMS%oem"
set "LOG=%OUTPUT_DIR%logs\%LOGE%"
set "LOGU=%TYMDHMS%utf"
set "LOGN=%FNN%%NAME_APPEND%-log.txt"

:: ��������� ���� � ���� 䠩� �� ��������, �.�. ffmpeg �뢮��� ��� � UTF-8, � cmd � OEM
set "FFMPEG_LOG_NAME=%OUTPUT_NAME%-log_ffmpeg.txt"
set "FFMPEG_LOG=%OUTPUT_DIR%logs\%FFMPEG_LOG_NAME%"
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








:: === ����: ����� ===
:: ����砥� ���⥫쭮��� �����. ���� :nk=1 ����� ⥪�� "duration="
set "TMP_FILE=%TEMP%\ffprobe_time_%random%%random%.tmp"
"%FFP%" -v error -show_entries format=duration -of default=nw=1:nk=1 "%FNF%" >"%TMP_FILE%"
set /p LENGTH_SECONDS= <"%TMP_FILE%"
del "%TMP_FILE%"
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

:: Fallback, �᫨ ����� �� �ᯮ����
if not defined SPEED_CENTI (
    >>"%LOG%" echo([WARNING] %DATE% %TIME:~0,8% ��������� �����: %CODEC%.
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% ��� ����� �६��� ����஢���� ��६ ᪮���� 50
    set "SPEED_CENTI=50"
)

:: ������뢠�� �ਬ�୮� �६� ����஢����
set /a ENCODE_SECONDS = (LENGTH_SECONDS * SPEED_CENTI) / 100

:: ������ 1 ᥪ㭤�
if %ENCODE_SECONDS% LSS 1 set "ENCODE_SECONDS=1"

:: ��ॢ���� � ������:ᥪ㭤�
set /a "MINUTES=ENCODE_SECONDS / 60"
set /a "SECONDS=ENCODE_SECONDS %% 60"
if %SECONDS% LSS 10 set "SECONDS=0%SECONDS%"

echo(�ਬ�୮� �६� ����஢����: %MINUTES% ����� %SECONDS% ᥪ㭤.
echo(
:DONE_LENGTH





:: === ����: COLOR RANGE ===
set "PIX_FMT="
:: �᫨ ����� Force full range
set "COLOR_RANGE="
if defined FORCE_FULL_RANGE (
    set "COLOR_RANGE=1"
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% ����� Force color range
    goto COLOR_RANGE_DONE
)
:: ��।������ full range �१ ffprobe. ���� :nk=1 ����� ⥪�� "pix_fmt="
set "TMP_FILE=%TEMP%\ffprobe_pix_fmt_%random%%random%.tmp"
"%FFP%" -v error -select_streams v:0 -show_entries stream=pix_fmt -of default=nw=1:nk=1 "%FNF%" >"%TMP_FILE%"
if not exist "%TMP_FILE%" (
    >>"%LOG%" echo([ERROR] %DATE% %TIME:~0,8% �� ����稫��� ᮧ���� �६���� 䠩� "%TMP_FILE%"
    goto COLOR_RANGE_DONE
)
set /p PIX_FMT= <"%TMP_FILE%"
del "%TMP_FILE%"
if not defined PIX_FMT (
    >>"%LOG%" echo([ERROR] %DATE% %TIME:~0,8% FFProbe �� ᬮ� ��।����� �ଠ� ���ᥫ��
    goto COLOR_RANGE_DONE
)
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% ��ଠ� ���ᥫ�� ��室����: %PIX_FMT%
for /f "tokens=1" %%a in ("%PIX_FMT%") do set "PIX_FMT=%%a"
:: ��⮮�।������ full range �� pix_fmt
if /i "%PIX_FMT%" == "yuvj420p" (
    set "COLOR_RANGE=1"
)

:: �᫨ OUTPUT_EXT = mp4 - ���塞 �� mkv
if not "%OUTPUT_EXT%" == "mp4" goto COLOR_RANGE_DONE
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% ��� ����� metadata full color � ������� mkvpropedit - ���塞 ���७�� �� mkv
set "OUTPUT_EXT=mkv"
set "OUTPUT=%OUTPUT_DIR%%OUTPUT_NAME%.%OUTPUT_EXT%"
:COLOR_RANGE_DONE






:: === ����: CURRENT SIZE ===
:: ����砥� ��室�� ࠧ���� ����� ��� ������ � ����⠡�஢���� �१ ffprobe
:: �ᯮ��㥬 �६���� 䠩�, ⠪ ��� ��� �뢮� ffprobe ����� ᮤ�ঠ��:
::     - �஡��� (���ਬ��, "1920 1080")
::     - ᯥ樠��� ᨬ���� (���ਬ��, escape-ᨬ����, �������)
::     - ����� ��ப� ��� �訡��
:: ����� ����� ᫮���� for /f
set "CURRENT_DIM="
set "TMP_FILE=%TEMP%\video_info_%random%%random%.tmp"
"%FFP%" -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "%FNF%" >"%TMP_FILE%"
if not exist "%TMP_FILE%" goto SKIP_CURRENT_DIM
:: ��������� ����� �������� ��ப� (goto '��室' �㦥� ��� ���뢠��� 横��)
for /f "tokens=1,2 delims=," %%a in ('type "%TMP_FILE%"') do (
    set "CURRENT_W=%%a"
    set "CURRENT_H=%%b"
)
del "%TMP_FILE%"
if not defined CURRENT_W (
    >>"%LOG%" echo([ERROR] %DATE% %TIME:~0,8% FFProbe �� ᬮ� ��।����� �ਭ�/�����
    goto SKIP_CURRENT_DIM
)
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% ����襭�� ��室����: %CURRENT_W%x%CURRENT_H%
:SKIP_CURRENT_DIM





:: === ����: ROTATION ===
:: ���� ������ ���� �� ����� SCALE
set "ROTATION_FILTER="
set "ROTATION_METADATA="

:: �᫨ ROTATION �� ����� - ��⠥��� ������� ⥣ Rotate �� 䠩��
if not defined ROTATION goto NO_USER_ROTATION

:: �᫨ ������ ���祭�� �⫨筮� �� 0 - �ᯮ��㥬 ���
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% ����� USER ROTATION=%ROTATION%
goto APPLY_ROTATION

:NO_USER_ROTATION
if /i "%EXT%" == ".mp4" goto GET_ROTATE
if /i "%EXT%" == ".mov" goto GET_ROTATE
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% ��ଠ� %EXT% �� �����ন���� ⥣ Rotate - �����祭�� �ய�饭�.
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% �᫨ ����� ������� - �ਭ㤨⥫쭮 ������ set ROTATION.
goto NO_ROTATION_TAG

:GET_ROTATE
set "ROTATION_TAG="
set "TMP_FILE=%TEMP%\ffprobe_rotation_%random%%random%.tmp"
"%FFP%" -v error -show_entries stream_tags=rotate -of default=nw=1:nk=1 "%FNF%" >"%TMP_FILE%"
if not exist "%TMP_FILE%" goto NO_ROTATION_TAG
set /p ROTATION_TAG= < "%TMP_FILE%"
del "%TMP_FILE%"
if not defined ROTATION_TAG goto NO_ROTATION_TAG

:: ����塞 �஡���
set "ROTATION_TAG=%ROTATION_TAG: =%"
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% � metadata ������ ⥣ Rotate: "%ROTATION_TAG%"

:: ��⠭�������� ROTATION ⮫쪮 �᫨ ��� ��� �� ������
set "ROTATION=%ROTATION_TAG%"

:: �஢��塞, �����ন���� �� ����� ������
:APPLY_ROTATION
set "SUPPORTS_TRANSPOSE=1"
if /i "%CODEC%" == "hevc_qsv"     set "SUPPORTS_TRANSPOSE="
if /i "%CODEC%" == "hevc_d3d12va" set "SUPPORTS_TRANSPOSE="
if /i "%CODEC%" == "h264_qsv"     set "SUPPORTS_TRANSPOSE="
if /i "%CODEC%" == "h264_d3d12va" set "SUPPORTS_TRANSPOSE="
if not defined SUPPORTS_TRANSPOSE goto SAVE_ROTATION_METADATA

:SET_TRANSPOSE
:: ��ନ�㥬 䨫��� ������
if "%ROTATION%" == "90" (
    set "ROTATION_FILTER=transpose=1"
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% �ਬ��� ������ �� 90 �ࠤ�ᮢ �� �ᮢ�� ��५��
    goto ROTATION_DONE
)
:: transpose=2 - ������ �� 90 ��⨢ �ᮢ��, �� ��� �㦭� 180.
:: ���⮬� �ਬ��塞 ������: 90 + 90 = 180.
if "%ROTATION%" == "180" (
    set "ROTATION_FILTER=transpose=2,transpose=2"
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% �ਬ��� ������ �� 180 �ࠤ�ᮢ
    goto ROTATION_DONE
)
if "%ROTATION%" == "270" (
    set "ROTATION_FILTER=transpose=2"
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% �ਬ��� ������ �� 90 �ࠤ�ᮢ ��⨢ �ᮢ�� ��५��
    goto ROTATION_DONE
)

:: � ��������, �᫨ ������ ������� ����������, �� ����� ��࠭��� ��� metadata
:SAVE_ROTATION_METADATA

:: === ��������: full range vs rotate ===
:: ���������� �����६����:
::   - colour-range=1 (�ॡ�� MKV)
::   - ⥣ rotate (�ॡ�� MP4)
::   - � ����� ��� transpose (qsv/d3d12va)
:: ��襭��: colour-range ������. �ய�᪠�� 䠩�.
if defined COLOR_RANGE (
    echo([ERROR] ���䫨��: colour-range � rotate ��� %CODEC% - ���������� �����.
    echo(colour-range ������. ����୨� ����� �� ����஢���� ��� ᬥ��� �����.
    echo(
    >>"%LOG%" echo([ERROR] %DATE% %TIME:~0,8% ���䫨��: colour-range � rotate. ������ �����.
    goto NEXT
)

:: �᫨ OUTPUT_EXT = mkv - ���塞 �� mp4
if not "%OUTPUT_EXT%" == "mkv" goto ROT_EXT_OK
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% ���塞 ���७�� �� mp4 ��� ����� ⥣� Rotate
set "OUTPUT_EXT=mp4"
set "OUTPUT=%OUTPUT_DIR%%OUTPUT_NAME%.%OUTPUT_EXT%"
:ROT_EXT_OK

:: ���࠭塞 ��� metadata
set "ROTATION_METADATA=-metadata:s:v:0 rotate=%ROTATION%"
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% ��� ��� ������ ������� ���������� - ⥣ ������ �㤥� ��࠭� � 䠩�� MP4
goto ROTATION_DONE

:: � ��������, �᫨ ������ �� ��।��� ��� �����४⥭
:NO_ROTATION_TAG
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% � metadata �� ������ ⥣ rotate ��� �� �����४⥭.
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% �� ����室����� ������ set ROTATION �ਭ㤨⥫쭮

:ROTATION_DONE







:: === ����: SCALE (������ ���� ��᫥ ROTATION) ===
:: ��ࠡ�⪠ ����⠡�஢���� � ���⮬ Rotation
set "SCALE_EXPR="
:: �᫨ SET SCALE �� ����� - �ய�᪠�� �ନ஢���� scale_expr
if not defined SCALE (
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% ���� �� ������, ����⠡�஢���� �⪫�祭�
    goto SKIP_SCALE
)
set "TARGET_H=%SCALE%"
:: ���뢠�� ������: �� 90/270 ���塞 ��� ����⠡�஢����
if "%ROTATION%"=="90" (
    set "SCALE_EXPR=scale=%SCALE%:-2"
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% ����� ������ �� 90 �ࠤ�ᮢ �� �ᮢ�� ��५�� - ����⠡��㥬 �� �ਭ�
    goto SKIP_SCALE
)
if "%ROTATION%"=="270" (
    set "SCALE_EXPR=scale=%SCALE%:-2"
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% ����� ������ �� 90 �ࠤ�ᮢ ��⨢ �ᮢ�� ��५�� - ����⠡��㥬 �� �ਭ�
    goto SKIP_SCALE
)
:: �� 㬮�砭�� ����⠡��㥬 �� ����
set "SCALE_EXPR=scale=-2:%SCALE%"
:SKIP_SCALE






:: === ����: SKIP_SCALE_FILTER ===
:: �஢��塞, �㦭� �� ����� �ਬ����� scale:
:: - ᮢ������ �� ���� � 楫����,
:: - ��� �� �ਭ㤨⥫쭮�� ������,
:: - ��� �� metadata ������.
:: �᫨ ��� ᮢ������ - �ய�᪠�� scale � -vf, �⮡� �������� ��ᯮ������ ��४���஢��.
set "SRC_H="
set "SKIP_SCALE_FILTER="
:: �᫨ SCALE �� ����� - �ய�᪠�� �஢���
if not defined SCALE goto SKIP_HEIGHT_CHECK

:: ����砥� ��室��� ����� �१ ffprobe, ���� :nk=1 ����� ⥪�� "height="
set "TMP_FILE=%TEMP%\ffprobe_height_%random%%random%.tmp"
"%FFP%" -v error -show_entries stream^=height -of default=nw=1:nk=1 "%FNF%" >"%TMP_FILE%"
if not exist "%TMP_FILE%" (
    >>"%LOG%" echo([WARNING] %DATE% %TIME:~0,8% �� 㤠���� ������� ����� ����� �� 䠩��
    goto SKIP_HEIGHT_CHECK
)
set /p SRC_H= < "%TMP_FILE%"
del "%TMP_FILE%"

:: ����塞 �஡���
set "SRC_H=%SRC_H: =%"

:: �஢��塞, ����� �� ROTATION �� ࠢ�� 0 (�ਭ㤨⥫�� ������)
set "FORCE_ROTATE="
if not defined ROTATION goto CHECK_SRC_HEIGHT
if "%ROTATION%" == "0" goto CHECK_SRC_HEIGHT
set "FORCE_ROTATE=1"

:CHECK_SRC_HEIGHT
:: �஢��塞 ᮢ������� �����
if "%SRC_H%" == "%SCALE%" goto HANDLE_SKIP_SCALE

:: ���� �⫨砥��� - ����⠡��㥬
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% ����� �㤥� ����⠡�஢���. ��室��� ����: %SRC_H%, 楫����: %SCALE%
goto SKIP_HEIGHT_CHECK

:HANDLE_SKIP_SCALE
:: ���� ᮢ������, �஢��塞 ����室������ ������
if defined FORCE_ROTATE goto SKIP_HEIGHT_CHECK
if defined ROTATION_METADATA goto SKIP_HEIGHT_CHECK

:: �� ������, �� ��⠤����� ��� - ����� �ய����� scale
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% ���� %SCALE% 㦥 ᮮ⢥����� 䠩��. ����⠡�஢���� �ய�饭�
set "SKIP_SCALE_FILTER=1"
:SKIP_HEIGHT_CHECK





:: === ���� FPS ===
:: ����: �ਢ��� VFR (variable frame rate) � CFR (constant), �⮡�:
:: - �������� �஡��� � ������묨 �������� (������� �� �� ����),
:: - 㬥����� ࠧ��� 䠩�� (VFR ����� ���� "����"),
:: - ������ ᮢ���⨬���� � �ந��뢠⥫ﬨ � TV.
if defined FPS (
    >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% FPS ����� �ਭ㤨⥫쭮: %FPS%, �ய�᪠�� ��� �����祭��
    goto FPS_DONE
)
:: ����祭�� ����� ���஢ �१ ffprobe
set "TMP_FILE=%TEMP%\ffprobe_fps_%random%%random%.tmp"
"%FFP%" -v error -select_streams v:0 -show_entries stream=r_frame_rate,avg_frame_rate -of default=nw=1 "%FNF%" >"%TMP_FILE%"
if not exist "%TMP_FILE%" (
    >>"%LOG%" echo([WARNING] %DATE% %TIME:~0,8% �� 㤠���� ������� FPS - 䠩� �� ᮧ���
    goto FPS_DONE
)
:: �����祭�� r_frame_rate
for /f "tokens=2 delims==" %%a in ('find "r_frame_rate" "%TMP_FILE%"') do set "R_FPS=%%a"
:: �����祭�� avg_frame_rate
for /f "tokens=2 delims==" %%a in ('find "avg_frame_rate" "%TMP_FILE%"') do set "A_FPS=%%a"
del "%TMP_FILE%"
if not defined R_FPS (
    >>"%LOG%" echo([WARNING] %DATE% %TIME:~0,8% �� 㤠���� ���� r_frame_rate
    goto FPS_DONE
)
if not defined A_FPS (
    >>"%LOG%" echo([WARNING] %DATE% %TIME:~0,8% �� 㤠���� ���� avg_frame_rate
    goto FPS_DONE
)

:: �ࠢ������ ���祭�� ��� ��ப�
if "%R_FPS%" == "%A_FPS%" goto FPS_DONE
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% �����㦥� FPS VFR. ��������� max frame rate �� mediainfo

:: ����砥� Max FPS �� MediaInfo
set "FPS="
set "MAX_FPS="
"%MI%" --Inform="Video;%%FrameRate_Maximum%%" "%FNF%" > "%TMP_FILE%"
if not exist "%TMP_FILE%" (
    >>"%LOG%" echo([WARNING] %DATE% %TIME:~0,8% �� 㤠���� ������� FPS - 䠩� �� ᮧ���
    goto FPS_DONE
)
set /p MAX_FPS= < "%TMP_FILE%"
del "%TMP_FILE%"
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






:: === ����: PROFILE ===
:: ��䨫� ����஢���� (profile:v)
set "USE_PROFILE=main"
if /i "%CODEC%" == "hevc_qsv" goto PROFILE_DONE
if /i "%CODEC%" == "hevc_d3d12va" goto PROFILE_DONE
set "USE_PROFILE=high"
if /i "%CODEC:~0,5%" == "h264_" goto PROFILE_DONE
if /i "%CODEC%" == "libx264" goto PROFILE_DONE
set "USE_PROFILE=main10"
if /i "%PROFILE%" == "main" set "USE_PROFILE=main"
:PROFILE_DONE
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% ��⠭����� ��䨫� ����஢����: %USE_PROFILE%





:: === ����: PIX_FMT_ARGS ===
set "PIX_FMT_ARGS=-pix_fmt p010le"

:: �᫨ �� main10 - �ࠧ� ��⠭�������� 8 ���
if /i not "%USE_PROFILE%" == "main10" goto SET_PIXFMT8

:: �஢��塞, �����ন���� �� ⥪�騩 ����� main10
if /i "%CODEC%" == "libx264" goto NO_MAIN10
if /i "%CODEC:~0,5%" == "h264_" goto NO_MAIN10

:: ��� libx265 �ᯮ��㥬 yuv420p10le
if /i "%CODEC%" == "libx265" set "PIX_FMT_ARGS=-pix_fmt yuv420p10le"
goto DONE_PIXFMT

:NO_MAIN10
>>"%LOG%" echo([WARNING] %DATE% %TIME:~0,8% ����� %CODEC% �� �����ন���� ��䨫� main10. ��ࠬ��� �ந����஢��

:SET_PIXFMT8
set "PIX_FMT_ARGS=-pix_fmt yuv420p"

:DONE_PIXFMT
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% ��� ������ %CODEC% � ��䨫�� %USE_PROFILE% ������塞 䫠�: %PIX_FMT_ARGS%







:: === ����: CRF ===
set "FINAL_CRF="
if not defined CRF goto SKIP_CRF
if /i "%CODEC:~-5%" == "nvenc" set "FINAL_CRF=-cq %CRF%"
if /i "%CODEC:~-3%" == "amf"   set "FINAL_CRF=-quality %CRF%"
if /i "%CODEC:~-3%" == "qsv"   set "FINAL_CRF=-global_quality %CRF%"
if /i "%CODEC%" == "libx265"   set "FINAL_CRF=-crf %CRF%"
if /i "%CODEC%" == "libx264"   set "FINAL_CRF=-crf %CRF%"
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% CRF ��⠭�����: %CRF%
:SKIP_CRF






:: === ����: VF ===
:: ��� ���� ������ ���� ��᫥ ������ ROTATION, SCALE
:: ��ନ�㥬 楯��� �����䨫��஢.
:: ���冷� �����:
:: 1. scale - 㬥��蠥� �� �㦭��� ࠧ���
:: 2. transpose - �����稢��� (㦥 �� ����襬 ����� - ����॥)
:: 3. fps - 䨪��㥬 ����� ���஢
:: ���⮬� ��� ���� - ��᫥ ROTATION, SCALE � FPS.

set "FILTER_LIST="
:: ���砫� scale, �⮡� 㬥����� ࠧ��� ��। �����⮬, �᫨ �� �ய�饭
if not "%SKIP_SCALE_FILTER%" == "1" if defined SCALE_EXPR set "FILTER_LIST=%FILTER_LIST%%SCALE_EXPR%,"

:: ��⥬ rotate
if defined ROTATION_FILTER set "FILTER_LIST=%FILTER_LIST%%ROTATION_FILTER%,"

:: FPS
if defined FPS set "FILTER_LIST=%FILTER_LIST%fps=%FPS%,"

:: ����塞 ���������� �������
if not defined FILTER_LIST goto :SKIP_COMMA_REMOVAL
set "LAST_CHAR=%FILTER_LIST:~-1%"
if not "%LAST_CHAR%" == "," goto :SKIP_COMMA_REMOVAL
set "FILTER_LIST=%FILTER_LIST:~0,-1%"
:SKIP_COMMA_REMOVAL

:: ��ନ�㥬 䫠� -vf
set "VF="
if defined FILTER_LIST set "VF=-vf "%FILTER_LIST%""

:: �����㥬 १����. �������� - � -vf ���� ����窨 !
if defined VF >>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% �����䨫���: %VF%






:: === ����: FINALKEYS ===
:: ���冷� ���祩 �������� ��� �������� ������� (qsv, nvenc, amf).
:: ������� �ࠩ���� ��������� ��ࠬ����, �᫨ ��� ���� �� � �ࠢ��쭮� ��᫥����⥫쭮��.
:: ���⮬� ᭠砫�: �����, ��䨫�, preset, ��⮬ vf, pix_fmt, crf � �.�.
:: ���冷� ���祩 ������ ���� ⠪��:
:: -hide_banner -c:v codec [-profile:v] [-preset] [-vf] [-pix_fmt] [-crf] [-tune] [-level]
::  [-r FPS] [-metadata rotate] -c:a -c:s [-metadata lng]
set "FINAL_KEYS=-hide_banner"

:: ����� � ��䨫�
set "FINAL_KEYS=%FINAL_KEYS% -c:v %CODEC% -profile:v %USE_PROFILE%"

:: Preset � quality
if not defined PRESET goto SKIP_PRESET
if /i "%CODEC:~-5%" == "nvenc" set "FINAL_KEYS=%FINAL_KEYS% -preset %PRESET%"
if /i "%CODEC:~-3%" == "amf"   set "FINAL_KEYS=%FINAL_KEYS% -quality %PRESET%"
if /i "%CODEC:~-3%" == "qsv"   set "FINAL_KEYS=%FINAL_KEYS% -preset %PRESET%"
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% ��⠭����� preset %PRESET%
:SKIP_PRESET

:: �����䨫��� -vf
if defined VF set "FINAL_KEYS=%FINAL_KEYS% %VF%"

:: ��ଠ� ���ᥫ�� (8 bit yuv420p ��� 10 bit yuv420p10le)
if defined PIX_FMT_ARGS set "FINAL_KEYS=%FINAL_KEYS% %PIX_FMT_ARGS%"

:: CRF/CQ
if defined FINAL_CRF set "FINAL_KEYS=%FINAL_KEYS% %FINAL_CRF%"

:: Tune � Level
if /i "%CODEC%" == "libx264" set "FINAL_KEYS=%FINAL_KEYS% -tune film"
if /i "%CODEC:~0,5%" == "h264_" set "FINAL_KEYS=%FINAL_KEYS% -level 4.0"

:: FPS
:: FPS ��⠭���������� �१ -vf fps=%FPS%, ���⮬� -r �� �㦥�
:: if defined FPS set "FINAL_KEYS=%FINAL_KEYS% -r %FPS%"

:: Metadata - Rotate �᫨ �� �����稢��� ����� ��-�� �������ন������� �����⭮�� ������
if defined ROTATION_METADATA set "FINAL_KEYS=%FINAL_KEYS% %ROTATION_METADATA%"

:: �㤨� � ������
set "FINAL_KEYS=%FINAL_KEYS% %AUDIO_ARGS% -c:s copy"

:: ��⠭�������� �� �㤨� � ����஢ � "rus". ��� ����� - �� �ண���: 
:: ffmpeg ������ �� �ਢ� � MKV, � � MP4 ����� ������� und/eng.
:: ��� ����� �㤥� ��⠭����� ����� �१ mkvpropedit.
:: �� �� ������� ��⠤��� ��� full-range MKV - ffmpeg �� 㬥��.
set "FINAL_KEYS=%FINAL_KEYS% -metadata language=rus -metadata:s:a:0 language=rus -metadata:s:s:0 language=rus"
:: ����塞 ���� ⥣� �����: ffmpeg ������� BPS, ࠧ��� � ���⥫쭮��� �� ��室����,
:: ���� �� ��४���஢�� - ��� �⠭������ �����묨.
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:v BPS= -metadata:s:v BPS-eng= -metadata:s:v NUMBER_OF_BYTES= -metadata:s:v NUMBER_OF_BYTES-eng= -metadata:s:v DURATION-eng="
:: ����塞 ⥣� �㤨� ������ �� ��४���஢��: �� -c:a copy ��� ����,
:: � �� ��४���஢�� ffmpeg �� �������� �� - ������� ����� ���祭��.
if "%AUDIO_ARGS%" == "-c:a copy" goto SKIP_CLEAN_AUDIO
set "FINAL_KEYS=%FINAL_KEYS% -metadata:s:a BPS= -metadata:s:a BPS-eng= -metadata:s:a NUMBER_OF_BYTES= -metadata:s:a NUMBER_OF_BYTES-eng= -metadata:s:a DURATION-eng="
:SKIP_CLEAN_AUDIO






:: === ����: FFMPEG ===
set "CMD_LINE="%FFM%" -i "%FNF%" %FINAL_KEYS% "%OUTPUT%""
>>"%LOG%" echo([CMD] %DATE% %TIME:~0,8% ��ப� ����஢����: %CMD_LINE%
:: � CMD_LINE 㦥 ���� ����窨 - ����� ����� "%CMD_LINE%"
:: FFMPEG ���� ��� � stderr, � �� � stdout - ���⮬� 2>"%FFMPEG_LOG%"
%CMD_LINE% 2>"%FFMPEG_LOG%"

:: ����� 㦥 ⮫쪮 MKV - ���� �᫨ OUTEXT �� MP4, ��� �� ��� 㦥 �ਭ㤨⥫쭮 ᬥ����.
:: ��� Full-range ������塞 梥⮢� ��⠤���� + ���塞 �� �� ���᪨�
:: ��⠫�� ��஦�� (�㤨�, ������) 㦥 ����稫� language=rus �१ ffmpeg -metadata (�. ���)
if not defined COLOR_RANGE goto SKIPMKVPROP
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% Full color range: ������塞 � MKV �������⥫�� ⥣� c ������� mkvpropedit
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% � MKV ���塞 �� �������஦�� �� ���᪨�
"%MKVP%" "%OUTPUT%" --edit track:v1 --set "language=rus" --set "colour-range=1" --set "color-matrix-coefficients=1">nul
goto DONEMKVPROP
:SKIPMKVPROP
:: �᫨ �� full-range, �� 䠩� - MKV: ⮫쪮 ���塞 �� �����
:: ��⠫쭮� (�㤨�, ������) 㦥 ����祭� ��� rus �१ ffmpeg
if not "%OUTPUT_EXT%" == "mkv" goto DONEMKVPROP
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% � MKV ���塞 �� �������஦�� �� ���᪨�
"%MKVP%" "%OUTPUT%" --edit track:v1 --set "language=rus">nul
:DONEMKVPROP




:: === ����: ��������� ����� ===
:: FFmpeg ���� ��� � UTF-8, � cmd - � OEM (cp866). ���⮬�:
:: 1. FFmpeg ��� - �⤥�쭮, � UTF-8 (��� ��ᬮ�� � ।�����).
:: 2. �᭮���� ��� - � OEM, ��⮬ ������������ � UTF-8 ��� ��ᬮ��.
:: �� �������� �᪠�� �訡�� � FFmpeg-���� - findstr ࠡ�⠥� ⮫쪮 � OEM.

:: �६���� ��������㥬 UTF8-��� FFmpeg � OEM ��� ���᪠ �訡�� �१ findstr
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
findstr /i "error failed" "%TMPFLOEM%">nul
if %ERRORLEVEL% EQU 0 (
    echo(FFmpeg �����訫�� � �訡��� - �. "%FFMPEG_LOG_NAME%"
    echo(
    >>"%LOG%" echo([ERROR] %DATE% %TIME:~0,8% FFmpeg �����訫�� � �訡��� - �. "%FFMPEG_LOG_NAME%"
)
del "%TMPFLOEM%"
popd
del "%VT%"

:: �����訫� ��ࠡ��� 䠩��
echo(%DATE% %TIME:~0,8% ��ࠡ�⪠ "%FNWE%" �����襭�.
echo(������ "%OUTPUT_NAME%.%OUTPUT_EXT%".
echo(C�. ���� � ����� "%OUTPUT_DIR%logs".
echo(---
>>"%LOG%" echo([INFO] %DATE% %TIME:~0,8% ������ "%OUTPUT_NAME%.%OUTPUT_EXT%"
>>"%LOG%" echo(---

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