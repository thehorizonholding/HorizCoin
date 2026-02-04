import uuid
from tigerbeetle import Client, Account, Transfer, AccountFlags, CreateAccountError, CreateTransferError

# Connect to TigerBeetle cluster (replace with real addresses in production)
client = Client(cluster_id=0, replica_addresses=["3000"])  # e.g. "3000,3001,3002"

# Account code constants
VAULT_ACCOUNT_CODE = 1001          # Assets (vault / settlement)
CUSTOMER_DEPOSIT_CODE = 2001       # Liabilities (customer custody)

def create_account(account_id: int, code: int, ledger: int = 1) -> bool:
    """Create a single account with strict flags."""
    account = Account(
        id=account_id,
        user_data_128=0,
        user_data_64=0,
        user_data_32=0,
        ledger=ledger,
        code=code,
        flags=AccountFlags.LINKED if code == CUSTOMER_DEPOSIT_CODE else AccountFlags.DEBITS_MUST_NOT_EXCEED_CREDITS,
        debits_pending=0,
        debits_posted=0,
        credits_pending=0,
        credits_posted=0,
        timestamp=0
    )

    errors = client.create_accounts([account])
    if errors:
        for idx, err in errors:
            print(f"Account creation failed at index {idx}: {err}")
        return False
    return True

def create_large_deposit(vault_id: int, customer_id: int, amount_units: int):
    """Example: Deposit $100T scaled to 10^18 precision."""
    transfer = Transfer(
        id=uuid.uuid4().int,
        debit_account_id=vault_id,
        credit_account_id=customer_id,
        amount=amount_units,
        pending_id=0,
        user_data_128=0,
        user_data_64=0,
        user_data_32=0,
        timeout=0,
        ledger=1,
        code=10001,  # e.g. LARGE_DEPOSIT
        flags=0,
        timestamp=0
    )

    errors = client.create_transfers([transfer])
    if errors:
        for idx, err in errors:
            print(f"Transfer failed at index {idx}: {err}")
        return False
    
    print(f"Success: Transferred {amount_units} units from vault {vault_id} → customer {customer_id}")
    return True


# Example usage
if __name__ == "__main__":
    vault_id = uuid.uuid4().int
    customer_id = uuid.uuid4().int
    
    create_account(vault_id, VAULT_ACCOUNT_CODE)
    create_account(customer_id, CUSTOMER_DEPOSIT_CODE)
    
    # 100 trillion at 10^18 precision
    amount = 100_000_000_000_000 * 10**18
    create_large_deposit(vault_id, customer_id, amount)
