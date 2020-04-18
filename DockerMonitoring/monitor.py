import os
import subprocess
from subprocess import Popen, PIPE
cmd = "docker ps".split(" ")
cmd_out = subprocess.check_output(cmd).strip()
container_list = {}
for line in cmd_out.split("\n")[1:]:
    container_list[line.split()[0]] = [line.split()[1]]
#print container_list

cmd1 = 'docker ps -q'.split(' ')
cmd2 = 'xargs docker inspect --format "{{.State.Pid}},{{.ID}}"'.split(' ')
#cmd_out = subprocess.check_output(cmd, shell=True).strip(#)
#print cmd_out

proc1 = Popen(cmd1, stdout=PIPE)
proc2 = Popen(cmd2, stdin=proc1.stdout, stdout=PIPE)
proc1.stdout.close()  # Allow ps_process to receive a SIGPIPE if grep_process exits.
output = proc2.communicate()[0].strip()
proc2.stdout.close()  # Allow ps_process to receive a SIGPIPE if grep_process exits.

for line in output.split("\n"):
    container_list[line.split(',')[1][:12]].append(line.split(',')[0][1:])
#print container_list

for key in container_list:
    pid = container_list[key][1]
    cmd = 'ps v {}'.format(pid).split(" ")
    cmd_out = subprocess.check_output(cmd).strip()
    pid_stats = cmd_out.split("\n")[1].split()
    #0 is pid, 6 is DRS, 7 is RSS
#    print container_list[key]
#    print pid_stats[0],pid_stats[6],pid_stats[7]
    container_list[key].append({'DRS': pid_stats[6], 'RSS': pid_stats[7]})
#    print container_list[key]
for i in container_list:
    print i,container_list[i]
