# **Complete Infrastructure Test Guide**

## **Test 1: User Data Script Completion**

**Command:**

```bash
sudo cat /var/log/user-data-completion.log
```

**Expected Output:**

```
User data script completed at Mon Dec 16 15:23:45 UTC 2024
Instance type: t3.medium, Instance ID: i-0abc123def456789
```

---

## **Test 2: Swap Status**

**Command:**

```bash
free -h
```

**Expected Output:**

```
               total        used        free      shared  buff/cache   available
Mem:           3.7Gi       488Mi       2.0Gi       2.7Mi       1.6Gi       3.3Gi
Swap:             0B          0B          0B
```

**What to look for:** `Swap: 0B 0B 0B` ✅

---

## **Test 3: Kernel Modules**

**Command:**

```bash
lsmod | grep -E "overlay|br_netfilter"
```

**Expected Output:**

```
br_netfilter           32768  0
bridge                176128  1 br_netfilter
overlay               151552  0
```

---

## **Test 4: Sysctl Network Settings**

**Commands:**

```bash
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.bridge.bridge-nf-call-ip6tables
sysctl net.ipv4.ip_forward
```

**Expected Output:**

```
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
```

---

## **Test 5: Inter-Node Connectivity (Run from Master)**

**Commands:**

```bash
# Get the private IPs first
terraform output worker_private_ip
terraform output gpu_worker_private_ip

# Then test ping (should work now with ICMP rules)
ping -c 3 <worker-private-ip>
ping -c 3 <gpu-worker-private-ip>
```

**Expected Output:**

```
PING 10.10.xxx.xxx (10.10.xxx.xxx) 56(84) bytes of data.
64 bytes from 10.10.xxx.xxx: icmp_seq=1 ttl=64 time=0.123 ms
64 bytes from 10.10.xxx.xxx: icmp_seq=2 ttl=64 time=0.145 ms
64 bytes from 10.10.xxx.xxx: icmp_seq=3 ttl=64 time=0.132 ms

--- 10.10.xxx.xxx ping statistics ---
3 packets transmitted, 3 received, 0% packet loss
```

---

## **Test 6: GPU Detection (GPU Worker Only)**

**Commands:**

```bash
# Test the fixed metadata service
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-type

# Look for NVIDIA hardware
lspci | grep -i nvidia
```

**Expected Output:**

```
g4dn.xlarge

00:1e.0 3D controller: NVIDIA Corporation TU104GL [Tesla T4] (rev a1)
```

---

## **Test 7: Hostname Verification**

**Command (on each node):**

```bash
hostname
```

**Expected Output (if user data worked):**

- **Master:** `your-repo-name-node-<node-id>`
- **Worker:** `your-repo-name-node-<node-id>`
- **GPU Worker:** `your-repo-name-gpu-worker`

---
