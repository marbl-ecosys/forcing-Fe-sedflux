#! /usr/bin/env python

import yaml

with open('environment.yml', 'r') as fid:
    deps = yaml.safe_load(fid)['dependencies']
    
deps_pip = []
for d in deps:
    if isinstance(d, dict):
        if 'pip' in d:
            deps_pip = d['pip']
            
if deps_pip:
    for d in deps_pip:
        print(d, end=' ')