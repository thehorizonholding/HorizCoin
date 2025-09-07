# Key Management (Draft)

Key Type | Purpose | Storage | Rotation
-------- | ------- | ------- | --------
Deployment | Initial contract deploy | Hardware wallet | One-time
Multisig Signers | Emergency / param changes | Hardware wallet | Quarterly / on compromise
Oracle Signing | Epoch report signatures | HSM / enclave (preferred) | Rolling / as needed
Governance Voter | Delegated voting | User-controlled | User discretion

Procedures:
1. Rotation: generate new key, update registry, sign handover message.
2. Compromise: revoke, publish incident, rotate threshold if required.
3. Audit Trail: maintain signed JSON log of key changes.