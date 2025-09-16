chcp 65001
cd /d C:\Users\depei_liu\w\13X，芯兄弟，PS5默认音量过小\001-1-20250519-复现问题\1-1-sdk
python C:\Users\depei_liu\Dp1\lazy\nvim1\cmds1\16-cbp2cmake.py C:\Users\depei_liu\w\13X，芯兄弟，PS5默认音量过小\001-1-20250519-复现问题\1-1-sdk\app\projects\standard\app.cbp C:\Users\depei_liu\w\13X，芯兄弟，PS5默认音量过小\001-1-20250519-复现问题\1-1-sdk\CMakeLists.txt
rd /s /q build
cmake -B build -G "MinGW Makefiles" -DCMAKE_EXPORT_COMPILE_COMMANDS=1
copy build\compile_commands.json . /y
