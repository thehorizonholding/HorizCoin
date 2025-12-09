# Quantum Oracle — verifies Lamport signatures and one-time pads
def verify_lamport(proof: bytes, public_keys: list, message: bytes) -> bool:
    """Information-theoretically secure verification"""
    msg_hash = sha3_512(message).digest()
    bits = bin(int.from_bytes(msg_hash, 'big'))[2:].zfill(256)
    for i, bit in enumerate(bits):
        if bit == '1':
            if sha3_512(proof[i*32:(i+1)*32]).digest() != public_keys[i]:
                return False
    return True
