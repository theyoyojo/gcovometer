#!/bin/env python

# calculate which functions contains the most unsqueezed coverage juice (Potential Coverage Increase Index)
# PCII(function) = (100 - coverage(function)) * (lines(function)/lines(file))
#
# input: a covreport from the gcovometer and a filename
#
# When life gives you lemons, cover the source code in lemonade!

import argparse

parser = argparse.ArgumentParser(
                    prog='juice_detector',
                    description='Detects unsqueezed juice',
                    epilog='From the juice department')

filename=None
parser.add_argument('-f', '--filename', dest='covreport', help='filename containing coverage data', required=True)

class CoveredFunction:
    def __init__(self, name):
        self.funcname = name
        self.percent = None
        self.lines = None

    def __str__(self):
        return f'({self.funcname}, {self.percent}, {self.lines})'

class CoveredFile:
    def __init__(self):
        self.filename = None
        self.percent = None
        self.lines = None
        self.functions = []

    def __str__(self):
        return f'<{self.filename}, {self.percent}, {self.lines}, {[str(func) for func in self.functions]}>'

# get number from 'executed_percent:<FLOAT.2>%'
def percent_unpack(string):
        return float(string.split(':')[1].split('%')[0])

def get_covered_file_data(covreport):
    with open(covreport, 'r') as f:
        lines = [line.strip() for line in f.readlines()]
    covered_file = CoveredFile()
    function = None
    filename = None
    for i, line in enumerate(lines):
        match line.split():
            case ['Function', name]:
                function = name.split("'")[1]
            case ['File', name]:
                filename = name.split("'")[1]
            case ['Lines', executed_percent, 'of', func_lines] if function is not None:
                covered_function = CoveredFunction(function)
                covered_function.percent = percent_unpack(executed_percent)
                covered_function.lines = float(func_lines)
                covered_file.functions.append(covered_function)
                function = None
            case ['Lines', executed_percent, 'of', file_lines] if filename is not None:
                covered_file.filename = filename
                covered_file.percent = percent_unpack(executed_percent)
                covered_file.lines = float(file_lines)
                return covered_file

def main(args):
    covered_file = get_covered_file_data(args.covreport)
    for func in covered_file.functions:
        print(f'{func.funcname}\t{(100 - func.percent) * (func.lines/covered_file.lines)}')

if __name__ == '__main__':
    main(parser.parse_args())
