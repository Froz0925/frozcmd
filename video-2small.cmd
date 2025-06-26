@echo off
set "VERS=Froz video recode script v27.06.2025"
:: ���� �ਯ�: ��४���஢���� �����䠩��� � ⥫�䮭��/�⮠����⮢
:: � 㬥��襭�� ࠧ��� ��� �������娢� ��� ����⢥���� ���� ����⢠.


:: === ����: ����ன�� ===

:: ����� ���� ����� (��樮���쭮). �ਬ���: 720, 480
:: �᫨ �� ������ - ������� ��� ���������.
:: ��� �ᮡ��� ��᫠ �������� 1080 �� 720 - ࠧ��� 㢥��稢����� ������⥫쭮
set "SCALE="

:: ������ ����� (Rotation tag).
:: �����: ������� ������ hevc_qsv hevc_d3d12va h264_qsv h264_d3d12va
:: �� ������ন���� ������ - ���� �㤥� �ந����஢��!.
:: ����� hevc_amf ����� ����� �訡�� � �����⮬!
:: �������� ���祭��:
::    90 - ������ �� �ᮢ�� ��५�� �� 90 �ࠤ�ᮢ
::    180 - ������ �� 180 �ࠤ�ᮢ
::    270 - ������ ��⨢ �ᮢ�� ��५�� �� 90 �ࠤ�ᮢ
::    �᫨ �� ������ - ������ ������� �� 䠩�� (rotation tag)
set "ROTATION="

:: ����� � ��ࠬ���� ����஢����:
:: HEVC (H.265) ������:
::    hevc_nvenc   - NVIDIA GPU (४�����㥬�, �ॡ���� Nvidia GeForce GTX 950 � ��� � �ࠩ��� 570+)
::    hevc_amf     - AMD GPU
::    hevc_qsv     - Intel Quick Sync Video
::    hevc_d3d12va - Windows Direct 12 (DXVA2), �����⭠� �����প�
::    libx265      - software ����஢���� HEVC (�祭� ��������)
:: H.264 ������:
::    h264_nvenc   - NVIDIA GPU (४�����㥬�)
::    h264_amf     - AMD GPU
::    h264_qsv     - Intel Quick Sync Video
::    libx264      - software ����஢���� H.264 (��������)
set "CODEC=hevc_nvenc"

:: Preset ��� hevc_nvenc (᪮����/����⢮). �������� ���祭��: p1-p7 (᪮����-����⢮).
:: �᫨ �� ������ - �� 㬮�砭�� hevc_nvenc �롨ࠥ� p4 (~CRF20, �� 720p ~2,5 ����/�)
set "PRESET="

:: ��䨫� ����஢����.
::    ��� HEVC: main10 - 10 bit, main - 8 bit.
::    ��� H.264: ��⮬���᪨ �롨ࠥ��� high, ������ᨬ� �� 㪠������� �����.
:: �᫨ �� ������ - �롨ࠥ� �����.
:: main10 �����ন����: hevc_nvenc, hevc_amf, libx265
:: main10 ����� �� ���ந��������� � ����� �ந��뢠⥫�� � ���ன�⢠�!
set "PROFILE=main10"

:: CRF - "�஢��� ����⢠". �᫨ �� ������ - �롨ࠥ� �����.
:: ��������㥬� ���祭�� �� �뢠��� ����⢠ � ࠧ��� 䠩��: 20-24
:: hevc_nvenc ��⮬�⮬ �⠢�� ��ଠ��� �஢���, �ਬ�୮ ࠢ�� CRF20.
:: ��� libx265/264 ���� �ਭ㤨⥫쭮 �⠢��� CRF20 ���� �� �롥�� ������ ����⢮ CRF28
:: CRF20 � 720p �� ~2,5 ����/�
set "CRF="

:: �㤨�-����ன�� - �� 㬮�砭�� ����஢���� �㤨���஦��
:: ����� �ᯮ�짮���� "-c:a libopus -b:a 128k" ��� 㬥��襭�� ࠧ���
set "AUDIO_ARGS=-c:a copy"

:: ������ - ��⠭����� � 1 �� ।��� ��砩 �᫨ �室��� ����� -
:: Full Range JPEG, �� �� YUVJ420P.
set "FORCE_FULL_RANGE="

:: FPS - ��⠭���� 楫���� ����� ���஢ (����易⥫쭮)
:: �ਬ���: 24, 25, 30, 50, 60, 24000/1001 (~23.976), 30000/1001 (~29.97) � �.�.
:: �᫨ �� ������ - ���� ���஢ ������� �� ��室���� (FPS CFR ��� VFR).
:: �ਬ��: set "FPS=30000/1001"
set "FPS="

:: �����⨬� ���祭��: mkv (㭨���ᠫ쭥�) ��� mp4.
:: ��� �������� ������� H.264 - ���� ����� mp4.
set "OUTPUT_EXT=mkv"

:: ���⠢�� � ��室���� ����� 䠩�� (����� �������� ��� ��⠢��� ���⮩)
set "NAME_APPEND=_sm"

:: === ����砭�� ����� ����஥� ===





:: === ����: �஢�ન ===
echo.
echo.%VERS%
echo.------------------------------------
:: �஢�ઠ ������ �室��� 䠩���
if "%~1" == "" (
    echo.�ᯮ�짮�����: ��।������ SET � ��砫� �ਯ�.
    echo.��⥬ ����ﭨ� ��� ��⠢�� �����䠩�� �� ��� 䠩�.
    echo.��室��.
    pause & exit /b
)
:: �஢�ઠ ������ �⨫��
set "FFM=%~dp0bin\ffmpeg.exe"
set "FFP=%~dp0bin\ffprobe.exe"
set "MI=%~dp0bin\mediainfo.exe"
set "MKVP=%~dp0bin\mkvpropedit.exe"
if not exist "%FFM%" echo.%FFM% �� ������, ��室��.& pause & exit /b
if not exist "%FFP%" echo.%FFP% �� ������, ��室��.& pause & exit /b
if not exist "%MI%" echo.%MI% �� ������, ��室��.& pause & exit /b
if not exist "%MKVP%" echo.%MKVP% �� ������, ��室��.& pause & exit /b





:: === ����: ���� ===
:FILE_LOOP
:: �����뢠�� ��� 䠩�� � ��६���� �⮡� %1 �� ᫮������ � �����
set "FNF=%~1"
set "FNN=%~n1"
set "FNWE=%~nx1"

:: �᫨ ����� ��� 䠩��� - ��室��
if "%FNF%" == "" goto FILE_LOOP_END

:: �६����� ��� OEM-����
set "td=%date:~0,2%"
set "tm=%date:~3,2%"
set "ty=%date:~6,4%"
set "thh=%time:~0,2%"
if not "%thh:~0,1%"==" " goto thh_ok
set "thh=0%thh:~1,1%"
:thh_ok
set "tmm=%time:~3,2%"
set "tss=%time:~6,2%"
set "TYMDHMS=%ty%-%tm%-%td%_%thh%-%tmm%-%tss%"

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
echo.%OUTPUT_NAME% 㦥 �������, �ய�᪠��.
goto NEXT
:DONE_SIZE_CHK
title ��ࠡ�⪠ %FNWE%...
echo.%DATE% %TIME:~0,8% ���� ��ࠡ�⪠ %FNWE%...
echo.[INFO] %DATE% %TIME:~0,8% ���� ��ࠡ�⪠ %FNWE%...>"%LOG%"








:: === ����: ����� ===
:: ����砥� ���⥫쭮��� �����. ���� :nk=1 ����� ⥪�� "duration="
set "TMP_FILE=%TEMP%\ffprobe_time.tmp"
"%FFP%" -v error -show_entries format=duration -of default=nw=1:nk=1 "%FNF%" > "%TMP_FILE%" 2>nul
set /p LENGTH_SECONDS= <"%TMP_FILE%"
del "%TMP_FILE%"
if not defined LENGTH_SECONDS (
    echo �� 㤠���� ������� ���⥫쭮��� �����.
    goto DONE_LENGTH
)

:: ��⠢�塞 ⮫쪮 楫� ᥪ㭤�
for /f "tokens=1 delims=." %%a in ("%LENGTH_SECONDS%") do set "LENGTH_SECONDS=%%a"

:: ������塞 +1, �⮡� ���㣫��� �����
set /a LENGTH_SECONDS+=1

:: ������뢠�� �६� ����஢���� ��室� �� X.X ᥪ㭤 �� ᥪ㭤� ����� ��� ������� �� CPU i3-2120:
:: 0.3 - *nvenc, libx264. 5.0 - libx265
:: ��� ��⠢�� � ���� - 㬭����� �६� �� 10
if /i "%CODEC:~5%" == "nvenc" set /a "ENCODE_SECONDS=(LENGTH_SECONDS * 3) / 10"
if /i "%CODEC%" == "libx265" set /a "ENCODE_SECONDS=(LENGTH_SECONDS * 50) / 10"

:: ��ॢ���� � �ଠ� ������:ᥪ㭤�
set /a "MINUTES=ENCODE_SECONDS / 60"
set /a "SECONDS=ENCODE_SECONDS %% 60"
if %SECONDS% LSS 10 set "SECONDS=0%SECONDS%"
echo.�ਬ�୮� �६� ����஢����: %MINUTES% ����� %SECONDS% ᥪ㭤.
:DONE_LENGTH






:: === ����: COLOR RANGE ===
set "PIX_FMT="
:: �᫨ ����� Force full range
set "COLOR_RANGE="
if defined FORCE_FULL_RANGE (
    set "COLOR_RANGE=1"
    echo.[INFO] ����� Force color range>>"%LOG%"
    goto COLOR_RANGE_DONE
)
:: ��।������ full range �१ ffprobe. ���� :nk=1 ����� ⥪�� "pix_fmt="
set "TMP_FILE=%TEMP%\ffprobe_pix_fmt.tmp"
"%FFP%" -v error -select_streams v:0 -show_entries stream=pix_fmt -of default=nw=1:nk=1 "%FNF%" > "%TMP_FILE%" 2>nul
if not exist "%TMP_FILE%" (
    echo.[ERROR] �� ����稫��� ᮧ���� �६���� 䠩� %TMP_FILE%>>"%LOG%"
    goto COLOR_RANGE_DONE
)
set /p PIX_FMT= <"%TMP_FILE%"
del "%TMP_FILE%"
if not defined PIX_FMT (
    echo.[ERROR] FFProbe �� ᬮ� ��।����� �ଠ� ���ᥫ��>>"%LOG%"
    goto COLOR_RANGE_DONE
)
echo.[INFO] ��ଠ� ���ᥫ�� ��室����: %PIX_FMT%>>"%LOG%"
for /f "tokens=1" %%a in ("%PIX_FMT%") do set "PIX_FMT=%%a"
:: ��⮮�।������ full range �� pix_fmt
if /i "%PIX_FMT%" == "yuvj420p" (
    set "COLOR_RANGE=1"
)

:: �᫨ OUTPUT_EXT = mp4 - ���塞 �� mkv
if not "%OUTPUT_EXT%" == "mp4" goto COLOR_RANGE_DONE
echo.[INFO] ��� ����� metadata full color � ������� mkvpropedit - ���塞 ���७�� c mp4 �� mkv>>"%LOG%"
set "OUTPUT_EXT=mkv"
set "OUTPUT=%OUTPUT_DIR%%OUTPUT_NAME%.%OUTPUT_EXT%"
:COLOR_RANGE_DONE






:: === ����: CURRENT SIZE ===
:: ����砥� ��室�� ࠧ���� ����� ��� ������ � ����⠡�஢���� �१ ffprobe
:: �ᯮ��㥬 �६���� 䠩�, ⠪ ��� ����� �뢮� ffprobe ����� ᮤ�ঠ��:
::     - �஡��� (���ਬ��, "1920 1080")
::     - ᯥ樠��� ᨬ���� (���ਬ��, escape-ᨬ����, �������)
::     - ����� ��ப� ��� �訡��
:: �� �ᯮ��㥬 for /f. �ਬ���, ����� ᫮���� 横� for /f:
::     - "1920 1080" > �� ��ଠ����樨 �⠭������ "19201080" (����୮)
::     - "error" > �㤥� ������� ��� �ਭ�/����
:: ���⮬� ������᭥� ���� �१ set /p < file
set "CURRENT_DIM="
set "TMP_FILE=%TEMP%\video_info.tmp"
"%FFP%" -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "%FNF%" > "%TMP_FILE%" 2>nul
if not exist "%TMP_FILE%" goto SKIP_CURRENT_DIM
:: ��������� ����� �������� ��ப� (goto '��室' �㦥� ��� ���뢠��� 横��)
for /f "tokens=1,2 delims=," %%a in ('type "%TMP_FILE%"') do (
    set "CURRENT_W=%%a"
    set "CURRENT_H=%%b"
)
del "%TMP_FILE%"
if not defined CURRENT_W (
    echo.������: FFProbe �� ᬮ� ��।����� �ਭ�/�����>>"%LOG%"
    goto SKIP_CURRENT_DIM
)
echo.[INFO] ����襭�� ��室����: %CURRENT_W%x%CURRENT_H%>>"%LOG%"
:SKIP_CURRENT_DIM




:: === ����: ROTATION ===
:: ���� ������ ���� �� ����� SCALE
set "ROTATION_FILTER="
set "ROTATION_METADATA="

:: �᫨ ROTATION �� ����� - ��⠥��� ������� ⥣ Rotate �� 䠩��
if not defined ROTATION goto NO_USER_ROTATION

:: �᫨ ������ ���祭�� �⫨筮� �� 0 - �ᯮ��㥬 ���
echo.[INFO] ����� USER ROTATION=%ROTATION%>>"%LOG%"
goto APPLY_ROTATION

:NO_USER_ROTATION
set "EXT=%~x1"
if /i "%EXT%" == ".mp4" goto GET_ROTATE
if /i "%EXT%" == ".mov" goto GET_ROTATE
echo.[WARNING] ��ଠ� %EXT% �� �����ন���� ⥣ Rotate - �����祭�� �ய�饭�.>>"%LOG%"
echo.[WARNING] �᫨ ����� ������� - �ਭ㤨⥫쭮 ������ set ROTATION.>>"%LOG%"
goto NO_ROTATION_TAG

:GET_ROTATE
set "ROTATION_TAG="
set "TMP_FILE=%TEMP%\ffprobe_rotation.tmp"
"%FFP%" -v error -show_entries stream_tags=rotate -of default=nw=1:nk=1 "%FNF%" > "%TMP_FILE%" 2>nul
if not exist "%TMP_FILE%" goto NO_ROTATION_TAG
set /p ROTATION_TAG= < "%TMP_FILE%"
del "%TMP_FILE%"
if not defined ROTATION_TAG goto NO_ROTATION_TAG

:: ����塞 �஡���
set "ROTATION_TAG=%ROTATION_TAG: =%"
echo.[INFO] � metadata ������ ⥣ Rotate: "%ROTATION_TAG%">>"%LOG%"

:: ��⠭�������� ROTATION ⮫쪮 �᫨ ��� ��� �� ������
set "ROTATION=%ROTATION_TAG%"

:: �஢��塞, �����ন���� �� ����� ������
:APPLY_ROTATION
set "UNSUPPORTED_ROTATION_CODECS= hevc_qsv hevc_d3d12va h264_qsv h264_d3d12va "
echo.%UNSUPPORTED_ROTATION_CODECS% | findstr /i /c:" %CODEC% " >nul && goto SAVE_ROTATION_METADATA

:SET_TRANSPOSE
:: ��ନ�㥬 䨫��� ������
if "%ROTATION%" == "90" (
    set "ROTATION_FILTER=transpose=1"
    echo.[INFO] �ਬ��� ������ �� 90 �ࠤ�ᮢ �� �ᮢ�� ��५��>>"%LOG%"
    goto ROTATION_DONE
)
if "%ROTATION%" == "180" (
    set "ROTATION_FILTER=transpose=2,transpose=2"
    echo.[INFO] �ਬ��� ������ �� 180 �ࠤ�ᮢ>>"%LOG%"
    goto ROTATION_DONE
)
if "%ROTATION%" == "270" (
    set "ROTATION_FILTER=transpose=2"
    echo.[INFO] �ਬ��� ������ �� 90 �ࠤ�ᮢ ��⨢ �ᮢ�� ��५��>>"%LOG%"
    goto ROTATION_DONE
)

:: � ��������, �᫨ ������ ������� ����������, �� ����� ��࠭��� ��� metadata
:SAVE_ROTATION_METADATA

:: �᫨ ࠭�� �� ��⠭����� full color range � ����� ����� �� 㬥�� ������ ����� - ����� �஡����:
:: MP4 �㦥� ��� ����� ⥣� Rotate, MKV �㦥� ��� ����� metadata color range. ���⮬� �訡�� � ��室.
if defined COLOR_RANGE (
    echo.[ERROR] ��� %CODEC% �� �������� ᮢ������ ������ ⥣� Rotate � ⥣�� Color Range � ����� ���⥩���.
    echo.[ERROR] ��� ��� ⥣ Color Range ������, � �������� ����� ������� - ������� �����.>>"%LOG%"
    echo.��������: ������� Full Color Range � ⥣ Rotate.
    echo.��� %CODEC% �� �������� ᮢ������ ������ ⥣� Rotate � ⥣�� Color Range � ����� ���⥩���.
    echo.��� ��� ⥣ Color Range ������, � �������� ����� ������� - ������� �����. �ய�᪠�� 䠩�.
    goto NEXT
)

:: �᫨ OUTPUT_EXT = mkv - ���塞 �� mp4
if not "%OUTPUT_EXT%" == "mkv" goto ROT_EXT_OK
echo.[INFO] ���塞 ���७�� �� mp4 ��� ����� ⥣� Rotate>>"%LOG%"
set "OUTPUT_EXT=mp4"
set "OUTPUT=%OUTPUT_DIR%%OUTPUT_NAME%.%OUTPUT_EXT%"
:ROT_EXT_OK

:: ���࠭塞 ��� metadata
set "ROTATION_METADATA=-metadata:s:v:0 rotate=%ROTATION%"
echo.[INFO] ��� ��� ������ ������� ���������� - ⥣ ������ �㤥� ��࠭� � 䠩�� MP4>>"%LOG%"
goto ROTATION_DONE

:: � ��������, �᫨ ������ �� ��।��� ��� �����४⥭
:NO_ROTATION_TAG
echo.[INFO] � metadata �� ������ ⥣ rotate ��� �� �����४⥭. �� ����室����� ������ set ROTATION �ਭ㤨⥫쭮>>"%LOG%"

:ROTATION_DONE







:: === ����: SCALE (������ ���� ��᫥ ROTATION) ===
:: �� ���饥 - ����� ��३� �� ����� ᮢ६���� zscale, �� �� ���� �� �� ��� ᡮઠ�:
:: zscale=width=1280:height=720.
:: ��� zscale=width='if(lte(iw*9/16,ih*4/3),1280,-2)':height=720
:: �� ��� ����� ���� �஡���� � �࠭�஢����� � cmd
:: ������ ��ப� -vf ����⥫쭮 ⠪��:
:: zscale=width=1280:height=720:flags=bitexact+full_chroma_int:rangein=limited:range=full

:: ��ࠡ�⪠ ����⠡�஢���� ����� (Scale) � ���⮬ Rotation
set "SCALE_EXPR="
:: �᫨ SET SCALE �� ����� - �ய�᪠�� �ନ஢���� scale_expr
if not defined SCALE (
    echo.[INFO] ���� �� ������, ����⠡�஢���� �⪫�祭�>>"%LOG%"
    goto SKIP_SCALE
)
set "TARGET_H=%SCALE%"
:: ���뢠�� ������: �� 90/270 ���塞 ��� ����⠡�஢����
if "%ROTATION%"=="90" (
    set "SCALE_EXPR=scale=%SCALE%:-2"
    echo.[INFO] ����� ������ �� 90 �ࠤ�ᮢ �� �ᮢ�� ��५�� - ����⠡��㥬 �� �ਭ�>>"%LOG%"
    goto SKIP_SCALE
)
if "%ROTATION%"=="270" (
    set "SCALE_EXPR=scale=%SCALE%:-2"
    echo.[INFO] ����� ������ �� 90 �ࠤ�ᮢ ��⨢ �ᮢ�� ��५�� - ����⠡��㥬 �� �ਭ�>>"%LOG%"
    goto SKIP_SCALE
)
:: �� 㬮�砭�� ����⠡��㥬 �� ����
set "SCALE_EXPR=scale=-2:%SCALE%"
:SKIP_SCALE






:: === HEIGHT_CHECK ===
:: �஢�ઠ ᮢ������� ����� � user set SCALE �⮡� �� ������ ��४���஢���� 1�1 � -vf
set "SRC_H="
set "SKIP_SCALE_FILTER="
:: �᫨ SCALE �� ����� - �ய�᪠�� �஢���
if not defined SCALE goto SKIP_HEIGHT_CHECK

:: ����砥� ��室��� ����� �१ ffprobe, ���� :nk=1 ����� ⥪�� "height="
set "TMP_FILE=%TEMP%\ffprobe_height.tmp"
"%FFP%" -v error -show_entries stream^=height -of default=nw=1:nk=1 "%FNF%" > "%TMP_FILE%" 2>nul
if not exist "%TMP_FILE%" (
    echo.[WARNING] �� 㤠���� ������� ����� ����� �� 䠩��>>"%LOG%"
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
echo.[INFO] ����� �㤥� ����⠡�஢���. ��室��� ����: %SRC_H%, 楫����: %SCALE%>>"%LOG%"
goto SKIP_HEIGHT_CHECK

:HANDLE_SKIP_SCALE
:: ���� ᮢ������, �஢��塞 ����室������ ������
if defined FORCE_ROTATE goto SKIP_HEIGHT_CHECK
if defined ROTATION_METADATA goto SKIP_HEIGHT_CHECK

:: �� ������, �� ��⠤����� ��� - ����� �ய����� scale
echo.[INFO] ���� %SCALE% 㦥 ᮮ⢥����� 䠩��. ����⠡�஢���� �ய�饭�>>"%LOG%"
set "SKIP_SCALE_FILTER=1"
:SKIP_HEIGHT_CHECK





:: === ���� FPS ===
if defined FPS (
    echo.[INFO] FPS ����� �ਭ㤨⥫쭮: %FPS%, �ய�᪠�� ��� �����祭��.>>"%LOG%"
    goto FPS_DONE
)
:: ����祭�� ����� ���஢ �१ ffprobe
set "TMP_FILE=%TEMP%\ffprobe_fps.tmp"
"%FFP%" -v error -select_streams v:0 -show_entries stream=r_frame_rate,avg_frame_rate -of default=nw=1 "%FNF%" > "%TMP_FILE%" 2>nul
if not exist "%TMP_FILE%" (
    echo.[WARNING] �� 㤠���� ������� FPS - 䠩� �� ᮧ���>>"%LOG%"
    goto FPS_DONE
)
:: �����祭�� r_frame_rate
for /f "tokens=2 delims==" %%a in ('find "r_frame_rate" "%TMP_FILE%"') do set "R_FPS=%%a"
:: �����祭�� avg_frame_rate
for /f "tokens=2 delims==" %%a in ('find "avg_frame_rate" "%TMP_FILE%"') do set "A_FPS=%%a"
del "%TMP_FILE%"
if not defined R_FPS (
    echo.[WARNING] �� 㤠���� ���� r_frame_rate>>"%LOG%"
    goto FPS_DONE
)
if not defined A_FPS (
    echo.[WARNING] �� 㤠���� ���� avg_frame_rate>>"%LOG%"
    goto FPS_DONE
)

:: �ࠢ������ ���祭�� ��� ��ப�
if "%R_FPS%" == "%A_FPS%" goto FPS_DONE
echo.[INFO] �����㦥� FPS VFR. ��������� max frame rate �� mediainfo>>"%LOG%"

:: ����砥� Max FPS �� MediaInfo
set "FPS="
set "MAX_FPS="
"%MI%" --Inform="Video;%%FrameRate_Maximum%%" "%FNF%" > "%TMP_FILE%" 2>nul
if not exist "%TMP_FILE%" (
    echo.[WARNING] �� 㤠���� ������� FPS - 䠩� �� ᮧ���>>"%LOG%"
    goto FPS_DONE
)
set /p MAX_FPS= < "%TMP_FILE%"
del "%TMP_FILE%"
if not defined MAX_FPS (
    echo.[WARNING] �� 㤠���� ������� max frame rate �� mediainfo>>"%LOG%"
    goto FPS_DONE
)

echo.[INFO] �����祭 max frame rate: %MAX_FPS%>>"%LOG%"

:: ��⠢�塞 ⮫쪮 楫� ���祭�� FPS
for /f "tokens=1 delims=." %%m in ("%MAX_FPS%") do set "MAX_FPS=%%m"

:: �ਭ㤨⥫쭮 ��⠭�������� ������訩 FPS CFR
set "FPS=25"
if %MAX_FPS% GTR 25 set "FPS=30"
:: 35 - ᯥ樠�쭮 ��� 䠩��� � VFR ~31.4 fps
if %MAX_FPS% GTR 35 set "FPS=50"
if %MAX_FPS% GTR 50 set "FPS=60"
echo.[INFO] �� ���������� ��⠭����� FPS CFR: %FPS%>>"%LOG%"
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
echo.[INFO] ��⠭����� ��䨫� ����஢����: %USE_PROFILE%>>"%LOG%"





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
echo.[WARNING] ����� %CODEC% �� �����ন���� ��䨫� main10. ��ࠬ��� �ந����஢��.>>"%LOG%"

:SET_PIXFMT8
set "PIX_FMT_ARGS=-pix_fmt yuv420p"

:DONE_PIXFMT
echo.[INFO] ��� ������ %CODEC% � ��䨫�� %USE_PROFILE% ������塞 䫠�: %PIX_FMT_ARGS%>>"%LOG%"







:: === ����: CRF ===
set "FINAL_CRF="
if not defined CRF goto SKIP_CRF
if /i "%CODEC%" == "hevc_nvenc" set "FINAL_CRF=-cq %CRF%"
if /i "%CODEC%" == "hevc_amf"   set "FINAL_CRF=-quality %CRF%"
if /i "%CODEC%" == "hevc_qsv"   set "FINAL_CRF=-global_quality %CRF%"
if /i "%CODEC%" == "libx265"    set "FINAL_CRF=-crf %CRF%"
if /i "%CODEC%" == "h264_nvenc" set "FINAL_CRF=-cq %CRF%"
if /i "%CODEC%" == "h264_amf"   set "FINAL_CRF=-quality %CRF%"
if /i "%CODEC%" == "h264_qsv"   set "FINAL_CRF=-global_quality %CRF%"
if /i "%CODEC%" == "libx264"    set "FINAL_CRF=-crf %CRF%"
echo.[INFO] CRF ��⠭�����: %CRF%>>"%LOG%"
:SKIP_CRF






:: === ����: VF ===
:: ��� ���� ������ ���� ��᫥ ������ ROTATION, SCALE
set "FILTER_LIST="
:: ���砫� scale, �⮡� 㬥����� ࠧ��� ��। �����⮬, �᫨ �� �ய�饭
if not "%SKIP_SCALE_FILTER%" == "1" if defined SCALE_EXPR set "FILTER_LIST=%FILTER_LIST%%SCALE_EXPR%,"

:: ��⥬ rotate
if defined ROTATION_FILTER set "FILTER_LIST=%FILTER_LIST%%ROTATION_FILTER%,"

:: FPS
if defined FPS set "FILTER_LIST=%FILTER_LIST%fps=%FPS%,"

:: ����塞 ���������� �������
if defined FILTER_LIST if "%FILTER_LIST:~-1%" == "," set "FILTER_LIST=%FILTER_LIST:~0,-1%"

:: ��ନ�㥬 䫠� -vf
set "VF="
if defined FILTER_LIST set "VF=-vf "%FILTER_LIST%""

:: �����㥬 १����. �������� - � -vf ���� ����窨 !
if defined VF echo.[INFO] �����䨫���: %VF%>>"%LOG%"





:: === ����: FINALKEYS ===
:: ���冷� ���祩 ������ ���� ⠪��, �ᮡ���� ��� �������� �������:
:: -hide_banner -c:v codec [-profile:v] [-preset] [-vf] [-pix_fmt] [-crf] [-tune] [-level] [-r FPS] [-metadata rotate] -c:a -c:s [-metadata lng]
set "FINAL_KEYS=-hide_banner"

:: ����� � ��䨫�
set "FINAL_KEYS=%FINAL_KEYS% -c:v %CODEC% -profile:v %USE_PROFILE%"

:: Preset � quality
if not defined PRESET goto SKIP_PRESET
if /i "%CODEC%" == "hevc_nvenc" set "FINAL_KEYS=%FINAL_KEYS% -preset %PRESET%"
if /i "%CODEC%" == "h264_nvenc" set "FINAL_KEYS=%FINAL_KEYS% -preset %PRESET%"
if /i "%CODEC%" == "hevc_amf"   set "FINAL_KEYS=%FINAL_KEYS% -quality %PRESET%"
if /i "%CODEC%" == "h264_amf"   set "FINAL_KEYS=%FINAL_KEYS% -quality %PRESET%"
if /i "%CODEC%" == "hevc_qsv"   set "FINAL_KEYS=%FINAL_KEYS% -preset %PRESET%"
if /i "%CODEC%" == "h264_qsv"   set "FINAL_KEYS=%FINAL_KEYS% -preset %PRESET%"
echo.[INFO] ��⠭����� preset %PRESET%>>"%LOG%"
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
rem if defined FPS set "FINAL_KEYS=%FINAL_KEYS% -r %FPS%"

:: Metadata (⥣ Rotate �᫨ �� �����稢��� ����� ��-�� �������ন������� �����⭮�� ������)
if defined ROTATION_METADATA set "FINAL_KEYS=%FINAL_KEYS% %ROTATION_METADATA%"

:: �㤨� � ������
set "FINAL_KEYS=%FINAL_KEYS% %AUDIO_ARGS% -c:s copy"

:: ���塞 �� ��஦�� �� ���᪨� �஬� ����� (��� MKV - ������� ����� mkvpropedit)
set "FINAL_KEYS=%FINAL_KEYS% -metadata language=rus -metadata:s:a:0 language=rus -metadata:s:s:0 language=rus"






:: === ����: FFMPEG ===
set "CMD_LINE="%FFM%" -i "%FNF%" %FINAL_KEYS% "%OUTPUT%""
echo.[CMD] ��ப� ����஢����: %CMD_LINE%>>"%LOG%"
%CMD_LINE% 2>"%FFMPEG_LOG%"

:: �᫨ full-range ������塞 metadata �१ mkvpropedit
if not defined COLOR_RANGE goto SKIPMKVPROP
echo.[INFO] Full color range: ������塞 � MKV �������⥫�� ⥣� c ������� mkvpropedit>>"%LOG%"
echo.[INFO] � MKV ���塞 �� �������஦�� �� ���᪨�>>"%LOG%"
:: ������� �⠢�� �모 ��஦�� - ���᪨�
"%MKVP%" "%OUTPUT%" --edit track:v1 --set "language=rus" --set "colour-range=1" --set "color-matrix-coefficients=1">nul
goto DONEMKVPROP
:SKIPMKVPROP
:: �᫨ OUTPUT_EXT=mkv - �⠢�� �모 ��஦�� - ���᪨�
if not "%OUTPUT_EXT%" == "mkv" goto DONEMKVPROP
echo.[INFO] � MKV ���塞 �� �������஦�� �� ���᪨�>>"%LOG%"
"%MKVP%" "%OUTPUT%" --edit track:v1 --set "language=rus">nul
:DONEMKVPROP





:: �६���� ��������㥬 UTF8-��� FFmpeg � OEM ��� ���᪠ �訡�� �१ findstr
set "VT=%temp%\tmp.vbs"
pushd "%OUTPUT_DIR%logs"
set "TMPFLUTF=$flogutf"
set "TMPFLOEM=$flogoem"
if exist "%TMPFLUTF%" del "%TMPFLUTF%"
if exist "%TMPFLOEM%" del "%TMPFLOEM%"
copy "%FFMPEG_LOG_NAME%" "%TMPFLUTF%">nul
echo.With CreateObject("ADODB.Stream"^)>"%VT%"
echo..Type=2:.Charset="UTF-8":.Open:.LoadFromFile "%TMPFLUTF%">>"%VT%"
echo.s=.ReadText:.Close>>"%VT%"
echo..Type=2:.Charset="cp866":.Open:.WriteText s>>"%VT%"
echo..SaveToFile "%TMPFLOEM%",2:.Close>>"%VT%"
echo.End With>>"%VT%"
cscript //nologo "%VT%"
del "%TMPFLUTF%"
findstr /i "error failed" "%TMPFLOEM%">nul
if %ERRORLEVEL% EQU 0 (
    echo.FFmpeg �����訫�� � �訡��� - �. "%FFMPEG_LOG_NAME%"
    echo.[ERROR] FFmpeg �����訫�� � �訡��� - �. "%FFMPEG_LOG_NAME%">>"%LOG%"
)
del "%TMPFLOEM%"
popd
del "%VT%"

:: �����訫� ��ࠡ��� 䠩��
echo.%DATE% %TIME:~0,8% ��ࠡ�⪠ %FNWE% �����襭�.
echo.������ "%OUTPUT_NAME%.%OUTPUT_EXT%".
echo.C�. ���� � ����� "%OUTPUT_DIR%logs".
echo.---
echo.[INFO] %DATE% %TIME:~0,8% ������ %OUTPUT_NAME%.%OUTPUT_EXT%>>"%LOG%"

:: ��������㥬 OEM-��� � UTF-8:
:: %LOGE% - �室��� OEM-���, %LOGU% - ��室��� UTF-8-���. ������ ���� ��� ��ਫ���� � �����.
:: ���室�� � ����� Logs
set "VT=%temp%\tmp.vbs"
pushd "%OUTPUT_DIR%logs"
echo.With CreateObject("ADODB.Stream"^)>"%VT%"
echo..Type=2:.Charset="cp866":.Open:.LoadFromFile "%LOGE%">>"%VT%"
echo.s=.ReadText:.Close>>"%VT%"
echo..Type=2:.Charset="UTF-8":.Open:.WriteText s>>"%VT%"
echo..SaveToFile "%LOGU%",2:.Close>>"%VT%"
echo.End With>>"%VT%"
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
echo.�� 䠩�� ��ࠡ�⠭�.
set ev="%temp%\$%~n0$.vbs"
set emsg="������ 䠩� '%~nx0' �����稫 ࠡ���."
chcp 1251 >nul
echo MsgBox %emsg%,,"%~nx0">%ev%
chcp 866 >nul
%ev% & del %ev%
pause
exit