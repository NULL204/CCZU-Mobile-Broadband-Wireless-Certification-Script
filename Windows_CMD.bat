::哆点认证脚本 BY 甲鱼鱼
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

::设置变量

::这里是账号
set user_account=
::这里是密码
set user_password=

::获取上网登录页IP，因为我不知道其他宿舍或者地区的IP是否一样，所以通过这种方式获取登录页IP
for /f "tokens=2 delims=/" %%i in ('curl -s "http://www.msftconnecttest.com/redirect" ^| findstr "NextURL"') do set URL=%%i
for /f "tokens=1 delims=:" %%i in ('echo %URL%') do set URL=%%i

::通过 ipconfig 命令获取本机 WLAN IP 地址
::ipconfig 有多个网卡输出，这里只获取 无线局域网适配器 WLAN 的 IP 地址
for /f "tokens=1 delims=:" %%i in ('ipconfig ^| findstr /n "WLAN"') do set num=%%i
set /a num-=1
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| more +%num% ^| findstr "IPv4" ^| more +0') do set ip=%%i
::去除空格
set ip=%ip: =%

::获取当前13位时间戳
for /f "tokens=1,2 delims=." %%i in ('powershell -Command "(Get-Date -UFormat %%s)"') do set timet1=%%i&set timet2=%%j
set timet=%timet1%%timet2%
for /f %%i in ('echo %timet:~0,13%') do set timet=%%i

::callback的生成方式是时间戳+一个随机数,原来的生成方式为：Math.floor(Math.random() * 10000 + 500)，效果为生成一个范围在 500 到 10499 之间的随机整数
::Although using the timestamp directly for callback works, it might trigger rate limits sometimes.

::以下是使用powershell以及cmd批处理实现的相同效果的方式

::获取当前时间的毫秒部分（0-999）
for /f %%a in ('powershell -command "(Get-Date).Millisecond"') do set ms=%%a
:: 使用时间毫秒值初始化随机种子
set /a seed=%ms%
:: 生成一个大随机数
set /a "large_random=((!seed! * 1103515245 + 12345) & 0x7fffffff)"
:: 将大随机数缩小到0-9999的范围
set /a "random_number=(!large_random! %% 10000)"
:: 添加500以获得500-10499的范围
set /a "final_number=!random_number! + 500"

::由于13位UNIX时间戳超出了32bit限制，对timet进行分割运算
for /f %%i in ('echo %timet:~0,3%') do set /a high_timet=%%i
for /f %%i in ('echo %timet:~4,13%') do set /a low_timet=%%i
::对低位timet进行加法运算
set /a "low_timet=!low_timet! + !final_number!"
::组合高低位timet
set callback_number=%high_timet%%low_timet%

::这两个变量与时间戳有关
set callback=dr%callback_number%
set _=%timet%

::以下的变量似乎是固定的
set wlan_user_mac=000000000000
set wlan_ac_ip=
set wlan_ac_name=0011.0519.250.00

::发送 curl GET 请求
curl -X GET "http://%URL%:801/eportal/?c=Portal&a=login&callback=%callback%&login_method=1&user_account=%%2Cb%%2C%user_account%&user_password=%user_password%&wlan_user_ip=%ip%&wlan_user_mac=%wlan_user_mac%&wlan_ac_ip=%wlan_ac_ip%&wlan_ac_name=%wlan_ac_name%&jsVersion=3.0&_=%_%"

::注销命令，注意使用新的时间戳
::curl -X GET "http://211.103.11.101:801/eportal/?c=Portal&a=logout&callback=%callback%&login_method=1&user_account=drcom&user_password=123&ac_logout=0&wlan_user_ip=%ip%&wlan_user_ipv6=&wlan_vlan_id=0&wlan_user_mac=%wlan_user_mac%&wlan_ac_ip=%wlan_ac_ip%&wlan_ac_name=%wlan_ac_name%&jsVersion=3.0&_=%_%"

echo.
pause
