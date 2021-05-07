def alt2temp(h):
 """
From P&FQ Toolbox                                                                      
Calculate temperature in R                                                             
    Input :                                                                                
          h : Pressure altitude in feet                                                  
    Output :                                                                               
          T : Temperature in R (accurate up to 60,000 feet)                                 
"""
To = 518.69
if h > 36089:
    T = 389.99
else :
    T = To * (1 - 6.87559e-6 * h)
return T
