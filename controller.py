"""controller.py
Entrypoint for the private AI orchestrator add-on. Runs in dry-run by default.
This script orchestrates planning -> verify -> execute (dry) -> analyze.
It is intentionally conservative: no destructive actions by default.
"""
import argparse, os, json, time
from privacy_guard import PrivacyGuard
from revenue_optimizer import RevenueOptimizer
from multi_cloud_sync import MultiCloudSync
from analytics_engine import AnalyticsEngine

def main(mode='dry-run'):
    print("Horiz Private AI - controller starting (mode=%s)" % mode)
    pg = PrivacyGuard()
    ro = RevenueOptimizer()
    mcs = MultiCloudSync()
    ae = AnalyticsEngine()

    # Simple flow: discover -> plan -> verify -> simulate -> analyze
    nodes = mcs.discover_nodes()
    print(f"Discovered {len(nodes)} node(s)")

    plan = ro.create_plan(nodes, objective='maximize_yield', budget_usd=1000)
    print("Plan created:", json.dumps(plan, indent=2))

    ok, issues = pg.verify_plan(plan)
    if not ok:
        print("Plan blocked by privacy guard:", issues)
        return 1

    if mode == 'dry-run':
        print("DRY RUN: Simulating plan execution...")
        sim = mcs.simulate_plan(plan)
        print("Simulation result:", json.dumps(sim, indent=2))
    else:
        print("EXECUTE: applying plan (this will call safe connectors)")
        results = mcs.execute_plan(plan)
        print("Execution results:", json.dumps(results, indent=2))

    report = ae.analyze(plan, nodes)
    print("Analytics report:\n", json.dumps(report, indent=2))
    return 0

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--mode', choices=['dry-run','execute'], default='dry-run')
    args = parser.parse_args()
    exit(main(mode=args.mode))
