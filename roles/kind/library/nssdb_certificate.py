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
module: nssdb_certificate
short_description: Manage the NSS certificate database
description:
  - Manage the NSS certificate database in ~/.pki/nssdb and in ~/snap/firefox/common/.mozilla/firefox/* (iif exists).
options:
  name:
    description:
      - Name of the certificate.
    type: str
  remote_src:
    description:
      - Path to the PEM encoded certificate to import into the nssdb.
    type: path
  trust:
    description:
      - Trust to apply to the certificate.
      - See trustargs at https://firefox-source-docs.mozilla.org/security/nss/legacy/tools/nss_tools_certutil/index.html
    type: str
notes:
  - This requires the certutil binary installed in the target host. This is normally provided by the libnss3-tools package.
  - See https://developer.mozilla.org/en-US/docs/Mozilla/Projects/NSS/Tools
  - See https://github.com/rgl/proxmox-ve-cluster-vagrant/blob/8e1530f74c716bf98b162d0fbca4872cb7d72d13/README.md?plain=1#L37-L55
author:
  - Rui Lopes (ruilopes.com)
'''

EXAMPLES = '''
- name: Trust the Kubernetes Ingress CA
  nssdb_certificate:
    name: talos Kubernetes Ingress CA
    remote_src: ~/.kube/talos-ingress-ca-crt.pem
    trust: C,,
'''

RETURN = '''
'''


import glob
import os
import os.path
import subprocess  # nosec B404

from ansible.module_utils.basic import AnsibleModule


class NssdbCertificate(AnsibleModule):
  def __init__(self):
    super(NssdbCertificate, self).__init__(
      argument_spec=dict(
        name=dict(type='str', required=True),
        remote_src=dict(type='path', required=True),
        trust=dict(type='str', required=True)),
      supports_check_mode=False)

  def main(self):
    name = self.params['name']
    remote_src = self.params['remote_src']
    trust = self.params['trust']
    changed = self._trust(name, remote_src, trust)
    self.exit_json(changed=changed, content=dict())

  def _trust(self, name, remote_src, trust):
    # see https://github.com/rgl/proxmox-ve-cluster-vagrant/blob/8e1530f74c716bf98b162d0fbca4872cb7d72d13/README.md?plain=1#L37-L55
    remote_src = os.path.expanduser(remote_src)
    # handle the default nssdb.
    nssdb_path = os.path.expanduser('~/.pki/nssdb')
    changed = self._trust_certificate(nssdb_path, name, remote_src, trust)
    # handle the firefox snap nssdb.
    # see https://bugs.launchpad.net/ubuntu/+source/chromium-browser/+bug/1859643
    for p in glob.glob(os.path.expanduser('~/snap/firefox/common/.mozilla/firefox/*/cert9.db')):
      nssdb_path = os.path.dirname(p)
      if self._trust_certificate(nssdb_path, name, remote_src, trust):
        changed = True
    return changed

  def _trust_certificate(self, nssdb_path, name, remote_src, trust):
    # ensure there is at most one certificate with the same name.
    changed = False
    exists = False
    for certificate_trust in self._list_certificates(nssdb_path, name):
      if certificate_trust == trust:
        result = self._run(
          'certutil',
          '-L',
          '-d', f'sql:{nssdb_path}',
          '-n', name,
          '-a')
        actual = result.stdout.strip()
        with open(remote_src) as f:
          expected = f.read().strip()
        if actual == expected:
          exists = True
          continue
      result = self._run(
        'certutil',
        '-D',
        '-d', f'sql:{nssdb_path}',
        '-n', name)
      changed = True
    if exists:
      return changed
    # add the certificate.
    if not os.path.exists(nssdb_path):
      os.makedirs(nssdb_path, mode=0o700)
    result = self._run(
      'certutil',
      '-A',
      '-d', f'sql:{nssdb_path}',
      '-n', name,
      '-i', remote_src,
      '-t', trust)
    return True

  def _list_certificates(self, nssdb_path, name):
    if not os.path.exists(nssdb_path):
      return
    result = self._run('certutil', '-L', '-d', f'sql:{nssdb_path}')
    for line in result.stdout.splitlines():
      parts = line.strip().rsplit(' ', maxsplit=1)
      if len(parts) != 2:
        continue
      certificate_name = parts[0].strip()
      certificate_trust = parts[1].strip()
      if certificate_name == name:
        yield certificate_trust

  def _run(self, *args):
    # TODO with check=True and when there is a non-zero exit code, the raised
    #      subprocess.CalledProcessError exception does not include
    #      stdout/stderr, which makes this impossible to troubleshoot, so we
    #      need to include that in the exception/log.
    return subprocess.run(args, check=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)


def main():
    module = NssdbCertificate()
    module.main()


if __name__ == '__main__':
    main()
