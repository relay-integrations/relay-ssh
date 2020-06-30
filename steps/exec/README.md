# ssh-step-exec

Executes commands over SSH

## Example

```
- name: ssh
  image: relaysh/ssh-step-exec
  spec:
    connection: !Connection {type: ssh, name: my-ssh-connection}
    username: relay
    port: 2222 # defaults to 22
    knownHosts: |
      server1.example.com ssh-rsa AAAAEXAMPLE
      server2.example.com ssh-rsa AAAANOTHEREXAMPLE
    # or
    #strictHostKeyChecking: false
    on:
    - server1.example.com
    - server2.example.com
    input:
    - whoami
    - uptime
    - cat /etc/passwd
```
