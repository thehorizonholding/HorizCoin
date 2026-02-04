import xml.etree.ElementTree as ET
from decimal import Decimal
from typing import Dict, Any

class ReconciliationError(Exception):
    pass

def reconcile_camt053(xml_content_or_path: str, currency: str = "USD") -> Dict[str, Any]:
    # Load XML (file or string)
    if xml_content_or_path.endswith('.xml'):
        tree = ET.parse(xml_content_or_path)
    else:
        root = ET.fromstring(xml_content_or_path)
        tree = ET.ElementTree(root)

    root = tree.getroot()
    ns = {'ns': 'urn:iso:std:iso:20022:tech:xsd:camt.053.001.02'}

    summary = {"total_entries": 0, "issues": [], "drift": Decimal("0.00")}

    for stmt in root.findall('.//ns:Stmt', ns):
        for ntry in stmt.findall('.//ns:Ntry', ns):
            summary["total_entries"] += 1

            amt_elem = ntry.find('ns:Amt', ns)
            if not amt_elem:
                continue

            try:
                amount = Decimal(amt_elem.text.strip())
            except:
                summary["issues"].append("Invalid amount")
                continue

            ccy = amt_elem.get('Ccy', 'unknown')
            cd_dbt = ntry.find('ns:CdtDbtInd', ns)
            direction = cd_dbt.text if cd_dbt is not None else None

            if direction not in ("CRDT", "DBIT"):
                continue

            signed = amount if direction == "CRDT" else -amount
            summary["drift"] += signed

            # In real code: match against TigerBeetle using AcctSvcrRef / EndToEndId
            ref = ntry.find('ns:AcctSvcrRef', ns)
            ref_text = ref.text if ref is not None else "no-ref"

            print(f"Entry: {signed:+.2f} {ccy}  | Ref: {ref_text}")

    if abs(summary["drift"]) > Decimal("0.01"):
        raise ReconciliationError(f"Drift detected: {summary['drift']:+.2f}")

    return summary
