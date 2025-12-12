# Generate Dilithium-5 + Kyber keys (production ready)
from oqs import KeyEncapsulation, Signature

kem = KeyEncapsulation("Kyber768")
sig = Signature("Dilithium5")

public_kem, secret_kem = kem.generate_keypair()
public_sig, secret_sig = sig.generate_keypair()

print("Quantum Public KEM:", public_kem.hex())
print("Quantum Private KEM:", secret_kem.hex())
print("Dilithium Public:", public_sig.hex())
