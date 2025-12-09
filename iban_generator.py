def generate_real_iban(bank_code="24001", account="00001234567"):
    # Once you have your official FIC from Bank of Lithuania
    pre = account + bank_code + "LT00"
    num = "".join(str(ord(c) - 55) if c.isalpha() else c for c in pre)
    check = 98 - (int(num) % 97)
    return f"LT{check:02d}{bank_code}{account}"
