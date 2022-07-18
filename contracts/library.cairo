%lang starknet

from starkware.cairo.common.uint256 import Uint256, uint256_lt, uint256_eq, uint256_add
from openzeppelin.token.erc721_enumerable.library import (
    ERC721_Enumerable_mint,
    ERC721_Enumerable_totalSupply,
)
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc

# Structs
struct TokenData:
    member borrower : felt
    member amount : felt
    member symbol : felt
end

# Storage
@storage_var
func Degensplit_lendings(token_id : Uint256) -> (token_data : TokenData):
end

func Degensplit_get_lending{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (token_data : TokenData):
    let (token_data) = Degensplit_lendings.read(token_id)
    return (token_data)
end

# Expenses
func Degensplit_add_lending{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    borrower : felt, amount : felt, symbol : felt
):
    alloc_locals
    let (local token_id) = ERC721_Enumerable_totalSupply()
    let (owner) = get_caller_address()

    ERC721_Enumerable_mint(to=owner, token_id=token_id)
    let token_data = TokenData(borrower=borrower, amount=amount, symbol=symbol)

    Degensplit_lendings.write(token_id, token_data)
    return ()
end

func Degensplit_get_debts{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    user : felt
) -> (debts_len : felt, debts : felt*):
    alloc_locals
    let (local debts : Uint256*) = alloc()
    local debts_len = 0
    let start = Uint256(0, 0)
    let (stop) = ERC721_Enumerable_totalSupply()
    let (_is_zero) = uint256_eq(stop, Uint256(0, 0))
    if _is_zero == 1:
        return (debts_len, debts)
    end
    _get_debts_loop{user=user, debts_len=debts_len, debts=debts, stop=stop}(start)
    return (debts_len, debts)
end

func _get_debts_loop{
    user : felt,
    debts_len : felt,
    debts : Uint256*,
    stop : Uint256,
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(token_id : Uint256):
    let (_next_iter) = uint256_lt(token_id, stop)
    if _next_iter == 0:
        return ()
    end

    let (token_data) = Degensplit_lendings.read(token_id)
    if token_data.borrower == user:
        assert [debts] = token_id
        tempvar debts = debts + Uint256.SIZE
        tempvar debts_len = debts_len + 1
    else:
        tempvar debts = debts
        tempvar debts_len = debts_len
    end
    let (next_token_id, _) = uint256_add(token_id, Uint256(1, 0))
    _get_debts_loop(next_token_id)
    return ()
end
