#!/usr/bin/env bash

# curl https://get.volta.sh | bash
# curl -L https://foundry.paradigm.xyz | bash

# node v18
# forge 0.2.0 (e488e2b 2023-07-10T15:17:42.605282000Z)

volta install || exit 127
forge --version || exit 127

npm install --install-strategy shallow
