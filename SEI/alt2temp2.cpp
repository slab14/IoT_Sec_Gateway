#include <stdio.h>
#include <math.h>

/*
 * From P&FQ Toolbox                                                                      
 * Calculate temperature in R
 * (accurate up to 60,000 feet)                                 
 *     Input:
 *        h : Pressure alt (ft)                                                  
 *     Output:
 *        T : Temp (R) 
*/
float alt2temp(float h){
  float T;
  float To = 518.69;
  if (h > 36089) {
      T = 389.99;
    }
  else {
    T = To * (1 - 6.87559e-6 * h);
  }
  return T;
}

float alt2temp(float h, float mmHg){
  float T;
  float To = 518.69;
  float dh;
  if (mmHg != 29.92) {
    dh = ((8.95e10 * 288.15) /
	  (-32.174 * 28.964) *
	  log(mmHg / 29.92));
    h += dh;
  }
  if (h > 36089) {
      T = 389.99;
    }
  else {
    T = To * (1 - 6.87559e-6 * h);
  }
  return T;
}
