import os
import sys
import math
import argparse
import subprocess 
import csv
import numpy
#import dislin

'''
# SYS.ARGV DEFINITIONS

flatfile = sys.argv[1]        # path for flatfile.html
param = sys.argv[2]           # i/o param to parse

'''

# USAGE & POSITIONAL ARGS DEFINITION
 
parser = argparse.ArgumentParser()
parser.add_argument("resultfile", help="Assign the vdbench output file to parser")
parser.add_argument("ioparam", help="Assign the vdbench I/O param to parser")
args = parser.parse_args()

flatfile = args.resultfile
param = args.ioparam

# MACROS FOR DISLIN PLOT DEFINITIONS

data_samples = 180            # Num of data samples; max = total(csv rows)
plot_filetype = 'xwin'        # Type of plot file; xwin, pdf, jpeg, png
plot_color = 'RED'            # Plot color; red, yellow, blue; orange; magenta, white, green 
axes_pos_x = 450              # Position of axes of lower left corner - x co-ordinate
axes_pos_y = 1800             # Position of axes of lower left corner - y co-ordinate
axes_len_l = 2200             # Length of axes on x-side
axes_len_h = 1200             # Height of axes on y-side
x_axis_name = 'INTERVAL'      # Name of x-axis
y_axis_name = param.upper()   # Name of y-axis
x_step = 10                   # values b/w x-axis labels ; modify based on data_samples size
y_step = 1000                 # values b/w y-axis labels ; modify based on max value of param
x_axis_ticks = 600            # ticks b/w x-axis labels ; Resolution along x-axis
y_axis_ticks = 1000           # ticks b/w y-axis labels ; Resolution along y-axis

# GLOBAL VARIABLE FOR PARSED CSV NAME
parsedfile = '%s.csv' %(param)

def vdParser():
    
    # Perform the vdbench result parse using parseflat util 
    subprocess.call ("./vdbench parseflat -i %s -c %s -o %s" %(flatfile, param, parsedfile),  shell=True)
    
    # Removes header data from resulting csv, i.e., parse output
    subprocess.call ("sed -i -e '1d' %s" %(parsedfile), shell=True)
    
def vdProcessor():
    
    # Determine the total number of data points available - i.e., interval count
    intervalcount = subprocess.check_output ("cat %s | wc -l" %(parsedfile), shell=True)
    n = int(intervalcount)
    
    # Define values for the param plot's x-axis
    x = range(n)
    
    # Define values for the param plot's y-axis
    y = []
    
    with open(parsedfile, 'rU') as data:
        reader = csv.reader(data)
        for row in reader:
            for cell in row:
                cell = float(cell) 
                y.append(cell)

    # Add into numpy list for obtaining data essentials
    data = numpy.genfromtxt(parsedfile, dtype='float',usecols=0)
   
    # Get the min and max values of the numpy list, i.e., param values
    minVal = data.min()
    maxVal = data.max()
    avgVal = data.mean()

    print "The minimum %s observed in %s" %(param, minVal)
    print "The maximum %s observed is %s" %(param, maxVal)
    print "The average %s observed in %s" %(param, avgVal)

    statsDict = {'x-range': x, 'y-range': y, 'min-param': minVal, 'max-param': maxVal, 'mean-param': avgVal}
    return (statsDict) 
 
'''

def dislinPlot(xvals, yvals, ylimit):
    
    # Set the plot output file format 
    dislin.metafl (plot_filetype) 

    # Dislin routine initialization
    dislin.disini ()

    # Set the font type on graph
    dislin.complx ()

    # Set the Graph color
    dislin.color (plot_color) 

    # Fix the position of axes on graph area
    dislin.axspos (axes_pos_x,axes_pos_y) 

    # Fix the length of axes on graph area
    dislin.axslen (axes_len_l,axes_len_h) 

    # Set name of axes 
    dislin.name (x_axis_name, 'X') 
    dislin.name (y_axis_name, 'Y') 

    # Num of digits after decimal point ; "-2" refers automatic selection
    dislin.labdig (-2, 'X')

    # Num of ticks on axes b/w values
    dislin.ticks (x_axis_ticks,'X') 
    dislin.ticks (y_axis_ticks,'Y') 

    # Plot title text
    dislin.titlin ('y_axis_name vs x_axis_name', 1) 

    # Plot details; xlower., xupper., x1stlabel., xstep., ylower., yupper., y1stlabel., ystep
    dislin.graf (0., float(data_samples), 0., float(x_step), 0., float(ylimit), 0., float(y_step)) 

    # Write title on plot
    dislin.title()

    # Curve changes if called multiple times
    dislin.chncrv ('NONE')

    # Plot the Curve
    dislin.curve (xvals, yvals, data_samples)

    # Dislin routine conclusion
    dislin.disfin ()

'''

def main():
    # First Parse flatfile
    vdParser()
    # Second, Get vital i/o stats 
    processedDict = vdProcessor()
    # Create the plot
    # dislinPlot(processedDict["x-range"], processedDict["y-range"], processedDict["max-param"])

main()


