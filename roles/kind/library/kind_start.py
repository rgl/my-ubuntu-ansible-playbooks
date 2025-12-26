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
module: kind_start
short_description: Start an existing kind cluster.
description:
  - Start an existing kind cluster.
options:
  name:
    description:
      - Name of the cluster.
    type: str
notes:
  - This requires the kind binary installed in the target host.
  - This requires the kubectl binary installed in the target host.
  - This requires the docker, kubernetes and yaml python libraries installed in the target host.
author:
  - Rui Lopes (ruilopes.com)
'''

EXAMPLES = '''
- name: Start cluster
  kind:
    name: kind
'''

RETURN = '''
'''


import time

import docker
import kubernetes
import yaml
from ansible.module_utils.basic import AnsibleModule


# see https://github.com/yaml/pyyaml/issues/234#issuecomment-765894586
class Dumper(yaml.Dumper):
  def increase_indent(self, flow=False, *args, **kwargs):
    return super().increase_indent(flow=flow, indentless=False)


class KindStart(AnsibleModule):
  def __init__(self):
    super(KindStart, self).__init__(
      argument_spec=dict(
        name=dict(type='str', required=True)),
      supports_check_mode=False)
    self.docker_client = docker.from_env()

  def main(self):
    container = self._get_container()
    if container:
      changed = self._start_cluster(container)
    else:
      changed = False
    self.exit_json(changed=changed)

  def _get_container(self):
    name = self.params['name']
    container_name = f'{name}-control-plane'
    containers = self.docker_client.containers.list(all=True, filters={'name':container_name})
    if len(containers) > 1:
      raise Exception(f'found more than one container named {container_name}')
    return containers[0] if len(containers) == 1 else None

  def _start_cluster(self, container):
    if container.status == 'running':
      return False
    container.start()
    self._wait_for_kubernetes(5*60)
    return True

  def _create_kubernetes_api_client(self):
    context_name = f"{self.params['name']}-kind"
    contexts, active_context = kubernetes.config.list_kube_config_contexts()
    if not contexts:
      raise Exception('cannot find any cluster in kubeconfig')
    for context in contexts:
      if context['name'] == context_name:
        return kubernetes.config.new_client_from_config(context=context_name)
    raise Exception('cannot find the cluster in kubeconfig')

  def _wait_for_kubernetes(self, timeout):
    kubernetes_client = kubernetes.client.CoreApi(api_client=self._create_kubernetes_api_client())
    start = time.monotonic()
    while True:
      if time.monotonic() - start > timeout:
        raise Exception('timeout while waiting for kubernetes to be available')
      try:
        kubernetes_client.get_api_versions()
        break
      except:
        # TODO to troubleshoot, log the exception to ansible.
        time.sleep(3)


def main():
    module = KindStart()
    module.main()


if __name__ == '__main__':
    main()
