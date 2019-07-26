import socket
import threading
import daemon
import re
import subprocess
import os.path

def tpm_create_primary():
    subprocess.check_call(['tpm2_createprimary', '-H', 'o', '-g', 'sha256', '-G', 'rsa', '-C', '/home/pi/tpmData/primary.ctx'])

def tpm_create():
    subprocess.check_call(['tpm2_create', '-C', '/home/pi/tpmData/primary_ctx', '-g', 'sha256', '-G', 'keyedhash', '-A', '"userwithauth|restricted|sign|fixedtpm|fixedparent|sensitivedataorigin"', '-u', '/home/pi/tpmData/key.pub', '-r', '/home/pi/tpmData/key.priv'])

def tpm_load():
    subprocess.check_call(['tpm2_load', '-C', '/home/pi/tpmeData/primary_ctx', '-u', '/home/pi/tpmData/key.pub', '-r', '/home/pi/tpmData/key.priv', '-c', '/home/pi/tpmData/key.ctx'])

def tpm_quote(pcr, nonce=None):
    if nonce:
        subprocess.check_call(['tpm2_quote', '-C', '/home/pi/tpmData/key_ctx', '-g', 'sha256', '-L', pcr, '-q', nonce, '-m', '/home/pi/tpmData/quote/message', '-s', '/home/pi/tpmData/quote/sig'])
    else:
        subprocess.check_call(['tpm2_quote', '-C', '/home/pi/tpmData/key_ctx', '-g', 'sha256', '-L', pcr, '-m', '/home/pi/tpmData/quote/message', '-s', '/home/pi/tpmData/quote/sig'])

def handle_client(sock, address, controller_address):
    if address[0] != controller_address:
        sock.close()
        exit()
    data=sock.recv(1024)
    if re.match('GetQuote', data):
        sock.sendall(data)
        with open('/home/pi/file.txt', 'a') as f:
            f.write("received: \n")
            f.write(data)
            f.write("\n***********\n")
            tpm2_quote('sha256:16') #TODO add avility to imput nonce (could even start by using port--address[1]
            with open('/home/pi/tpmData/quote/message', 'r') as f:
                message=f.read()
            with open('/home/pi/tpmData/quote/sig', 'r') as f:
                sig=f.read()
            sock.sendall(message+'\r\n\x00\r\n'+sig)
    sock.close()
    exit()

def serve_forever():
    server=socket.socket()
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('', 12345))
    server.listen(1)
    while True:
        conn, address = server.accept()
        thread = threading.Thread(target=handle_client, args=[conn, address, '10.10.10.10'])
        thread.daemon = True
        thread.start()

with daemon.DaemonContext():
    if not os.path.isfile('/home/pi/tpmData/primary.ctx'):
        tpm2_create_primary()
    if not os.path.isfile('/home/pi/tpmData/key.ctx'):
        tpm2_create()        
        tpm2_load() 
    server_forever()
