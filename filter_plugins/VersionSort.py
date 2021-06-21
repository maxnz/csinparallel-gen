#!/usr/bin/python

from typing import List, Tuple

class FilterModule(object):
    def filters(self):
        return {
            'version_sort': self.version_sort
        }

    def version_tuple(self, version: str) -> Tuple[int, int, int]:
        v: List[str] = version.split('/')[-1].replace('.yaml', '').split('.')
        return int(v[0]), int(v[1]), int(v[2])

    def version_sort(self, versions):
        return sorted(versions, key = self.version_tuple)
        
