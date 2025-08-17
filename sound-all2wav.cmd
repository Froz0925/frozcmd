@echo off
:: � ��砫� � ���� FMTS - ��易⥫쭮 �஡���
set "FMTS= .ac3 .aac .eac3 .flac .m4a .m4b .mka .mp3 .ogg .opus .wma .wv "
set "EOUT=wav"

set "DO=All audio to .%EOUT%"
title %DO%
set "VRS=Froz %DO% v15.08.2025"
echo(%VRS%
echo.

set "EX=%~dp0bin\ffmpeg.exe"
if not exist "%EX%" (
    echo(%EX% �� ������, ��室��.
    echo.
    pause
    exit /b
)
if "%~1"=="" (
    echo �����ন����� �ଠ��:%FMTS%
    echo ������ �� �ਯ� 䠩�� ��� ���� �����.
    echo.
    pause
    exit /b
)
:: �஢�ઠ ����� ��㬥�⮢ CMD �१ VBS
:: ⠪ ��� � CMD ��� ������᭮�� ᯮᮡ� ������ ��ப� � &)(
set "TV=%temp%\%~nx0_len_%random%.vbs"
set "TO=%temp%\%~nx0_out_%random%.txt"
:: ������� ����� ��� ��㬥�⮢ � �஡����� - ��� �஢�ન ����� CMD (8191)
:: ���ᨢ + Join, �.�. WScript.Arguments �� ᮢ���⨬ � Join �������
:: �஢�ઠ �� "%~1"=="" ��� ��࠭���� a.Count >= 1 , ����� ReDim ������ᥭ
echo Set a=WScript.Arguments.Unnamed:ReDim b(a.Count-1)>"%TV%"
echo For i=0To a.Count-1:b(i)=a(i):Next>>"%TV%"
echo WScript.Echo Len(Join(b," "))>>"%TV%"
cscript //nologo "%TV%" %* >"%TO%"
set "ALEN=0"
set /p "ALEN=" <"%TO%"
del "%TV%" & del "%TO%"
if %ALEN% gtr 7500 (
    echo ��������: ᫨誮� ������� �������.
    echo ���� ����� ��⥩ � 䠩��� ����� 7500 ᨬ����� - �������� ����� ������.
    echo ��࠭�祭�� Windows - 8191 ᨬ���, ��⠫쭮� �㤥� ��१���.
    echo.
    echo ������ ����� ����� �⤥���� 䠩���, ��� �������� ���ﬨ. ��室��.
    echo.
    pause
    exit /b
)
:: ����: �� �� ��ࠡ�⠭ ��� �� ���� 䠩� - ��� ᮮ�饭�� � ���⮬ १����.
set FOUND=
:: �஢��塞 ���� ��㬥�� - ����� ��� 䠩�
set "ATR=%~a1"
if /I "%ATR:~0,1%"=="d" goto folder
echo ��ࠡ�⪠ 䠩���...
echo.
:loop
if "%~1"=="" goto e
set "FNF=%~f1"
set "FN=%~n1"
set "EXT=%~x1"
set "OUTF=%~dp1%~n1.%EOUT%"
call :go
shift
goto loop

:folder
echo(��ࠡ�⪠ ����� "%~n1"
echo.
cd /d "%~f1"
for /f "delims=" %%F in ('dir /b /a-d 2^>nul') do (
    set "FNF=%%~fF"
    set "FN=%%~nF"
    set "EXT=%%~xF"
    set "OUTF=%%~nF.%EOUT%"
    call :go
)
echo.
echo ����� "%~n1" ��ࠡ�⠭�.
goto e

:go
if not exist "%FNF%" goto skip
if /i "%EXT%"=="" goto skip
echo %FMTS% | findstr /i /c:" %EXT% " >nul
if errorlevel 1 goto skip
if /i "%EXT%"==".%EOUT%" goto skip
if exist "%OUTF%" goto skip
echo(��������㥬: "%FN%%EXT%" -^> "%FN%.%EOUT%"
"%EX%" -hide_banner -i "%FNF%" -f %EOUT% -c:a pcm_s16le "%OUTF%"
echo.
set "FOUND=1"
exit /b
:skip
echo("%FN%%EXT%" - �ய�饭 (�������ন����� ��� 㦥 ��ࠡ�⠭)
echo.
exit /b


:e
if not defined FOUND echo ��� 䠩��� �����ন������ �ଠ⮢.
set "EV=%temp%\%~nx0-end-%random%.vbs"
set "EMSG=�� 䠩�� ��ࠡ�⠭�."
chcp 1251 >nul
echo MsgBox "%EMSG%",,"%~nx0">"%EV%"
chcp 866 >nul
"%EV%" & del "%EV%"
pause