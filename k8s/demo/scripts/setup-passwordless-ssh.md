# Setting Up Passwordless SSH between Local and Remote Host

A passwordless SSH setup between a local and remote host can be completed in 3 easy steps:

### Step 1:

Create a SSH Key for a local user on local-host using **ssh-keygen**:

```
localuser@local-host$ [Note: You are on local-host here]

localuser@local-host$ ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/home/localuser/.ssh/id_rsa):[Enter key]
Enter passphrase (empty for no passphrase): [Press enter key]
Enter same passphrase again: [Pess enter key]
Your identification has been saved in /home/localuser/.ssh/id_rsa.
Your public key has been saved in /home/localuser/.ssh/id_rsa.pub.
The key fingerprint is:
33:b3:fe:af:95:95:18:11:31:d5:de:96:2f:f2:35:f9 localuser@local-host
```

### Step 2:

Copy the public key to the remote-host(preferably IPAddress) using **ssh-copy-id**:

```
localuser@local-host$ ssh-copy-id -i ~/.ssh/id_rsa.pub remoteuser@remote-host
remoteuser@remote-host's password:
Now try logging into the machine, with "ssh 'remote-host'", and check in:

.ssh/authorized_keys

to make sure we haven't added extra keys that you weren't expecting.
```

### Step 3:

Login to remote-host(preferably IPAddress) without entering the password.

```
localuser@local-host$ ssh remoteuser@remote-host
Last login: Sun Nov 16 17:22:33 2008 from 192.168.1.2
[Note: SSH did not ask for password.]

remoteuser@remote-host$ [Note: You are on remote-host here]
```