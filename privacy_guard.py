"""privacy_guard.py
Simple privacy guard that enforces consent, policy, and provenance checks.
In production, integrate with OPA (Open Policy Agent), a consent DB, and KMS/HSM.
"""
import hashlib, json, time

class PrivacyGuard:
    def __init__(self):
        # In real deployments, integrate with DB and policy engine
        self.allowed_recipients = set()  # populate from a consent manager
        self.max_data_types = {'metrics','telemetry','aggregates'}

    def register_consent(self, recipient_id):
        self.allowed_recipients.add(recipient_id)

    def verify_plan(self, plan):
        """Return (ok:bool, issues:list)"""
        issues = []
        for step in plan.get('steps', []):
            # Example: block any raw-data exports without explicit consent
            if step.get('type') == 'export' and step.get('data_type') not in self.max_data_types:
                issues.append(f"Export of disallowed data_type: {step.get('data_type')}")
            if step.get('recipient') and step.get('recipient') not in self.allowed_recipients:
                issues.append(f"Recipient {step.get('recipient')} has no consent record")
        return (len(issues) == 0, issues)

    def provenance_hash(self, artifact_bytes):
        h = hashlib.sha256(artifact_bytes).hexdigest()
        return h
