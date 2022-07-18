from pathlib import Path

CONTRACTS = {p.stem: p for p in list(Path("contracts").glob("*.cairo"))}
