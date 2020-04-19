import os
import subprocess
from subprocess import Popen, PIPE

def get_container_stats():

    #capture container ID, container name
    cmd = "docker ps".split(" ")
    cmd_out = subprocess.check_output(cmd).strip()
    container_list = {}
    if len(cmd_out.split("\n")) == 1:
        return "No containers running"

    for line in cmd_out.split("\n")[1:]:
        container_list[line.split()[0]] = [line.split()[1],line.split()[-1]]
#    print container_list
    cmd1 = 'docker ps -q'.split(' ')
    cmd2 = 'xargs docker inspect --format "{{.State.Pid}},{{.ID}}"'.split(' ')

    #capture PID corresponding to container ID
    proc1 = Popen(cmd1, stdout=PIPE)
    proc2 = Popen(cmd2, stdin=proc1.stdout, stdout=PIPE)
    proc1.stdout.close()  
    output = proc2.communicate()[0].strip()
    proc2.stdout.close()  

    for line in output.split("\n"):
        container_list[line.split(',')[1][:12]].append(line.split(',')[0][1:])

#capture DRS and RSS for each PID
    for key in container_list:
        pid = container_list[key][2]
        cmd = 'ps v {}'.format(pid).split(" ")
        cmd_out = subprocess.check_output(cmd).strip()
        pid_stats = cmd_out.split("\n")[1].split()
        container_list[key].append({'DRS': pid_stats[6], 'RSS': pid_stats[7]})
#    for i in container_list:
#        print i,container_list[i]
    return container_list

def enable_checkpoint(container_name, checkpoint_name):
    cmd = "docker checkpoint create {} {}".format(container_name,checkpoint_name).split(" ")
    cmd_out = subprocess.check_output(cmd).strip()
    if cmd_out == checkpoint_name:
        return "Success"
    else:
        return "Failure"

if __name__ == "__main__":
    print get_container_stats()

