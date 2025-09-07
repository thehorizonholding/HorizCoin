# Risk Register (Living Document)

ID | Category | Description | Impact | Likelihood | Mitigation | Owner | Status
-- | -------- | ----------- | ------ | ---------- | ---------- | ----- | ------
R-001 | Technical | Epoch signature validation bug | High | Medium | Fuzz + audits | Eng Lead | Open
R-002 | Economic | Emission misparameter -> oversupply | High | Low | Bounds + simulation | Tokenomics | Open
R-003 | Security | Oracle key compromise | High | Medium | HSM + rotation | Security | Open
R-004 | Governance | Delegate concentration | Medium | Medium | Delegation incentives | Governance | Open
R-005 | Operational | Single infra provider outage | Medium | Medium | Multi-region + failover | Ops | Open
R-006 | Regulatory | Forward-looking misstatements | High | Low | Comms policy enforcement | Compliance | Open
R-007 | Performance | Report aggregation latency spike | Medium | Medium | Benchmark + optimize | Eng | Open
R-008 | Data Integrity | Bandwidth spoofing via collusion | High | Medium | Multi vantage + outlier trim | Oracle | Open