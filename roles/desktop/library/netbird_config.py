#!/usr/bin/python
# -*- coding: utf-8 -*-

# ignore E111 indentation is not a multiple of 4.
# flake8: noqa: E111

# ignore E402 module level import not at top of file.
# flake8: noqa: E402

# ignore E501 line too long (96 > 88 characters).
# flake8: noqa: E501

DOCUMENTATION = '''
---
module: netbird_config
short_description: Manage the NetBird configuration.
description:
  - Manage the NetBird configuration.
options:
  iface_black_list_include:
    description:
      - Name of the interface to include in the interfaces excluded from the NetBird configuration.
    type: list
    elements: str
author:
  - Rui Lopes (ruilopes.com)
'''

EXAMPLES = '''
- name: Configure NetBird
  netbird_config:
    iface_black_list_include:
      - dns0
'''

RETURN = '''
'''


import json
import os
import os.path
import tempfile

from ansible.module_utils.basic import AnsibleModule


class NetBirdConfig(AnsibleModule):
  def __init__(self):
    super(NetBirdConfig, self).__init__(
      argument_spec=dict(
        iface_black_list_include=dict(type='list', elements='str')),
      supports_check_mode=False)

  def main(self):
    iface_black_list_include = self.params['iface_black_list_include']
    changed = False
    config_path = '/etc/netbird/config.json'
    if not os.path.exists(config_path):
      self.exit_json(changed=changed)
      return
    with open(config_path, 'r') as f:
      config = json.load(f)
    iface_black_list = config.get('IFaceBlackList', [])
    missing_ifaces = [iface for iface in iface_black_list_include if iface not in iface_black_list]
    if missing_ifaces:
      iface_black_list.extend(missing_ifaces)
      config['IFaceBlackList'] = iface_black_list
      changed = True
    if changed:
      with tempfile.NamedTemporaryFile('w', encoding='utf8', prefix='config.json.', suffix='.tmp', delete=False, dir=os.path.dirname(config_path)) as f:
        json.dump(config, f, indent=4)
        f.close()
        os.rename(f.name, config_path)
    self.exit_json(changed=changed)


def main():
    module = NetBirdConfig()
    module.main()


if __name__ == '__main__':
    main()
