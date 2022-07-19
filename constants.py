import os
from pathlib import Path

from dotenv import load_dotenv
from starkware.crypto.signature.signature import private_to_stark_key

load_dotenv()
CONTRACTS = {p.stem: p for p in list(Path("contracts").glob("*.cairo"))}

PUBLIC_KEY = private_to_stark_key(int(os.environ["PRIVATE_KEY"]))
