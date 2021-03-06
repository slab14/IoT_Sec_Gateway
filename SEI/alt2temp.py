import numpy as np

"""
From P&FQ Toolbox                                                                      
Calculate temperature in R                                                             
(accurate up to 60,000 feet)
    Input :                                                                                
          h : Pressure alt (ft)
    Output :                                                                               
          T : Temp (R) 
"""
def alt2temp(h):
    To = 518.69
    if h > 36089:
        T = 389.99
    else:
        T = To * (1 - 6.87559e-6 * h)
    return T
