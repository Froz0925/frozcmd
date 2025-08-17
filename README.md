Сборник моих (Froz) CMD-скриптов.
Так как cmd-файлы должны быть в кодировке OEM 866 - для просмотра в браузере на сайте GitHub дополнительно добавлены отдельные readme-версии (не для запуска!) с "*-UTF8-DoNotRun" в имени.
Расширения файлов таких readme-версий оставлены .cmd чтобы срабатывала авторасцветка cmd-кода.


APK_minAndroidVersion.cmd
Из указанных .apk-файлов в txt-файл извлекается минимальная версия Android.
В папку bin нужно положить aapt2_64.exe из Android Asset Packaging Tool (apktool)

EXIF-DTO_JPG2JPG.cmd
Копирует EXIF из Файл-1.jpg в Файл-2.jpg.
В папку bin нужно положить exiv2.exe.

media_renamer.cmd и media_renamer.txt
Пакетное переименование файлов по маске: YYYY-MM-DD_HHMMSS_имя_[PROGR].ext
для упорядочивания фото-видеоархивов с файлами из разных источников и форматов имён.
Работает с EXIF-JPG (DTO), датой в имени в различных сочетаниях символов и датой изменения файла (DLM).
В папку bin нужно положить exiv2.exe.

sound-all2wav.cmd
Распаковывает аудиофайлы из .ac3 .aac .eac3 .flac .m4a .m4b .mka .mp3 .ogg .opus .wma .wv в WAV 16 bit.
В папку bin нужно положить ffmpeg.exe.

sound-wav2mp3.cmd
Упаковывает wav-файлы в .mp3 CBR 320 kbit.
В папку bin нужно положить lame.exe.

sound-wav2opus.cmd
Упаковывает wav-файлы в .opus 128 kbit.
В папку bin нужно положить opusenc.exe.

video-2small.cmd
Перекодирование видеофайлов с телефонов/фотоаппаратов в уменьшенный размер для видеоархива без существенной потери качества.
Дефолтный энкодер - аппаратный FFMPEG hevc_nvenc (нужна современная видеокарта Nvidia и свежий драйвер), но можно использовать и другие.
В папку bin бужно положить ffmpeg.exe, ffprobe.exe, mediainfo.exe, mkvpropedit.exe.

