import pytest
import pytest_asyncio
from nile.accounts import load
from starkware.starknet.compiler.compile import compile_starknet_files
from starkware.starknet.testing.starknet import Starknet, StarknetContract

from constants import CONTRACTS, PUBLIC_KEY

NETWORK = "127.0.0.1"
OWNER = int(next(load(str(PUBLIC_KEY), NETWORK))["address"], 16)
BORROWER = OWNER + 1


@pytest_asyncio.fixture(scope="session")
async def degensplit(starknet: Starknet) -> StarknetContract:
    return await starknet.deploy(
        contract_class=compile_starknet_files(
            [str(CONTRACTS["Degensplit"])],
            debug_info=True,
            disable_hint_validation=True,
        ),
        constructor_calldata=[
            int("Degensplit".encode().hex(), 16),
            int("DGSP".encode().hex(), 16),
            OWNER,
        ],
    )


@pytest.mark.asyncio
class TestDegensplit:
    class TestAddLending:
        @staticmethod
        async def test_should_mint_lending_token(degensplit: StarknetContract):
            balance_before = (await degensplit.balanceOf(OWNER).call()).result.balance
            amount = 10
            symbol = int("usd".encode().hex(), 16)
            await degensplit.addLending(BORROWER, amount, symbol).invoke(
                caller_address=OWNER
            )
            balance_after = (await degensplit.balanceOf(OWNER).call()).result.balance
            assert balance_after[0] == balance_before[0] + 1
            token_id = (
                await degensplit.tokenOfOwnerByIndex(OWNER, balance_before).call()
            ).result.tokenId
            token_data = (await degensplit.getLending(token_id).call()).result.tokenData
            assert token_data.borrower == BORROWER
            assert token_data.amount == amount
            assert token_data.symbol == symbol

    class TestGetDebts:
        @staticmethod
        async def test_should_return_user_debts(degensplit: StarknetContract):
            debts = (await degensplit.getDebts(BORROWER).call()).result.debts
            assert debts == [0]

    class TestGetGroupBalance:
        @staticmethod
        async def test_should_return_group_balance(degensplit: StarknetContract):
            symbol = int("usd".encode().hex(), 16)
            await degensplit.addLending(OWNER, 100, symbol).invoke(
                caller_address=BORROWER
            )
            group_balance = (
                await degensplit.getGroupBalance([OWNER, BORROWER]).call()
            ).result.balances
            assert len(group_balance) == 2
