#!/bin/sh

##################################
###                            ###
###      Joshua G. Mausolf     ###
###   Department of Sociology  ###
###    University of Chicago   ###
###                            ###
##################################


#Define List of User Names
users='Alex-A14 banerjeeesha LucasBJ xiaorancheng incipamus yanningcui ifarah srishtigoel nhonors kimswchi elliekoh FrannyMendesLevitin limchengyee lmhjulian jmarvelcoen nnickels yuepan4 pohyuquan XianQu2016 Rjschwa sullivannicole xt5 gmvelez longxuan0908 MichelleWang32 zhengyinyuan dizhou2010'

#Specify Fork
fork="hw08"


#Initiate Loop
for username in $users; do
	if [ ! -d $username ]; then
		echo "Collecting repo for " $username
		req_url='https://github.com/'$username'/'$fork
		git clone $req_url && mv $fork $username && cp ../.Rprofile $username
		sleep 5s
	else
		echo "Repository already collected. Pass"
	fi
done


