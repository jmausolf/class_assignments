import pandas as pd
import os, sys, subprocess
import shutil
from glob import glob



#Set Assignment Number
assignment_number = 1


def return_ta(assignment_number):
	if assignment_number % 2 == 1:
		return 'Josh'
	else:
		return 'Keertana'


def make_folder_name(row):

	n = str(row['index']+1)
	o = row['full_name']
	return n+'__'+o.lower().replace(' ', '_')


def rename_folders(row):

	old_name = row['github_handle']
	new_name = row['fullname_clean']

	try:
		os.rename(old_name, new_name)
	except:
		print(old_name, new_name)
		pass

#Make Folder Names
df = pd.read_csv("../perspectives_sect_1_gradesheet_MASTER.csv")
df = df.reset_index()
df['fullname_clean'] = df.apply(make_folder_name, axis=1)


#Filter for Preceptor / Weekly Students to Grade
ta = return_ta(assignment_number)
df = df.loc[df['ta'] == ta]
df = df[['fullname_clean', 'github_handle', 'ta']]
print(df)

#Rename Selected Folders
df.apply(rename_folders, axis=1)


## Files to Remove
rm_dirs = [d for d in os.listdir(os.getcwd()) 
				if os.path.isdir(d)
				and not os.path.basename(d)[0].isdigit()]

## Delete Extra Folders
for r in rm_dirs:
	del_cmd = "rm -rf {}".format(r)
	subprocess.call(del_cmd, shell=True)



