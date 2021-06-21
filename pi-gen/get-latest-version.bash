#!/bin/bash

git clone https://gitlab+deploy-token-12:sErpRQP96JzfVponpBh-@stogit.cs.stolaf.edu/hd-image/hd-image.git .getversion > /dev/null

(
cd .getversion || exit 1
git checkout $1 > /dev/null

FILES=$(ls updates/*.yaml | sed 's|updates/||g' | sed 's/\(.*\)/"\1"/g' | tr '\n' ',')

python3 << EOF
from typing import List, Tuple

def version_tuple(version: str) -> Tuple[int, int, int]:
    v: List[str] = version.split('/')[-1].replace('.yaml', '').split('.')
    return int(v[0]), int(v[1]), int(v[2])

def version_sort(versions):
    return sorted(versions, key = version_tuple)
        
print(version_sort([$FILES])[-1][:-5])
EOF
)

rm -rf .getversion
