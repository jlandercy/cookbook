#!/usr/bin/python3
# -*- coding: utf-8 -*-

import sys

from attacker import TwistedClass2

def deserialize(fname):
    import pickle
    
    with open(fname, "rb") as file:
        try:
            x = pickle.load(file)
            print("Unpickled {} {}".format(x, type(x)))
            return x
        except Exception as err:
            print("Error: {}".format(err))
            


def main():
    
    x1 = deserialize("TC1.pickle")
    x2 = deserialize("TC2.pickle")
    x3 = deserialize("TC3.pickle")
    
    
    sys.exit(0)
    
if __name__ == "__main__":
    main()
