# Flatten solidity source code
# Usage:
#
# python flatten.py --path contract_dir/target_contract.sol --include include_dir_1 --include include_dir_2
#

import argparse
import os
import sys
from pathlib import Path
from os.path import abspath
from typing import Tuple, List, Any, Optional, Set
# Duplicate pragma to be dropped
F_PRGAMA_ABICODER = 'abicoder'
F_PRGAMA_ABICODERV2 = 'ABIEncoderV2'
F_PRGAMA_SMTCHECKER = 'SMTChecker'

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.dirname(SCRIPT_DIR))

# Replace a SPDX license line
def replace_spdx(line=None) -> Optional[str]:
    return line and line.replace('SPDX-License', 'IGNORE_LICENSE') or None

get_file_name = lambda p: p.split(os.path.sep)[-1]

class FlattenError(ValueError):
    pass

def replace_pragma(seen_meta, prag, head, tail=None) -> Optional[str]:
    if tail and head == 'pragma' and prag in tail:
        if prag in seen_meta:
            return '//{} {}\n'.format(head, head)
        seen_meta.add(prag)
    return None

FlattenLine = Tuple[str, int, str]
FlattenSourceResult = List[FlattenLine]
def flatten(file_path: str, seen: Optional[Set[str]] = None, seen_meta=None, include_paths:str = []) -> str:
    '''
    Flatten a contract recursively. Return a list of tuple with three elements:
    - `file_path` path of current line
    - `linenum` the line numer in the file.
    - `line` the content of the line with the trailing line break

    Note all line numbers here are zero-based
    '''
    seen_meta = seen_meta or set()
    seen = seen or set()
    file_name = get_file_name(os.path.abspath(file_path))
    if file_name in seen:
        return []

    if not os.path.isfile(file_path):
        raise FlattenError(f'Target is not a file: {file_path}')

    if not file_path.lower().endswith('.sol'):
        raise FlattenError(f'Only solidity file is allowed: {file_path}')
    include_paths.append(abspath(os.path.join(Path(file_path).parent)))
    # NOTE here we assume same file name at different places on the file system represent the same file
    seen.add(file_name)
    content = []
    print ("file path ", file_path)
    # print ("include_paths ", include_paths)
    for linenum, line in enumerate(open(file_path, 'r')):
        segs = line.strip().split(maxsplit=1)
        if segs and segs[0] == 'import':
            quote = segs[1][0]
            if '{' in segs[1]:
                path = line.split('"')[-2].strip('"')
            else:
                path = segs[1][:-1].strip(quote)
            found_import = False
            if os.path.isfile(path):
                found_import = True
            print(f'{file_path} {path}')
            for include_path in include_paths:
                if os.path.isfile(include_path+'/'+path):
                    path = include_path + '/' + path
                    found_import = True
                    print(f'included path {file_path} {path}')
            if not found_import:
                raise FlattenError(f'Cannot find import file: {path}')
            path = abspath(os.path.join(Path(file_path).parent, path))
            content = content + flatten(path, seen, seen_meta, include_paths=include_paths)
        else:
            nline = segs and (replace_pragma(seen_meta, F_PRGAMA_ABICODER, *segs) or
                              replace_pragma(seen_meta, F_PRGAMA_ABICODERV2, *segs) or
                              replace_pragma(seen_meta, F_PRGAMA_SMTCHECKER, *segs) or
                              replace_spdx(line))
            nl = nline or line
            # a source code file can end without a line break, need to append one
            nl = nl if nl.endswith('\n') else f'{nl}\n'
            content.append((abspath(file_path), linenum, nl))
            # print('{:2d} {} {}'.format(linenum, nl, nl.endswith("\n")))
    return content

parser = argparse.ArgumentParser()
parser.add_argument('--path', type=str, help='The main contract to be flattened', required=True)
parser.add_argument('--include', action='append', help='The paths of included libraries to be flattened', required=False)
parser.add_argument('--output', type=str, default='./', help='The output path to write file', required=False)
args = parser.parse_args()

path = args.path
include_paths = args.include or []
for i in range(len(include_paths)):
    if include_paths[i][-1] == '/':
        include_paths[i] = include_paths[i][:-1]
print (include_paths)

if not os.path.exists(path):
    raise Exception(f'File not found {path}')

if not os.path.isfile(path):
    raise Exception(f'Target is not file {path}')

content = ''.join([nl for (_, _, nl) in flatten(path, include_paths = include_paths)])

filename = path.split(os.path.sep)[-1]
ext = filename.split('.')[-1]
output = args.output+filename[:-len(ext)-1] + '_flattened.' + ext

with open(output, 'w') as f:
    f.write(content)

print(f'Flattened file written to {output}')
