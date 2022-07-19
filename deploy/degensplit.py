import json
import logging
from pathlib import Path

import pandas as pd
from caseconverter import snakecase
from nile.common import ABIS_DIRECTORY, CONTRACTS_DIRECTORY
from nile.nre import NileRuntimeEnvironment

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def run(nre: NileRuntimeEnvironment) -> None:

    # TODO: fix nile doesn't manage to load env variables
    # owner = nre.get_or_deploy_account("PRIVATE_KEY").address
    owner = "0x020d288374979f57461740ae89f4c954c9e69d802cfa48760ab32534e17179ef"

    contract_name = "Degensplit"
    alias = snakecase(contract_name)
    arguments = [
        "0x" + "Degensplit".encode().hex(),
        "0x" + "DGSP".encode().hex(),
        owner,
    ]

    contract_file = next(Path(CONTRACTS_DIRECTORY).glob(f"{contract_name}.cairo"))
    abi_file = Path(ABIS_DIRECTORY) / f"{contract_name}.json"
    prev_abi = {}
    try:
        address, _ = nre.get_deployment(alias)
        logger.info(
            f"Contract {contract_name} already deployed, checking differences..."
        )
        # TODO: we should pull the abi from the address to check if it changed
        # prev_abi = fetch_abi(address)
    except StopIteration:
        logger.info(f"No deployment found for contract {contract_name}")

    logger.info(f"Compiling contract {contract_name}...")
    nre.compile([contract_file])

    new_abi = json.load(open(abi_file))
    if new_abi != prev_abi:
        if prev_abi != {}:
            logger.info(f"Contract {contract_name} has changed, redeploying...")

        file = f"{nre.network}.deployments.txt"
        (
            pd.read_csv(file, names=["address", "abi", "alias"], sep=":")
            .loc[lambda df: df.alias != alias]  # type: ignore
            .to_csv(file, sep=":", index=False, header=False)
        )
        address, _ = nre.deploy(
            contract_name,
            alias=alias,
            arguments=arguments,
        )
        logger.info(f"Deployed {contract_name} at {address} in network {nre.network}")
    else:
        logger.info(f"Contract {contract_name} is up to date, skipping...")
