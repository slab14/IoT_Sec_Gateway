import os
import subprocess
from subprocess import Popen, PIPE
import csv

def get_base_scores():
    scores={}
    with open('critical_base_scores.csv') as csvfile:
        readCSV = csv.reader(csvfile,delimiter=',')
        for row in readCSV:
            scores[row[0]] = int(row[1])
    return scores

def get_container_stats():

    #capture container ID, container name
    cmd = "docker ps".split(" ")
    cmd_out = subprocess.check_output(cmd).strip()
    container_list = {}
    scores = get_base_scores()

    if len(cmd_out.split("\n")) == 1:
        return "No containers running"

    for line in cmd_out.split("\n")[1:]:
        split_line = line.split()
        container_id = split_line[0]
        image_name = split_line[1]
        cont_name = split_line[-1]
        container_list[container_id] = [('image_name',line.split()[1])]
        container_list[container_id].append(('cont_name',line.split()[-1]))
        container_list[container_id].append(('base_score',scores[image_name]))

    cmd1 = 'docker ps -q'.split(' ')
    cmd2 = 'xargs docker inspect --format "{{.State.Pid}},{{.ID}}"'.split(' ')

    #capture PID corresponding to container ID
    proc1 = Popen(cmd1, stdout=PIPE)
    proc2 = Popen(cmd2, stdin=proc1.stdout, stdout=PIPE)
    proc1.stdout.close()  
    output = proc2.communicate()[0].strip()
    proc2.stdout.close()  

    for line in output.split("\n"):
        container_id = line.split(',')[1][:12]
        pid = line.split(',')[0][1:]
        container_list[container_id].append(('pid',pid))
    #capture DRS and RSS for each PID
    for key in container_list:
        pid = container_list[key][3][1]
        cmd = 'ps v {}'.format(pid).split(" ")
        cmd_out = subprocess.check_output(cmd).strip()
        pid_stats = cmd_out.split("\n")[1].split()
        container_list[key].append(('DRS', pid_stats[6])) 
        container_list[key].append(('RSS', pid_stats[7]))

    return container_list

def enable_checkpoint(container_name, checkpoint_name):
    cmd = "docker checkpoint create {} {}".format(container_name,checkpoint_name).split(" ")
    cmd_out = subprocess.check_output(cmd).strip()
    if cmd_out == checkpoint_name:
        return "Success"
    else:
        return "Failure"

def restore_checkpoint(checkpoint_name,container_name):
    cmd = "docker start --checkpoint {} {}".format(checkpoint_name,container_name).split(" ")
    cmd_out = subprocess.check_output(cmd).strip()
    #cannot check success or failure since no output on terminal for either possibility
    return "Success"

if __name__ == "__main__":
    print get_base_scores()
    print get_container_stats()
