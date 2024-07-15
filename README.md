# README

## Project Description
This repository contains the results of an 8-week period of research and analysis completed by three undergraduate students from Taylor University, during the summer of 2024. The team was presented with an outside data source, collected from weather balloons launched the day of the total solar eclipse on April 8th, 2024. The files here guide through the process of preprocessing the dataset, adding additional columns, performing analysis on the data, and developing deliverable results. 

## Data Availability
As of the latest update to this repository, the data used to conduct this study is not publically available, and is thus not included with the files here. However, there is potential for it to be available upon request. 

## Installations and setup
This code was primarily written and made to run in an RStudio Environment, and thus the following packages may need to be installed:
tidyverse, fs, readr, mosaic, dplyr, effsize, forecast, lmtest, imputeTS, Metrics, caret, stringr, lubridate, VIM, brms, httr, jsonlite, ggplot2, tidyr

You can do so by entering the following into a console or RScript:
`install.packages(‘tidyverse’)`
`install.packages(‘fs’)`
`install.packages(‘readr’)`
`install.packages(‘mosaic’)`
`install.packages(‘dplyr’)`
`install.packages(‘effsize’)`
`install.packages(‘forecast’)`
`install.packages(‘lmtest’)`
`install.packages(‘imputeTS’)`
`install.packages(‘Metrics’)`
`install.packages(‘caret’)`
`install.packages(‘stringr’)`
`install.packages(‘lubridate’)`
`install.packages(‘VIM’)`
`install.packages(‘brms’)`
`install.packages(‘httr’)`
`install.packages(‘jsonlite’)`
`install.packages(‘ggplot2’)`
`install.packages(‘tidyr’)`

You may also need to install the following Python packages: panda, numpy, scikit-learn, 
`install.packages("reticulate")`
`pip install pandas`
`pip install scikit-learn`
`pip install numpy`


To recreate our analysis and steps from our report in their entirety, several files are provided. We will explain the structure and basic function of the provided files and folders, while explanation of any additional created files and folders can be found within the files that create them themselves. It's important to note that many of these files are set up to read from the results of previous files (and thus could be used in the future with new/additional data) to provide a similar analysis

## Contents
***Order of operation:*** These files follow the 8-week process of research and analysis from start to finish, and as such many of the later files depend on results from earlier files. Here is a brief note on the most optimal order these files are to be run:

	1. ExplainationOfImputation.Rmd - Reads from original file
		
	2. FillingAllNulls.qmd - Reads from original file- exports cleaned data. Necessary to run.
	
	3. cleaning moon.R - Reads from OriginalMoonData.csv, exports expanded_testingcleaningofmoon.csv. Necessary to run for app.R
	
	4. app.R - Reads from cleaned data and 
	 
	5. AltitudeAndAccel.Rmd - analysis of cleaned data
	 
	6. TemperatureAnalysis.ipynb - analysis of cleaned data
      
### PreProcessing Files

#### ExplainationOfImputation.Rmd  
The file detailing the steps of selecting methods of imputation for the columns for 3 variables: Temperature, Acceleration, and Light. It is important to note that the purpose of this file is simply exploration of the reasoning behind the methods of imputation selected for later use; it is not intended to be the main file of imputation itself. This file reads in the original data set and creates several folders consisting of the data necessary for explanation of the models, as well as displays graphs showing the resulting “best” imputations. It is not necessary to run this file in order to run any files afterwards, ad it only provides explaination as to why certain imputation methods were chosen for certain columns.

#### FillingAllNulls.qmd 
File that takes the original .csv file and creates files for individual balloons, then creates new imputed and indicator columns. The resulting file is `AllNullsFilled.csv`.

### Interactive Application

#### OriginalMoonData.csv 
This file contains information found at https://eclipse.gsfc.nasa.gov/SEpath/SEpath2001/SE2024Apr08Tpath.html, providing information about the location of the moon’s shadow at different times during the eclipse. Nothing need be done with this file - it is here to be read into cleaning moon.R

#### cleaning moon.R 
This file is responsible for most of the transformation of the original data found from NASA to the data processed and used by the interactive application. It reads in `OriginalMoonData.csv`, while outputting `expanded_testingcleaningofmoon.csv`.

#### expanded_testingcleaningofmoon.csv 
This is the data that is the result of `cleaning moon.R`, should you not desire to re-run the cleaning file and just run the app itself. Nothing needs to be done on the user side with this file.

#### app.R 
This file is responsible for producing a Shiny application visualizing the data resulting from the PreProcessing Steps. It reads in both `expanded_testingcleaningofmoon.csv` and `AllNullsFilled.csv` and transforms that information into an interactive visual overlaying the path of the moon and balloons at the time indicated by a user-controlled slider. It also provides a table detailing information about each balloon at that time. 
	
### Analysis
#### AltitudeAndAccel.Rmd 
This file includes steps taken to analyze the effects of totality on Acceleration between 60,000-70,000 ft. It also details a more generalized approach, looking at similar patterns in a higher number of balloons found in differing areas. It reads in `AllNullsFilled.csv`, walks through the steps of analysis, and gives conclusions/results including graphs and other observations. 

#### TemperatureAnalysis.ipynb
This file is a supplementary file containing python code used to evaluate the effect of totality on temperature. 
