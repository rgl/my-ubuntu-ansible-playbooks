#!/usr/bin/python
# -*- coding: utf-8 -*-

DOCUMENTATION = '''
---
module: talos_cluster_docker
short_description: Manage a talos cluster in docker
description:
  - Manage a talos cluster in docker.
options:
  name:
    description:
      - Name of the cluster.
    type: str
  exposed_ports:
    description:
      - List of exposed ports.
      - Ports 0.0.0.0:6443->6443/tcp and 0.0.0.0:50000->50000/tcp are always exposed by talos regardless of what is defined in this property.
    type: list
    elements: str
notes:
  - When there is an error creating/starting the cluster, there is no attempt to recover/destroy it.
  - This will also modify your ~/.kube/config file by managing the admin@<name> cluster entry.
  - This requires the talosctl binary installed in the target host.
  - This requires the docker and kubernetes python libraries installed in the target host.
author:
  - Rui Lopes (ruilopes.com)
'''

EXAMPLES = '''
- name: Create cluster
  talos_cluster_docker:
    name: talos
    exposed_ports:
      - 32443:32443/tcp
'''

RETURN = '''
'''


from ansible.module_utils.basic import AnsibleModule
import docker
import kubernetes
import subprocess
import time


class TalosClusterDocker(AnsibleModule):
  def __init__(self):
    super(TalosClusterDocker, self).__init__(
      argument_spec=dict(
        name=dict(type='str', required=True),
        exposed_ports=dict(type='list', elements='str')),
      supports_check_mode=False)
    self.docker_client = docker.from_env()

  def main(self):
    name = self.params['name']
    container_name = f'{name}-master-1'

    containers = self.docker_client.containers.list(all=True, filters={'name':container_name})

    if len(containers) > 1:
      raise Exception(f'found more than one container named {container_name}')
    elif len(containers) == 1:
      changed = self._start_cluster(containers[0])
    else:
      changed = self._create_cluster()

    self.exit_json(changed=changed, content=dict())

  def _start_cluster(self, container):
    if container.status == 'running':
      # TODO reconfigure the container when it does not have the expected exposed_ports configuration.
      return False
    container.start()
    self._wait_for_kubernetes(5*60)
    return True

  def _create_cluster(self):
    name = self.params['name']
    exposed_ports = self.params['exposed_ports']
    args = [
      'talosctl',
      'cluster',
      'create',
      f'--name={name}',
      f'--exposed-ports={",".join(exposed_ports)}',
      '--workers=0',
      '--with-kubespan=false',
      '--with-cluster-discovery=false']
    # TODO with check=True and when there is a non-zero exit code, the raised
    #      subprocess.CalledProcessError exception does not include
    #      stdout/stderr, which makes this impossible to troubleshoot, so we
    #      need to include that in the exception/log.
    subprocess.run(args, check=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    self._wait_for_kubernetes(25*60)
    return True

  def _create_kubernetes_client(self):
    context_name = f"admin@{self.params['name']}"
    contexts, active_context = kubernetes.config.list_kube_config_contexts()
    if not contexts:
      raise Exception('cannot find any cluster in kubeconfig')
    for context in contexts:
      if context['name'] == context_name:
        return kubernetes.client.CoreApi(api_client=kubernetes.config.new_client_from_config(context=context_name))
    raise Exception('cannot find the cluster in kubeconfig')

  def _wait_for_kubernetes(self, timeout):
    kubernetes_client = self._create_kubernetes_client()
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
    module = TalosClusterDocker()
    module.main()


if __name__ == '__main__':
    main()
