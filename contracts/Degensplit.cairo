# Declare this file as a StarkNet contract.
%lang starknet

from openzeppelin.token.erc721_enumerable.ERC721_Enumerable_Mintable_Burnable import constructor
from openzeppelin.token.erc721.library import _exists
from openzeppelin.utils.constants import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.dict import DictAccess

from contracts.library import (
    Degensplit_add_lending,
    Degensplit_get_lending,
    Degensplit_get_debts,
    Degensplit_get_group_balance,
    TokenData,
)

@view
func getLending{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tokenId : Uint256
) -> (tokenData : TokenData):
    let (_token_exists) = _exists(tokenId)
    with_attr error_mesage("getLending: token does not exist"):
        assert _token_exists = TRUE
    end
    let (tokenData) = Degensplit_get_lending(tokenId)
    return (tokenData)
end

@external
func addLending{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    borrower : felt, amount : felt, symbol : felt
):
    Degensplit_add_lending(borrower, amount, symbol)
    return ()
end

@view
func getDebts{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(user : felt) -> (
    debts_len : felt, debts : felt*
):
    let (debts_len, debts) = Degensplit_get_debts(user)
    return (debts_len, debts)
end

@view
func getGroupBalance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    users_len : felt, users : felt*
) -> (balances_len : felt, balances : DictAccess*):
    let (balances_len, balances) = Degensplit_get_group_balance(users_len, users)
    return (balances_len, balances)
end
