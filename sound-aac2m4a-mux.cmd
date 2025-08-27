@echo off
:: FMTS: ᯨ᮪ �����ন������ ���७��. ��易⥫�� �஡��� �� ��� � �����, � �窨.
:: EOUT: ��室��� ���७�� - ��� �窨.
set "FMTS= .aac "
set "EOUT=m4a"

set "DO=AAC mux to M4A"
title %DO%
set "VRS=Froz %DO% v27.08.2025"
echo(%VRS%
echo(
set "CMDN=%~n0"
set "EX=%~dp0bin\ffmpeg.exe"
if not exist "%EX%" echo("%EX%" �� ������, ��室��.& echo(& pause & exit /b
if "%~1"=="" (
    echo(�����ন����� �ଠ��:%FMTS%
    echo(������ �� �ਯ� 䠩�� ��� ���� �����.
    echo(
    pause
    exit /b
)
:: �஢�ઠ ����� ��㬥�⮢: ����� Windows 8191 ᨬ��� - ���� ����� ���� ��१��, � ��⠫�� �����
:: CMD �������� �� ��।�� &)( � %* - �ᯮ��㥬 VBS
:: ����� 㤠���� �஢��� "%~1"=="" - VBS �� ᬮ��� ������� �����
set "TV=%temp%\%CMDN%_len_%random%%random%.vbs"
set "TO=%temp%\%CMDN%_out_%random%%random%.txt"
>"%TV%" echo(Set a=WScript.Arguments.Unnamed:ReDim b(a.Count-1)
>>"%TV%" echo(For i=0To a.Count-1:b(i)=a(i):Next
>>"%TV%" echo(WScript.Echo Len(Join(b," "))
cscript //nologo "%TV%" %* >"%TO%"
set "ALEN=0"
set /p "ALEN=" <"%TO%"
del "%TV%" & del "%TO%"
if %ALEN% gtr 7500 (
    echo(��������: ᫨誮� ������� �������.
    echo(���� ����� ��⥩ � 䠩��� ����� 7500 ᨬ����� - �������� ����� ������.
    echo(��࠭�祭�� Windows - 8191 ᨬ���, ��⠫쭮� �㤥� ��१���.
    echo(
    echo(������ ����� ����� �⤥���� 䠩���, ��� �������� ���ﬨ. ��室��.
    echo(
    pause
    exit /b
)
:: ����: �� �� ��ࠡ�⠭ ��� �� ���� 䠩� - ��� ᮮ�饭�� � ���⮬ १����.
set FOUND=
:: �஢��塞 ���� ��㬥�� - ����� ��� 䠩�
set "ATR=%~a1"
if /I "%ATR:~0,1%"=="d" goto folder
echo(��ࠡ�⪠ 䠩���...
echo(
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
echo(
:: �ᯮ��㥬 pushd+popd, � �� cd /d �� ��砩 ��ࠡ�⪨ 䠩��� � �⥢�� ������ \\server\share\file.ext
pushd "%~f1"
for /f "delims=" %%F in ('dir /b /a-d') do (
    set "FNF=%%~fF"
    set "FN=%%~nF"
    set "EXT=%%~xF"
    set "OUTF=%%~nF.%EOUT%"
    call :go
)
popd
echo(
echo(����� "%~n1" ��ࠡ�⠭�.
goto e

:go
if not exist "%FNF%" goto skip
if /i "%EXT%"=="" goto skip
echo(%FMTS% | findstr /i /c:" %EXT% " >nul
if errorlevel 1 goto skip
if /i "%EXT%"==".%EOUT%" goto skip
if exist "%OUTF%" goto skip
echo(��������㥬: "%FN%%EXT%" -^> "%FN%.%EOUT%"
"%EX%" -hide_banner -i "%FNF%" -c copy "%OUTF%"
echo(
set "FOUND=1"
exit /b
:skip
echo("%FN%%EXT%" - �ய�饭 (�������ন����� ��� 㦥 ��ࠡ�⠭)
echo(
exit /b


:e
if not defined FOUND echo(��� 䠩��� �����ন������ �ଠ⮢.
set "EV=%temp%\%CMDN%-end-%random%%random%.vbs"
set "EMSG=�� 䠩�� ��ࠡ�⠭�."
chcp 1251 >nul
>"%EV%" echo(MsgBox "%EMSG%",,"%CMDN%"
chcp 866 >nul
cscript //nologo "%EV%"
del "%EV%"
pause