#!/usr/bin/python
# -*- coding: utf-8 -*-

# ignore E111 indentation is not a multiple of 4.
# flake8: noqa: E111

# ignore E402 module level import not at top of file.
# flake8: noqa: E402

# ignore E501 line too long (96 > 88 characters).
# flake8: noqa: E501

DOCUMENTATION = """
---
module: self_signed_certificate
short_description: Manage a self-signed certificate
description:
  - Manage a self-signed certificate.
options:
  crt_path:
    description:
      - Path where to save the certificate.
    type: path
  key_path:
    description:
      - Path where to save the private key.
    type: path
  expiration_days:
    description:
      - Number of days the certificate is valid for.
      - The certificate will be rotated when it expires in less then 10 days.
    type: int
    default: 365
notes:
  - This requires the cryptography python library installed in the target host.
author:
  - Rui Lopes (ruilopes.com)
"""

EXAMPLES = """
- name: Create Gnome Remote Desktop Remote Login Certificate
  become: true
  become_user: gnome-remote-desktop
  self_signed_certificate:
    crt_path: ~/.local/share/gnome-remote-desktop/tls.crt
    key_path: ~/.local/share/gnome-remote-desktop/tls.key
    expiration_days: 365
"""

RETURN = """
crt_path:
  description:
    - Certificate path.
  returned: success
  type: path
key_path:
  description:
    - Private key path.
  returned: success
  type: path
"""


import datetime
import os
import platform

from ansible.module_utils.basic import AnsibleModule
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa


class SelfSignedCertificateModule(AnsibleModule):
    def __init__(self):
        super(SelfSignedCertificateModule, self).__init__(
            argument_spec=dict(
                crt_path=dict(type="path", required=True),
                key_path=dict(type="path", required=True),
                expiration_days=dict(type="int", default=365),
            ),
            supports_check_mode=False,
        )

    def main(self):
        crt_path = os.path.expanduser(self.params["crt_path"])
        key_path = os.path.expanduser(self.params["key_path"])
        expiration_days = self.params["expiration_days"]
        common_name = platform.node()
        now = datetime.datetime.now()
        change = False
        if not os.path.exists(crt_path):
            change = True
        else:
            with open(crt_path, "rb") as f:
                crt = x509.load_pem_x509_certificate(f.read())
            actual_common_names = crt.subject.get_attributes_for_oid(
                x509.NameOID.COMMON_NAME
            )
            if len(actual_common_names) != 1:
                change = True
            elif actual_common_names[0].value != common_name:
                change = True
            elif now >= crt.not_valid_after - datetime.timedelta(days=10):
                change = True
        if change:
            # see https://cryptography.io/en/41.0.7/x509/tutorial/#creating-a-self-signed-certificate
            subject = issuer = x509.Name(
                [x509.NameAttribute(x509.NameOID.COMMON_NAME, common_name)]
            )
            key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
            crt = (
                x509.CertificateBuilder()
                .subject_name(subject)
                .issuer_name(issuer)
                .public_key(key.public_key())
                .serial_number(x509.random_serial_number())
                .not_valid_before(now)
                .not_valid_after(now + datetime.timedelta(days=expiration_days))
                .sign(key, hashes.SHA256())
            )
            os.makedirs(os.path.dirname(key_path), exist_ok=True)
            fd = os.open(key_path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
            with open(fd, "wb") as f:
                f.write(
                    key.private_bytes(
                        encoding=serialization.Encoding.PEM,
                        format=serialization.PrivateFormat.TraditionalOpenSSL,
                        encryption_algorithm=serialization.NoEncryption(),
                    )
                )
            os.makedirs(os.path.dirname(crt_path), exist_ok=True)
            fd = os.open(crt_path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o644)
            with open(fd, "wb") as f:
                f.write(crt.public_bytes(serialization.Encoding.PEM))
        self.exit_json(changed=change, crt_path=crt_path, key_path=key_path)


def main():
    module = SelfSignedCertificateModule()
    module.main()


if __name__ == "__main__":
    main()
