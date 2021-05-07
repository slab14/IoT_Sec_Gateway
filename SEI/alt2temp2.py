import math

"""
From P&FQ Toolbox                                                                      
Calculate temperature in R                                                             
(accurate up to 60,000 feet)
    Input:                                                                                
          h: Pressure alt (ft)
       mmHG: altimeter setting
    Output:                                                                               
          T: Temp (R) 
"""
def alt2temp(h, mmHg=29.92):
    if mmHg != 29.92:
        dh = ((8.95e10 * 288.15) /
              (-32.174 * 28.964) *
              math.log(mmHg / 29.92))
        h += dh
    To = 518.69
    if h > 36089:
        T = 389.99
    else:
        T = To * (1 - 6.87559e-6 * h)
    return T
