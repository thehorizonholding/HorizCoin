# Operations Runbook (Draft)

Incident Types:
1. Missed Epoch
2. Report Invalid / Rejected
3. Oracle Node Outage Cluster
4. Governance Misconfig
5. Key Compromise

Template:
- Detection Signal
- Owner
- Immediate Actions
- User Communication
- Escalation Path
- Postmortem Checklist

Example (Missed Epoch):
- Detection: Alert if no report after epoch_end + grace
- Action: Check oracle logs, verify committee liveness
- Escalation: Ops -> Security if second consecutive miss
- Communication: Status message if >2 missed