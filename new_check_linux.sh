#! /bin/bash 
#vesion 1.0
#author by  (tanjie)

ipadd=`ifconfig -a | grep Bcast | awk -F "[ :]+" '{print $4}' | tr "\n" "_"`
cat <<EOF
*************************************************************************************
*****				linux基线检查脚本	  	     		*****
*****				Author(tanjie)	  	     		*****
*************************************************************************************
*****				linux基线配置规范设计				*****
*****				输出结果"/tmp/${ipadd}_checkResult.txt"				*****
*************************************************************************************
EOF


echo "IP: ${ipadd}" >> "/tmp/${ipadd}_checkResult.txt"

user_id=`whoami`
echo "当前扫描用户：${user_id}" >> "/tmp/${ipadd}_checkResult.txt"

scanner_time=`date '+%Y-%m-%d %H:%M:%S'`
echo "当前扫描时间：${scanner_time}" >> "/tmp/${ipadd}_checkResult.txt"

echo "***************************"
echo "账号策略检查中..."
echo "***************************"

#编号：SBL-Linux-02-01-01 
#项目：帐号与口令-用户口令设置
#合格：Y;不合格：N
#不合格地方

passmax=`cat /etc/login.defs | grep PASS_MAX_DAYS | grep -v ^# | awk '{print $2}'`
passmin=`cat /etc/login.defs | grep PASS_MIN_DAYS | grep -v ^# | awk '{print $2}'`
passlen=`cat /etc/login.defs | grep PASS_MIN_LEN | grep -v ^# | awk '{print $2}'`
passage=`cat /etc/login.defs | grep PASS_WARN_AGE | grep -v ^# | awk '{print $2}'`

echo "SBL-Linux-02-01-01:" >> "/tmp/${ipadd}_checkResult.txt"
if [ $passmax -le 90 -a $passmax -gt 0 ];then
  echo "Y:口令生存周期为${passmax}天，符合要求" >> "/tmp/${ipadd}_checkResult.txt"
else
  echo "N:口令生存周期为${passmax}天，不符合要求,建议设置不大于90天" >> "/tmp/${ipadd}_checkResult.txt"
fi

if [ $passmin -ge 6 ];then
  echo "Y:口令更改最小时间间隔为${passmin}天，符合要求" >> "/tmp/${ipadd}_checkResult.txt"
else
  echo "N:口令更改最小时间间隔为${passmin}天，不符合要求，建议设置大于等于6天" >> "/tmp/${ipadd}_checkResult.txt"
fi

if [ $passlen -ge 8 ];then
  echo "Y:口令最小长度为${passlen},符合要求" >> "/tmp/${ipadd}_checkResult.txt"
else
  echo "N:口令最小长度为${passlen},不符合要求，建议设置最小长度大于等于8" >> "/tmp/${ipadd}_checkResult.txt"
fi

if [ $passage -ge 30 -a $passage -lt $passmax ];then
  echo "Y:口令过期警告时间天数为${passage},符合要求" >> "/tmp/${ipadd}_checkResult.txt"
else
  echo "N:口令过期警告时间天数为${passage},不符合要求，建议设置大于等于30并小于口令生存周期" >> /"/tmp/${ipadd}_checkResult.txt"
fi

echo "***************************"
echo "账号是否会主动注销检查中..."
echo "***************************"
checkTimeout=$(cat /etc/profile | grep TMOUT | awk -F[=] '{print $2}')
if [ $? -eq 0 ];then
  TMOUT=`cat /etc/profile | grep TMOUT | awk -F[=] '{print $2}'`
  if [ $TMOUT -le 600 -a $TMOUT -ge 10 ];then
    echo "Y:账号超时时间${TMOUT}秒,符合要求" >> "/tmp/${ipadd}_checkResult.txt"
  else
    echo "N:账号超时时间${TMOUT}秒,不符合要求，建议设置小于600秒" >> "/tmp/${ipadd}_checkResult.txt"
  fi
else
  echo "N:账号超时不存在自动注销,不符合要求，建议设置小于600秒" >> "/tmp/${ipadd}_checkResult.txt"
fi



#编号：SBL-Linux-02-01-02 
#项目：帐号与口令-root用户远程登录限制
#合格：Y;不合格：N
#不合格地方

echo "***************************"
echo "检查root用户是否能远程登录限制..."
echo "***************************"

echo "SBL-Linux-02-01-02:" >> "/tmp/${ipadd}_checkResult.txt"
remoteLogin=$(cat /etc/ssh/sshd_config | grep -v ^# |grep "PermitRootLogin no")
if [ $? -eq 0 ];then
  echo "Y:已经设置远程root不能登陆，符合要求" >> "/tmp/${ipadd}_checkResult.txt"
else
  echo "N:已经设置远程root能登陆，不符合要求，建议/etc/ssh/sshd_config添加PermitRootLogin no" >> "/tmp/${ipadd}_checkResult.txt"
fi




#编号：SBL-Linux-02-01-03
#项目：帐号与口令-检查是否存在除root之外UID为0的用户
#合格：Y;不合格：N
#不合格地方

#查找非root账号UID为0的账号
echo "SBL-Linux-02-01-03:" >> "/tmp/${ipadd}_checkResult.txt"
UIDS=`awk -F[:] 'NR!=1{print $3}' /etc/passwd`
flag=0
for i in $UIDS
do
  if [ $i = 0 ];then
    echo "N:存在非root账号的账号UID为0，不符合要求" >> "/tmp/${ipadd}_checkResult.txt"
  else
    flag=1
  fi
done
if [ $flag = 1 ];then
  echo "Y:不存在非root账号的账号UID为0，符合要求" >> "/tmp/${ipadd}_checkResult.txt"
fi


#编号：SBL-Linux-02-01-04
#项目：帐号与口令-检查telnet服务是否开启
#合格：Y;不合格：N
#不合格地方
#检查telnet是否开启
echo "SBL-Linux-02-01-04:" >> "/tmp/${ipadd}_checkResult.txt"
telnetd=`cat /etc/xinetd.d/telnet | grep disable | awk '{print $3}'`
if [ "$telnetd"x = "yes"x ]; then
  echo "N:检测到telnet服务开启，不符合要求，建议关闭telnet" >> "/tmp/${ipadd}_checkResult.txt"
fi



#编号：SBL-Linux-02-01-05
#项目：帐号与口令-root用户环境变量的安全性
#合格：Y;不合格：N
#不合格地方
#检查目录权限是否为777
echo "SBL-Linux-02-01-05:" >> "/tmp/${ipadd}_checkResult.txt"
dirPri=$(find $(echo $PATH | tr ':' ' ') -type d \( -perm -0777 \) 2> /dev/null)

if [  -z "$dirPri" ] 
then
  echo "Y:目录权限无777的,符合要求" >> "/tmp/${ipadd}_checkResult.txt"
else
  echo "N:文件${dirPri}目录权限为777的，不符合要求。" >> "/tmp/${ipadd}_checkResult.txt"
fi


#编号：SBL-Linux-02-01-06
#项目：帐号与口令-远程连接的安全性配置
#合格：Y;不合格：N
#不合格地方
echo "SBL-Linux-02-01-06:" >> "/tmp/${ipadd}_checkResult.txt"
fileNetrc=`find / -xdev -mount -name .netrc -print 2> /dev/null`
if [  -z "${fileNetrc}" ];then
  echo "Y:不存在.netrc文件，符合要求" >> "/tmp/${ipadd}_checkResult.txt"
else
  echo "N:存在.netrc文件，不符合要求" >> "/tmp/${ipadd}_checkResult.txt"
fi


fileRhosts=`find / -xdev -mount -name .rhosts -print 2> /dev/null`
if [ -z "$fileRhosts" ];then
  echo "Y:不存在.rhosts文件，符合要求" >> "/tmp/${ipadd}_checkResult.txt"
else
  echo "N:存在.rhosts文件，不符合要求" >> "/tmp/${ipadd}_checkResult.txt"
fi



#编号：SBL-Linux-02-01-07
#项目：帐号与口令-用户的umask安全配置
#合格：Y;不合格：N
#不合格地方
#检查umask设置
echo "SBL-Linux-02-01-07:" >> "/tmp/${ipadd}_checkResult.txt"
umask1=`cat /etc/profile | grep umask | grep -v ^# | awk '{print $2}'`
umask2=`cat /etc/csh.cshrc | grep umask | grep -v ^# | awk '{print $2}'`
umask3=`cat /etc/bashrc | grep umask | grep -v ^# | awk 'NR!=1{print $2}'`
flags=0
for i in $umask1
do
  if [ $i != "027" ];then
    echo "N:/etc/profile文件中所所设置的umask为${i},不符合要求，建议设置为027" >> "/tmp/${ipadd}_checkResult.txt"
    flags=1
    break
  fi
done
if [ $flags == 0 ];then
  echo "Y:/etc/profile文件中所设置的umask为${i},符合要求" >> "/tmp/${ipadd}_checkResult.txt"
fi 


flags=0
for i in $umask2
do
  if [ $i != "027" ];then
    echo "N:/etc/csh.cshrc文件中所所设置的umask为${i},不符合要求，建议设置为027" >> "/tmp/${ipadd}_checkResult.txt"
    flags=1
    break
  fi
done  
if [ $flags == 0 ];then
  echo "Y:/etc/csh.cshrc文件中所设置的umask为${i},符合要求" >> "/tmp/${ipadd}_checkResult.txt"
fi


flags=0
for i in $umask3
do
  if [ $i != "027" ];then
    echo "N:/etc/bashrc文件中所设置的umask为${i},不符合要求，建议设置为027" >> "/tmp/${ipadd}_checkResult.txt"
    flags=1
    break
  fi
done
if [ $flags == 0 ];then
  echo "Y:/etc/bashrc文件中所设置的umask为${i},符合要求" >> "/tmp/${ipadd}_checkResult.txt"
fi




#编号：SBL-Linux-02-01-08
#项目：帐号与口令-grub和lilo密码是否设置检查
#合格：Y;不合格：N
#不合格地方
#grub和lilo密码是否设置检查
echo "SBL-Linux-02-01-08:" >> "/tmp/${ipadd}_checkResult.txt"
grubfile=$(cat /etc/grub.conf | grep password)
if [ $? -eq 0 ];then
  echo "Y:已设置grub密码,符合要求" >> "/tmp/${ipadd}_checkResult.txt"
else
  echo "N:没有设置grub密码，不符合要求,建议设置grub密码" >> "/tmp/${ipadd}_checkResult.txt"
fi

lilo=$(cat /etc/lilo.conf | grep password)
if [ $? -eq 0 ];then
  echo "Y:已设置lilo密码,符合要求" >> "/tmp/${ipadd}_checkResult.txt"
else
  echo "N:没有设置lilo密码，不符合要求,建议设置lilo密码" >> "/tmp/${ipadd}_checkResult.txt"
fi




#编号：SBL-Linux-02-02-01
#项目：文件系统-重要目录和文件的权限设置
#合格：Y;不合格：N
#不合格地方
echo "SBL-Linux-02-02-01:" >> "/tmp/${ipadd}_checkResult.txt"
echo "***************************"
echo "检查重要文件权限中..."
echo "***************************"

file1=`ls -l /etc/passwd | awk '{print $1}'`
file2=`ls -l /etc/shadow | awk '{print $1}'`
file3=`ls -l /etc/group | awk '{print $1}'`
file4=`ls -l /etc/securetty | awk '{print $1}'`
file5=`ls -l /etc/services | awk '{print $1}'`
file6=`ls -l /etc/xinetd.conf | awk '{print $1}'`
file7=`ls -l /etc/grub.conf | awk '{print $1}'`
file8=`ls -l /etc/lilo.conf | awk '{print $1}'`



#检测文件权限为400的文件
if [ $file2 = "-r--------" ];then
  echo "Y:/etc/shadow文件权限为400，符合要求" >> "/tmp/${ipadd}_checkResult.txt"
else
  echo "N:/etc/shadow文件权限不为400，不符合要求，建议设置权限为400" >> "/tmp/${ipadd}_checkResult.txt"
fi



#检测文件权限为600的文件
if [ $file4 = "-rw-------" ];then
  echo "Y:/etc/security文件权限为600，符合要求" >> "/tmp/${ipadd}_checkResult.txt"
else
  echo "N:/etc/security文件权限不为600，不符合要求，建议设置权限为600" >> "/tmp/${ipadd}_checkResult.txt"
fi

if [ $file6 = "-rw-------" ];then
  echo "Y:/etc/xinetd.conf文件权限为600，符合要求" >> "/tmp/${ipadd}_checkResult.txt"
else
  echo "N:/etc/xinetd.conf文件权限不为600，不符合要求，建议设置权限为600" >> "/tmp/${ipadd}_checkResult.txt"
fi

if [ $file7 = "-rw-------" ];then
  echo "Y:/etc/grub.conf文件权限为600，符合要求" >> "/tmp/${ipadd}_checkResult.txt"
else
  echo "N:/etc/grub.conf文件权限不为600，不符合要求，建议设置权限为600" >> "/tmp/${ipadd}_checkResult.txt"
fi

if [ -f /etc/lilo.conf ];then
  if [ $file8 = "-rw-------" ];then
    echo "Y:/etc/lilo.conf文件权限为600，符合要求" >> "/tmp/${ipadd}_checkResult.txt"
  else
    echo "N:/etc/lilo.conf文件权限不为600，不符合要求，建议设置权限为600" >> "/tmp/${ipadd}_checkResult.txt"
  fi
  
else
  echo "N:/etc/lilo.conf文件夹不存在"
fi

#检测文件权限为644的文件

if [ $file1 = "-rw-r--r--" ];then
  echo "Y:/etc/passwd文件权限为644，符合要求" >> "/tmp/${ipadd}_checkResult.txt"
else
  echo "N:/etc/passwd文件权限不为644，不符合要求，建议设置权限为644" >> "/tmp/${ipadd}_checkResult.txt"
fi

if [ $file5 = "-rw-r--r--" ];then
  echo "Y:/etc/services文件权限为644，符合要求" >> "/tmp/${ipadd}_checkResult.txt"
else
  echo "N:/etc/services文件权限不为644，不符合要求，建议设置权限为644" >> "/tmp/${ipadd}_checkResult.txt"
fi

if [ $file3 = "-rw-r--r--" ];then
  echo "Y:/etc/group文件权限为644，符合要求" >> "/tmp/${ipadd}_checkResult.txt"
else
  echo "N:/etc/group文件权限不为644，不符合要求，建议设置权限为644" >> "/tmp/${ipadd}_checkResult.txt"
fi

#编号：SBL-Linux-02-02-02
#项目：文件系统-查找未授权的SUID/SGID文件
#合格：Y;不合格：N
#不合格地方
echo "SBL-Linux-02-02-02:" >> "/tmp/${ipadd}_checkResult.txt"
unauthorizedfile=`find / \( -perm -04000 -o -perm -02000 \) -type f `
echo "C:文件${unauthorizedfile}设置了SUID/SGID，请检查是否授权" >> "/tmp/${ipadd}_checkResult.txt"


#编号：SBL-Linux-02-02-03
#项目：文件系统-检查任何人都有写权限的目录
#合格：Y;不合格：N;检查：C
#不合格地方
echo "SBL-Linux-02-02-03:" >> "/tmp/${ipadd}_checkResult.txt"
checkWriteDre=$(find / -xdev -mount -type d \( -perm -0002 -a ! -perm -1000 \) 2> /dev/null)
if [  -z "${checkWriteDre}" ];then
  echo "Y:不存在任何人都有写权限的目录，符合要求" >> "/tmp/${ipadd}_checkResult.txt"
else
  echo "N:${checkWriteDre}目录任何人都可以写，不符合要求" >> "/tmp/${ipadd}_checkResult.txt"
fi	


#编号：SBL-Linux-02-02-04
#项目：文件系统-检查任何人都有写权限的文件
#合格：Y;不合格：N;检查：C
#不合格地方
echo "SBL-Linux-02-02-04:" >> "/tmp/${ipadd}_checkResult.txt"
checkWriteFile=$(find / -xdev -mount -type f \( -perm -0002 -a ! -perm -1000 \) 2> /dev/null)
if [  -z "${checkWriteFile}" ];then
  echo "Y:不存在任何人都有写权限的目录，符合要求" >> "/tmp/${ipadd}_checkResult.txt"
else
  echo "N:${checkWriteFile}目录任何人都可以写，不符合要求" >> "/tmp/${ipadd}_checkResult.txt"
fi	


#编号：SBL-Linux-02-02-05
#项目：文件系统-检查异常隐含文件
#合格：Y;不合格：N;检查：C
#不合格地方
echo "SBL-Linux-02-02-05:" >> "/tmp/${ipadd}_checkResult.txt"
hideFile=$(find / -xdev -mount \( -name "..*" -o -name "...*" \) 2> /dev/null)
if [  -z "${hideFile}" ];then
  echo "Y:不存在隐藏文件，符合要求" >> "/tmp/${ipadd}_checkResult.txt"
else
  echo "N:${hideFile}是隐藏文件，建议审视" >> "/tmp/${ipadd}_checkResult.txt"
fi	

#编号：SBL-Linux-03-01-01 
#项目：日志审计-syslog登录事件记录
#合格：Y;不合格：N;检查：C
#不合格地方
echo "SBL-Linux-03-01-01:" >> "/tmp/${ipadd}_checkResult.txt"
recodeFile=$(cat /etc/syslog.conf)
if [  ! -z "${recodeFile}" ];then
   logFile=$(cat /etc/syslog.conf | grep -V ^# | grep authpriv.*)
  if [ ! -z "${logFile}" ];then
  	echo "Y:存在保存authpirv的日志文件" >> "/tmp/${ipadd}_checkResult.txt"
  else
    echo "N:不存在保存authpirv的日志文件" >> "/tmp/${ipadd}_checkResult.txt"
  fi
else
  echo "N:不存在／etc/syslog.conf文件，建议对所有登录事件都记录" >> "/tmp/${ipadd}_checkResult.txt"
fi	


#编号：SBL-Linux-03-01-02
#项目：系统文件-检查日志审核功能是否开启
#合格：Y;不合格：N;检查：C
echo "SBL-Linux-03-01-02:" >> "/tmp/${ipadd}_checkResult.txt"
auditdStatus=$(service auditd status 2> /dev/null)
if [ $? = 0 ];then
  echo "Y:系统日志审核功能已开启，符合要求" >> "/tmp/${ipadd}_checkResult.txt"
fi
if [ $? = 3 ];then
  echo "N:系统日志审核功能已关闭，不符合要求，建议service auditd start开启" >> "/tmp/${ipadd}_checkResult.txt"
fi


#编号：SBL-Linux-04-01-01 
#项目：系统文件-系统core dump状态
#合格：Y;不合格：N;检查：C
echo "SBL-Linux-04-01-01:" >> "/tmp/${ipadd}_checkResult.txt"
limitsFile=$(cat /etc/security/limits.conf | grep -V ^# | grep core)
if [ $? -eq 0 ];then
  soft=`cat /etc/security/limits.conf | grep -V ^# | grep core | awk {print $2}`
  for i in $soft
  do
    if [ "$i"x = "soft"x ];then
      echo "Y:* soft core 0 已经设置" >> "/tmp/${ipadd}_checkResult.txt"
    fi
    if [ "$i"x = "hard"x ];then
      echo "Y:* hard core 0 已经设置" >> "/tmp/${ipadd}_checkResult.txt"
    fi
  done
else 
  echo "N:没有设置core，建议在/etc/security/limits.conf中添加* soft core 0和* hard core 0" >> "/tmp/${ipadd}_checkResult.txt"
fi


#编号：SBL-Linux-04-01-02
#项目：系统文件-检查磁盘动态空间，是否大于等于80%
#合格：Y;不合格：N;检查：C
#
echo "SBL-Linux-04-01-02:" >> "/tmp/${ipadd}_checkResult.txt"
space=$(df -h | awk -F "[ %]+" 'NR!=1{print $5}')
for i in $space
do
  if [ $i -ge 80 ];then
    echo "C:警告！磁盘存储容量大于80%,建议扩充磁盘容量或者删除垃圾文件" >> "/tmp/${ipadd}_checkResult.txt"
  fi
done
