%lang starknet

from starkware.cairo.common.uint256 import Uint256, uint256_lt, uint256_eq, uint256_add, uint256_le
from openzeppelin.token.erc721_enumerable.library import (
    ERC721_Enumerable_mint,
    ERC721_Enumerable_totalSupply,
    ERC721_Enumerable_tokenOfOwnerByIndex,
    ERC721_balanceOf,
)
from openzeppelin.utils.constants import TRUE, FALSE
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.dict import DictAccess, squash_dict, dict_write
from starkware.cairo.common.default_dict import default_dict_new, default_dict_finalize

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
    let (_is_zero) = uint256_eq(start, stop)
    if _is_zero == TRUE:
        return (debts_len, debts)
    end
    _get_debts_loop{user=user, debts_len=debts_len, debts=debts, stop=stop}(start)
    return (debts_len, debts)
end

func Degensplit_get_group_balance{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(users_len : felt, users : felt*) -> (balances_len : felt, balances : DictAccess*):
    alloc_locals
    let (local balances_start) = default_dict_new(default_value=0)
    let balances = balances_start

    if users_len == 0:
        return (0, balances_start)
    end

    let start = 0
    _aggregate_users_lendings_loop{users_len=users_len, users=users, balances=balances}(start)

    let (finalized_balances_start, finalized_balances_end) = default_dict_finalize(
        balances_start, balances, 0
    )
    # TODO: check that values sum to 0
    return ((finalized_balances_end - finalized_balances_start) / DictAccess.SIZE, balances_start)
end

# Internals

func _get_debts_loop{
    user : felt,
    debts_len : felt,
    debts : Uint256*,
    stop : Uint256,
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(token_id : Uint256):
    let (_stop_iter) = uint256_le(stop, token_id)
    if _stop_iter == TRUE:
        return ()
    end

    let (token_data) = Degensplit_lendings.read(token_id)
    if token_data.borrower == user:
        assert [debts + debts_len * Uint256.SIZE] = token_id
        tempvar debts_len = debts_len + 1
        tempvar range_check_ptr = range_check_ptr
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
    else:
        tempvar debts_len = debts_len
        tempvar range_check_ptr = range_check_ptr
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
    end
    let (next_token_id, _) = uint256_add(token_id, Uint256(1, 0))
    _get_debts_loop(next_token_id)
    return ()
end

func _aggregate_user_lendings_loop{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
    user : felt,
    balances : DictAccess*,
    stop : Uint256,
}(index : Uint256):
    alloc_locals
    let (_stop_iter) = uint256_le(stop, index)
    if _stop_iter == TRUE:
        return ()
    end

    let (local token_id) = ERC721_Enumerable_tokenOfOwnerByIndex(user, index)
    let (local token_data) = Degensplit_lendings.read(token_id)
    # TODO: should take symbol into account here
    dict_write{dict_ptr=balances}(user, token_data.amount)
    dict_write{dict_ptr=balances}(token_data.borrower, -token_data.amount)

    let (_next_index, _) = uint256_add(index, Uint256(1, 0))
    _aggregate_user_lendings_loop(_next_index)

    return ()
end

func _aggregate_users_lendings_loop{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
    users_len : felt,
    users : felt*,
    balances : DictAccess*,
}(index : felt):
    if index == users_len:
        return ()
    end

    let user = users[index]

    let start = Uint256(0, 0)
    let (stop) = ERC721_balanceOf(user)
    _aggregate_user_lendings_loop{user=user, balances=balances, stop=stop}(start)
    _aggregate_users_lendings_loop(index + 1)

    return ()
end
