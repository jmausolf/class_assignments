#!/bin/sh

##################################
###                            ###
###      Joshua G. Mausolf     ###
###   Department of Sociology  ###
###    University of Chicago   ###
###                            ###
##################################


#Define List of User Names
users='dhruvalb KenChenCompEcon keertanavc jtschoi yundai424 RSFlores jsgenan NetaGee fulinguo cosettelh hanjiaxu ellenhsieh ShuyanHuang nerdizzyz ruixili ShanglunLi liu431 SixueLiuMACSS hannamn madelaida smiklin policyglot SiyuanPengMike boyangqu HaowenShang tonofshell bhargavvader sunying2018 sanittawan josetan delores9584 nt546 di-Tong zeyuxu1997 yalingtsui dongchengecon Bobicheng-Zhang TianxinZheng AZorroMedina'

#Specify Fork
fork="persp-analysis_A18"


#Initiate Loop
for username in $users; do
	if [ ! -d $username ]; then
		echo "Collecting repo for " $username
		req_url='https://github.com/'$username'/'$fork
		git clone $req_url && mv $fork $username && cp ../.Rprofile $username
		sleep 5s
	else
		echo "Repository already collected. Attempting to update hw..."
		cd $username && git pull origin master && cd ..
		sleep 5s
	fi
done


