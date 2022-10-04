#!/usr/bin/python
# -*- coding: utf-8 -*-

DOCUMENTATION = '''
---
module: gnome_extension
short_description: Manage a GNOME extension.
description:
  - Manage a gnome_extension.
options:
  name:
    description:
      - Name, PK or UUID of the GNOME extension to manage.
    type: str
author:
  - Rui Lopes (ruilopes.com)
'''

EXAMPLES = '''
- name: Install Dash to Panel
  gnome_extension:
    # see https://extensions.gnome.org/extension/1160/dash-to-panel/
    # see https://github.com/home-sweet-gnome/dash-to-panel
    name: dash-to-panel@jderose9.github.com
'''

RETURN = '''
'''


# Notes
#
# * unattended extension management is an hassle.
#   * see https://gitlab.gnome.org/GNOME/gnome-shell/-/issues/2513
#   * see https://gitlab.gnome.org/GNOME/gnome-shell/-/issues/2689
#   * see https://github.com/mjakeman/extension-manager
# * gnome-extensions app:
#   * uses dbus to implement most of its features.
#   * see https://gitlab.gnome.org/GNOME/gnome-shell/-/tree/42.4/subprojects/extensions-tool/src
# * dbus org.gnome.Shell.Extensions.InstallRemoteExtension asks for the user
#   confirmation, so its not good for the unattended installation use-case.
#     ```python
#     import dbus
#     import json
#     import yaml
#     bus = dbus.SessionBus()
#     # see d-feet(1)
#     # see /usr/share/dbus-1/interfaces/org.gnome.Shell.Extensions.xml
#     shell_extensions_proxy = bus.get_object("org.gnome.Shell.Extensions", "/org/gnome/Shell/Extensions")
#     shell_extensions = dbus.Interface(shell_extensions_proxy, "org.gnome.Shell.Extensions")
#     # list known extensions.
#     extensions = json.loads(json.dumps(shell_extensions.ListExtensions()))
#     print(yaml.dump(extensions))
#     # install an extension.
#     # NB InstallRemoteExtension asks the user confirmation.
#     shell_extensions.InstallRemoteExtension('sensory-perception@HarlemSquirrel.github.io')
#     ```
# * this would allow the current session to be aware of the extension, but it does not seem to work:
#     ```python
#     shell_proxy = bus.get_object("org.gnome.Shell", "/org/gnome/Shell")
#     shell = dbus.Interface(shell_proxy, "org.gnome.Shell")
#     shell.Eval('''
#     const uuid = 'sensory-perception@HarlemSquirrel.github.io';
#     const dir = Gio.File.new_for_path(GLib.build_filenamev([
#         global.userdatadir, 'extensions', uuid]));
#     const extension = Main.extensionManager.createExtensionObject(
#         uuid, dir, ExtensionUtils.ExtensionType.PER_USER);
#     Main.extensionManager.loadExtension(extension);
#     ''')
#     ```


from ansible.module_utils.basic import AnsibleModule
import json
import os
import os.path
import re
import requests
import subprocess
import tempfile
from urllib.parse import urljoin


class GnomeExtension(AnsibleModule):
  def __init__(self):
    super(GnomeExtension, self).__init__(
      argument_spec=dict(
        name=dict(type='str', required=True)),
      supports_check_mode=False)

  def main(self):
    name = self.params['name']
    changed = False
    # get the extension uuid.
    shell_version = self._get_shell_version()
    if re.match(r'.+@.+', name):
      uuid = name
    else:
      # e.g. https://extensions.gnome.org/extension-query/?sort=uuid&page=1&shell_version=42.4&search=dash-to-panel
      response = requests.get('https://extensions.gnome.org/extension-query/', {
        'sort': 'uuid',
        'shell_version': shell_version,
        'search': name,
      })
      metadata = response.json()['extensions'][0]
      uuid = metadata['uuid']
    # get the extension latest metadata.
    # e.g. https://extensions.gnome.org/extension-info/?uuid=dash-to-panel@jderose9.github.com&shell_version=42.4
    response = requests.get('https://extensions.gnome.org/extension-info/', {
      'uuid': uuid,
      'shell_version': shell_version,
    })
    metadata = response.json()
    version = str(metadata['version'])
    # install.
    installed_version = self._get_installed_version(uuid)
    if installed_version != version:
      # download.
      download_url = urljoin(response.request.url, metadata['download_url'])
      response = requests.get(download_url)
      tmpf = tempfile.NamedTemporaryFile(delete=False)
      tmpf.write(response.content)
      tmpf.close()
      # install.
      args = [
        'gnome-extensions',
        'install',
        '--force',
        tmpf.name
      ]
      subprocess.run(args, check=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
      os.unlink(tmpf.name)
      changed = True
    # enable the extension.
    if self._extension_enable(uuid):
      changed = True
    if changed:
      self.warn('you must log out the GNOME session and log in again for changes to be applied')
    self.exit_json(changed=changed)

  def _get_installed_version(self, uuid):
    # NB we cannot use gnome-extensions info or list because it only shows
    #    loaded extensions, but we cannot force a load, so instead, this
    #    directly parses the metadata.json file and hopes for the best.
    #    see https://gitlab.gnome.org/GNOME/gnome-shell/-/issues/2513
    metadata_path = os.path.join(
      os.path.expanduser('~/.local/share/gnome-shell/extensions'),
      uuid,
      'metadata.json')
    if not os.path.exists(metadata_path):
      return None
    with open(metadata_path, 'r') as f:
      metadata = json.load(f)
    return str(metadata.get('version'))

  def _extension_enable(self, uuid):
    # NB this is not checking the exit code because running enable after an
    #    install does not work.
    #    see https://gitlab.gnome.org/GNOME/gnome-shell/-/issues/2513
    # bail when its already enabled.
    info = self._extension_info(uuid)
    if re.search(r'(?m)^\s*State: ENABLED$', info):
      return False
    # enable the extension.
    args = [
      'gnome-extensions',
      'enable',
      uuid
    ]
    subprocess.run(args, check=False, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return True

  def _extension_info(self, uuid):
    args = [
      'gnome-extensions',
      'info',
      uuid
    ]
    result = subprocess.run(args, check=False, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return result.stdout

  def _get_shell_version(self):
    args = [
      'gnome-shell',
      '--version']
    # TODO with check=True and when there is a non-zero exit code, the raised
    #      subprocess.CalledProcessError exception does not include
    #      stdout/stderr, which makes this impossible to troubleshoot, so we
    #      need to include that in the exception/log.
    result = subprocess.run(args, check=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    m = re.search(r'\s*(?P<major>\d+(\.\d+)+)\s*', result.stdout)
    if not m:
      raise 'failed to get the gnome version'
    return m.group('major')


def main():
    module = GnomeExtension()
    module.main()


if __name__ == '__main__':
    main()
