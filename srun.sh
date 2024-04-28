#!/bin/ash
USERNAME='221188100301'
PASSWORD='951753'
signin() {
    Stu_No=$1
    Stu_Passwd=$2
    URL="http://172.16.154.130/cgi-bin/srun_portal"
    Encrypted_No="{SRUN3}\r\n"
    Encrypted_Passwd=""
    for i in `seq ${#Stu_No}`
    do
        letter=$(printf "%d" "'${Stu_No:$(($i-1)):1}")
        let letter=letter+4
        letter=$(printf \\x`printf %x $letter`)
        Encrypted_No=$Encrypted_No$letter
    done
    for i in `seq ${#Stu_Passwd}`
    do
        i=$(($i-1))
        letter=$(printf "%d" "'${Stu_Passwd:$i:1}")
        if test $i -eq 0
        then
            ki=$(($letter^48))
        else
            ki=$(($letter^((10-i%10)+48)))
        fi
        _l=$((($ki&0x0f)+0x36))
        _h=$((($ki>>4&0x0f)+0x63))
        _l=$(printf \\x`printf %x $_l`)
        _h=$(printf \\x`printf %x $_h`)
        if  test $(($i%2)) -eq 1
        then
            result=$_h$_l
        else
            result=$_l$_h
        fi
        Encrypted_Passwd=$Encrypted_Passwd$result
    done
    sigin_result=$(wget -qO- --post-data=$(printf "username=";urlencode $Encrypted_No;printf "&password=";urlencode $Encrypted_Passwd;printf "&ac_id=1&action=login&type=3&n=117&mbytes=0&minutes=0&drop=0&pop=1&mac=02:00:00:00:00:00") $URL
)
    echo $sigin_result
    if [[ $sigin_result == login_ok* ]]
    then
        return 1
    else
        return 0
    fi
}
urlencode() {
    local LANG=C
    for i in `seq ${#1}`
    do
        local c="${1:$(($i-1)):1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c" ;; 
        esac
    done
}
# 220911开启了防共享检测，这里模拟设备UA，可自行修改（或删除）--user-agent参数
while true
do
    test_result=$(wget --timeout=3 -qO- http://connect.rom.miui.com/generate_204 --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36 Edg/105.0.1343.33")
    if [ -z "$test_result" ]; then
        echo "$(date '+%Y-%m-%d %X') Already online"
    else
        echo "$(date '+%Y-%m-%d %X') Offline, trying to reconnect..."
        signin $USERNAME $PASSWORD
        if test $? -eq 1; then
            echo "$(date '+%Y-%m-%d %X') Succeed!"
        else
            echo "$(date '+%Y-%m-%d %X') Failed!"
        fi
    fi
    sleep 5
done
# 另一种在线检测方案
# check_online() {
#     ping -c 1 114.114.114.114 >/dev/null 2>&1
#     if [ $? -eq 0 ]; then
#         return 0  # 用户在线
#     else
#         return 1  # 用户离线
#     fi
# }

# while true; do
#     if check_online; then
#         echo "Already online."
#     else
#         echo "Offline, trying to sign in..."
#         signin $USERNAME $PASSWORD
#         if check_online; then
#             echo "Sign in successful."
#         else
#             echo "Sign in failed."
#         fi
#     fi
#     sleep 5 # 每隔5秒检查一次网络
# done