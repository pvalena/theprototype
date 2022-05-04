#!/bin/bash

grep -r VERSION | grep -vE '^(test|spec|configure|ChangeLog|sample|compile|object|error|defs|random|bootstrap|tool|win32|common|doc|dln|enc|bignum|debug|benchmark)' | grep -E '\s*VERSION\s*=' | grep -vE '(\$|\_|\:|\_CON|\_MOD)VERSION' | grep -v '^lib/bundler/templates/' | grep -vE 'VERSION\s*=\s*(VERSION\_CODE|\/\\bversion)'
