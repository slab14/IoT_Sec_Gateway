from netfilterqueue import NetfilterQueue
import hashlib
import sha3
import hmac
from ecdsa import SigningKey
import binascii
from poly1305_aes import (get_key, authenticate, verify)
from Crypto.Hash import CMAC
from Crypto.Hash import MD2
from Crypto.Cipher import AES
from Crypto.Cipher import ARC2
import zlib
import umac

def Fletcher32(string):
    # Very slow implementation
    a = map(ord,string)
    b = [sum(a[:i])%65535 for i in range(len(a)+1)]
    return (sum(b) << 16) | max(b)

def print_and_accept(pkt):

    '''
    # Generate SHA_ hash of packet
    #m=hashlib.sha256(pkt.get_payload())
    m=hashlib.shake_128(pkt.get_payload())
    m.digest() #note, shake requires a size
    '''

    '''
    # Generate MD4/2 Hash
    MD2.new(pkt.get_payload())
    '''

    '''
    # Generate HMAC of packet or create signature. 
    hmac.new('secret_key', pkt.get_payload(), hashlib.sha1)
    #signature=sk.sign(pkt.get_payload())
    '''

    '''
    # Generate Poly1305
    #kr=get_key()
    kr='super_secret_key_0123456789_abcd'
    auth=authenticate(kr, pkt.get_payload())
    '''
    
    '''
    # Generate CMAC
    secret = b'Sixteen byte key'
    cobj = CMAC.new(secret, ciphermod=AES)
    cobj.update(pkt.get_payload())
    '''
    
    '''
    # Generate CRC32
    buf = (binascii.crc32(pkt.get_payload()) & 0xFFFFFFFF)
    '''

    '''
    # Generate adler32
    zlib.adler32(pkt.get_payload())
    '''
    
    '''
    # Generate Fletcher32
    buf = Fletcher32(pkt.get_payload())
    '''

    u = umac.umac('super_secret_key', 32)
    n = 'bcdefghi'
    x = pkt.get_payload()
    i = 0
    while ( (i+1) * 1024 < len(x) ):
        u.umacUpdate(x[i*1024:(i+1)*1024])
        i += 1
    tag = u.umacFinal(x[i*1024:], 8*len(x[i*1024:]), n)
    
    pkt.accept()


sk=SigningKey.generate()
nfqueue=NetfilterQueue()
nfqueue.bind(1,print_and_accept)
try:
    nfqueue.run()
except KeyboardInterrupt:
    print('Good-bye')

nfqueue.unbind()
