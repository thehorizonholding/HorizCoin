def generate_iban(country_code: str, bank_code: str, account_number: str) -> str:
    """Generate IBAN check digits (ISO 7064 Mod 97-10). For testing/simulation only."""
    country_code = country_code.upper()
    if len(country_code) != 2 or not country_code.isalpha():
        raise ValueError("Country code must be 2 letters")

    bban = (bank_code + account_number).replace(" ", "")
    temp = bban + country_code + "00"

    expanded = "".join(str(ord(c.upper()) - 55) if c.isalpha() else c for c in temp)
    remainder = int(expanded) % 97
    check = 98 - remainder

    return f"{country_code}{check:02d}{bban}"
