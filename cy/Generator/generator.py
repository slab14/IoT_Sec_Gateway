import re

in_driver = open("bohateidriver.c", "r") 
#in_mblib = open("bohateiipslib.c", "r")
#in_policy = open("In_Bohatei", "r") 
out_driver = open("driver.c", "w")
#out_mblib = open("bohateiips.c", "w")

for line in in_driver.readlines():
	out_driver.write(line)

# cleanup
in_driver.close()
out_driver.close()