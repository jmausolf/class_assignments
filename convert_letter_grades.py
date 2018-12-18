import pandas as pd
import numpy as np


########################################
## Inputs
########################################

df = pd.read_csv('lettergrades.csv')

#Define Grade Cols
grade_cols = ['proposal_grade', 'lit_review_grade', 'datamethods_review']

#Define Grade Weights
weights = [.30, .55, .15]

#Define Grade Penalty
#One Grade Penalty, Col, Expected Value
grade_penalty = [1.0, 'ma_proposal_form', 'Signed']


#Define Letter Grade and GPA Mapping
#note: as two lists, not a dict
letter_grades = ['A', 'A-', 
				 'B+', 'B', 'B-',
				 'C+', 'C', 'C-',
				 'D+', 'D',
				 'F']

gpa_grades = [4.0, 3.7, 
			  3.3, 3.0, 2.7,
			  2.3, 2.0, 1.7,
			  1.3, 1.0,
			  0.0]
	
#Transcript Mapping
transcript_mapping = {'A':'A', 'A-':'A',
					  'B+':'A-', 'B':'A-', 'B-':'B+',
					  'C+':'B', 'C':'B', 'C-':'B',
					  'D+':'B-', 'D':'B-', 'F':'B-'
					 } 
	



########################################
## Core Functions
########################################

def rename_cols(col):
	c0 = str(col).replace(' ', '_').replace('-', '').lower()
	c1 = c0.replace('/', '').replace('__', '_')
	c2 = c1.replace('(', '').replace(')', '')
	return c2


def clean_grade_cols(df, cols):
	clean_col = lambda x: str(x).strip().replace(' ', '')
	
	for c in cols:
		df[c] = df[c].apply(clean_col)
	
	return df
	

def grade_average(df, cols, grade_mapping, weights=None, verbose=False):

	graded_cols = []
	for c in cols:
		grade_nm = c+'_grade'
		graded_cols.append(grade_nm)
		df[grade_nm] = df[c].replace(grade_mapping)
	
	df['unweighted_avg_grade'] = round(df.mean(axis=1, numeric_only=True), 4)
	
	if weights is None:
		pass
	else:
		i = 0
		weighted_grades = []
		dw = df.copy()
		for c in graded_cols:
			
			wgt_grade_nm = c+'_weighted'
			dw[wgt_grade_nm] = dw[c]*(weights[i])
			i+=1
			weighted_grades.append(wgt_grade_nm)
			
		dw = dw[weighted_grades]
		dw['total'] = dw.sum(axis=1, numeric_only=True)
		dw['weighted_sum'] = sum(weights)
		dw['weighted_avg_grade'] = round(dw['total'] / dw['weighted_sum'], 4)
		
		
		if verbose is False:
			dw = dw['weighted_avg_grade']
		else:
			pass
			
		df = pd.concat([df, dw], axis=1)
			
	return df


def apply_grade_penalty(penalty_df, grade_df, grade_cols, grade_penalty):

	#Establish Grade Penalty
	gp = grade_penalty
	df1 = pd.DataFrame(penalty_df.copy())
	df1['grade_penalty'] = None
	df1.loc[(df1[gp[1]] == gp[2]), 'grade_penalty'] = 0
	df1.loc[(df1[gp[1]] != gp[2]), 'grade_penalty'] = gp[0]

	#Apply Grade Penalty to Each Requested Grade Col
	gc = grade_cols
	df2 = grade_df.copy()
	df = pd.concat([df1, df2], axis=1)
	for c in gc:
		df[c] = df[c]-df['grade_penalty']

	#Drop gp[1] to avoid duplicate cols
	df = df.drop([gp[1]], axis=1)
	return df


def ret_midpoints(gpa_grades):
	
	df1 = pd.DataFrame(gpa_grades)
	df2 = df1.copy().iloc[1:].reset_index(drop=True)
	
	df = pd.concat([df1, df2], axis=1, ignore_index=True)
	df.columns = ['u', 'l']
	df = df.fillna(method='ffill')
	df['m'] = (df.u + df.l) / 2
	return df


def convert_gpa_to_letter(df, col, letter_grades, gpa_grades):
	
	#Get GPA Midpoints (Upper, Lower, Mid)
	gp = ret_midpoints(gpa_grades)
	
	#Format Grade Dataframe
	df = df.copy()[[col]]
	df.columns = ['g']
	
	#Loop Over Grade Options and Recode
	lg = letter_grades
	l = 0
	grade_col = col+'_letter'
	df[grade_col] = None
	for i, r in gp.iterrows():
		
		if l == 0:
			df.loc[ (df['g'] > r.m), grade_col] = lg[l]
			df.loc[((df['g'] <= r.m) & (df['g'] > r.l)), grade_col] = lg[l+1]
		elif l == len(lg)-1:
			df.loc[((df['g'] <= mid) & (df['g'] > r.l)), grade_col] = 'F'
			df.loc[(df['g'] == 0.0), grade_col] = 'F'
		else:
			df.loc[((df['g'] > r.m) & (df['g'] <= r.u)), grade_col] = lg[l]
			df.loc[((df['g'] <= r.m) & (df['g'] > r.l)), grade_col] = lg[l+1]
			if r.l == 0:
				mid = 0.5

		l+=1
	
	return df[[grade_col]]
	

########################################
## Run Main Functions
########################################

#Rename Cols
old_cols = df.columns.tolist()
new_cols = [rename_cols(c) for c in old_cols]
df.columns = new_cols

#Define Grade Cols
assignment_cols = ['a'+str(i) for i in range(1, len(grade_cols)+1)]

#Keep Subset of Data
dfs = df[grade_cols].copy()
dfs.columns = assignment_cols

#Grade Mapping
grade_mapping = dict(zip(letter_grades, gpa_grades))
print(grade_mapping)
print(transcript_mapping)

#Determine Average Weighted Grades
dfs = clean_grade_cols(dfs, assignment_cols)
dfw = grade_average(dfs, assignment_cols, grade_mapping, weights)

#Apply Grade Penalty
gp_df = df[grade_penalty[1]]
grade_cols = ['weighted_avg_grade', 'unweighted_avg_grade']
dfw = apply_grade_penalty(gp_df, dfw, grade_cols, grade_penalty)

#Return to Letter Grades
wg = convert_gpa_to_letter(dfw, 'weighted_avg_grade', letter_grades, gpa_grades)
ug = convert_gpa_to_letter(dfw, 'unweighted_avg_grade', letter_grades, gpa_grades)
grades = pd.concat([df, dfw, wg, ug], axis=1)


#Make of Copy of Weighted == Internal, and Mapped == Transcript Grades
grades['internal_grade_passing_criteria'] = grades['weighted_avg_grade_letter']
grades['transcript_grade'] = grades['weighted_avg_grade_letter'].map(transcript_mapping)

#Pass MA-RC
grades['require_MA_winter_quarter'] = 'Y'
grades.loc[(grades['weighted_avg_grade'] > 3.15), 'require_MA_winter_quarter'] = 'N'

#Drop Original Internal/External Grades
drop_cols = ['average_letter_grade_three_assignments_internal_benchmark_for_passing_course',
	   'overall_completion_grade_transcript_grade_for_those_officially_taking_class']
grades = grades.drop(drop_cols, axis=1)



print(grades.columns)
grades.to_csv('converted_grades.csv', index=False)

