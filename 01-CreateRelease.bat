@echo off

SET NAME=OcbMicroSplatTestBiomes

if not exist build\ (
  mkdir build
)

if exist build\%NAME%\ (
  echo remove existing directory
  rmdir build\%NAME% /S /Q
)

mkdir build\%NAME%

SET VERSION=snapshot

if not "%1"=="" (
  SET VERSION=%1
)

echo create %VERSION%

xcopy *.dll build\%NAME%\
xcopy README.md build\%NAME%\
xcopy ModInfo.xml build\%NAME%\
xcopy Config build\%NAME%\Config\ /S
xcopy Resources build\%NAME%\Resources\ /S
xcopy UIAtlases build\%NAME%\UIAtlases\ /S

REM explicitly copy all files to exclude processed
xcopy "Worlds\Test Biomes\*.xml" "build\%NAME%\Worlds\Test Biomes\"
xcopy "Worlds\Test Biomes\*.raw" "build\%NAME%\Worlds\Test Biomes\"
xcopy "Worlds\Test Biomes\*.ttw" "build\%NAME%\Worlds\Test Biomes\"
xcopy "Worlds\Test Biomes\biomes.png" "build\%NAME%\Worlds\Test Biomes\"
xcopy "Worlds\Test Biomes\radiation.png" "build\%NAME%\Worlds\Test Biomes\"
xcopy "Worlds\Test Biomes\splat3.png" "build\%NAME%\Worlds\Test Biomes\"
xcopy "Worlds\Test Biomes\splat4.png" "build\%NAME%\Worlds\Test Biomes\"

cd build
echo Packaging %NAME%-%VERSION%.zip
powershell Compress-Archive %NAME% %NAME%-%VERSION%-V1.2.zip -Force
cd ..

SET RV=%ERRORLEVEL%
if "%CI%"=="" pause
exit /B %RV%
