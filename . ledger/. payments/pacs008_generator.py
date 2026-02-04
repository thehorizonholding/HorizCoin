from lxml import etree
import uuid
from datetime import datetime, timezone
from decimal import Decimal
from typing import Optional

def generate_pacs_008(
    sender_iban: str,
    receiver_iban: str,
    amount: Decimal,
    currency: str = "USD",
    end_to_end_id: Optional[str] = None,
    remittance_info: Optional[str] = None,
    settlement_method: str = "INST"
) -> bytes:
    nsmap = {None: "urn:iso:std:iso:20022:tech:xsd:pacs.008.001.08"}
    root = etree.Element("Document", nsmap=nsmap)
    fitofi = etree.SubElement(root, "FIToFICstmrCdtTrf")

    # Group Header
    grp_hdr = etree.SubElement(fitofi, "GrpHdr")
    etree.SubElement(grp_hdr, "MsgId").text = str(uuid.uuid4())
    etree.SubElement(grp_hdr, "CreDtTm").text = datetime.now(timezone.utc).isoformat(timespec='seconds')
    etree.SubElement(grp_hdr, "NbOfTxs").text = "1"
    etree.SubElement(grp_hdr, "CtrlSum").text = f"{amount:.2f}"

    sttlm_inf = etree.SubElement(grp_hdr, "SttlmInf")
    etree.SubElement(sttlm_inf, "SttlmMtd").text = settlement_method

    # Transaction
    tx = etree.SubElement(fitofi, "CdtTrfTxInf")
    pmt_id = etree.SubElement(tx, "PmtId")
    etree.SubElement(pmt_id, "InstrId").text = f"INST-{uuid.uuid4().hex[:8]}"
    etree.SubElement(pmt_id, "EndToEndId").text = end_to_end_id or f"E2E-{uuid.uuid4().hex[:12]}"
    etree.SubElement(pmt_id, "TxId").text = str(uuid.uuid4())

    instd_amt = etree.SubElement(tx, "InstdAmt", Ccy=currency)
    instd_amt.text = f"{amount:.2f}"

    # Debtor
    dbtr = etree.SubElement(tx, "Dbtr")
    etree.SubElement(dbtr, "Nm").text = "Sender Name"
    dbtr_acct = etree.SubElement(tx, "DbtrAcct")
    etree.SubElement(etree.SubElement(dbtr_acct, "Id"), "IBAN").text = sender_iban

    # Creditor
    cdtr = etree.SubElement(tx, "Cdtr")
    etree.SubElement(cdtr, "Nm").text = "Receiver Name"
    cdtr_acct = etree.SubElement(tx, "CdtrAcct")
    etree.SubElement(etree.SubElement(cdtr_acct, "Id"), "IBAN").text = receiver_iban

    if remittance_info:
        rmt_inf = etree.SubElement(tx, "RmtInf")
        etree.SubElement(rmt_inf, "Ustrd").text = remittance_info[:140]

    return etree.tostring(root, pretty_print=True, xml_declaration=True, encoding="UTF-8")
