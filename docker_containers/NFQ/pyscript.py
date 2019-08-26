from netfilterqueue import NetfilterQueue
import hashlib
import hmac
from ecdsa import SigningKey


def print_and_accept(pkt):
    '''
    m=hashlib.sha256(pkt.get_payload())
    m.digest()
    '''
    hmac.new('secret_key', pkt.get_payload(), hashlib.md5)
    #signature=sk.sign(pkt.get_payload())
    pkt.accept()

sk=SigningKey.generate()
nfqueue=NetfilterQueue()
nfqueue.bind(1,print_and_accept)
try:
    nfqueue.run()
except KeyboardInterrupt:
    print('Good-bye')

nfqueue.unbind()
