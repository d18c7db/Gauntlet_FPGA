#!/usr/bin/env python
import runpy, sys
sys.argv.append('--root=.')
sys.argv.append('--core=gauntlet')
sys.argv.append('--top=tb_gauntlet')
runpy.run_path('../../replay_common/scripts/common.py')