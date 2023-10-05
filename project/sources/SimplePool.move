module project::pool {

    use aptos_std::coin::{Self, Coin};
    use aptos_std::vector;
    use aptos_std::signer;
    use aptos_std::timestamp::{now_seconds};


    struct PoolInfo has key {
        underlying_asset: vector<u8>,
        total_deposits: u64,
        interest_rate: u8,
        totoal_borrowed: u64,
    }

    const PRECISION: u64 = PRECISION;

    const ERR_POOL_NOT_THERE: u64 = 1;
    const ERR_USER_NOT_THERE: u64 = 2;
    const ERR_USER_BAL: u64 = 3;
    const ERR_DEBT_NOT_ZERO: u64 = 4;
    const ERR_DEBT_AMOUNT_ERR: u64 = 5;

    struct UserInfo has key {
        total_deposits: u64,
        total_borrowed: u64,
        health_factor: u64,
    }

    public fun init_pool(asset: vecotr<u8>, interest: u8) {
        let balance = 0;
        move_to(@project, PoolInfo {asset, balance, interest, balance});
    }

    public fun supply(account: &signer, amount: u64) {
        let pool_info = borrow_global_mut<PoolInfo>(@project);

        let pool_there = exists<PoolInfo>(@project);
        assert!(pool_there, ERR_POOL_NOT_THERE);

        pool_info.total_deposits = pool_info.total_deposits + amount;

        if(exists<UserInfo>(account)) {
            let user_info = borrow_global_mut<UserInfo>(account);

            user_info.total_deposits = user_info.total_deposits + amount;
            if(user_info.total_borrowed == 0){
                user_info.health_factor = PRECISION;
            } else {
                user_info.health_factor = (
                    user_info.total_borrowed / user_info.total_deposits
                ) * PRECISION;
            }
        } else {

            let zero_balance: u64 = 0;
            move_to<UserInfo>(account, UserInfo{
                amount,
                zero_balance,
                zero_balance
            });
        };
    }

    public fun borrow(account: &signer, amount: u64) {
        let user_exists = exists<UserInfo>(account);
        assert!(user_exists, ERR_USER_NOT_THERE);
        let user_info = borrow_global_mut<UserInfo>(account);

        let bal_not_zero: bool = user_info.total_deposits != 0;

        assert!(bal_not_zero, ERR_USER_BAL);

        let pool = borrow_global_mut<PoolInfo>(@project);

        let heath_after = (
            (
                user_info.total_borrowed + amount
            ) / user_info.total_deposits
        ) * PRECISION;

        assert!(health_factor > 5);

        user_info.health_factor = heath_after;

        pool.total_borrowed = pool.total_borrowed + amount;
        user .total_borrowed = user.total_borrowed + amount;
    }

    public fun repay(account: & signer, amount: u64) {
        let user_exists = exists<UserInfo>(account);
        assert!(user_exists, ERR_USER_NOT_THERE);
        let user_info = borrow_global_mut<UserInfo>(account);

        let debt_not_zero: bool = user_info.total_borrowed != 0;
        assert!(debt_not_zero, ERR_DEBT_NOT_ZERO);
        assert!(amount <= user_info.total_borrowed, ERR_DEBT_AMOUNT_ERR);
        user .total_borrowed = user.total_borrowed - amount;

        if ((user_info.total_borrowed - amount) == 0) {
            user_info.health_factor = PRECISION;
        } else {
            user_info.health_factor = (
                (
                    user_info.total_borrowed - amount
                ) / user_info.total_deposits
            ) * PRECISION ;
        };

        let pool = borrow_global_mut<PoolInfo>(@project);
        pool.total_borrowed = pool.total_borrowed - amount;

    }

    public fun withdraw(account: &signer, amount: u64) {
        let user_exists = exists<UserInfo>(account);
        assert!(user_exists, ERR_USER_NOT_THERE);
        let user_info = borrow_global_mut<UserInfo>(account);

        if (user_info.total_borrowed == 0) {
            assert!(amount <= user.total_deposits, ERR_USER_BAL);
            user_info.total_deposits = user_info.total_deposits - amount;
        } else {
            assert!(amount <= user_info.total_deposits - user_info.total_borrowed, ERR_USER_BAL);
            user_info.health_factor = (user_info.total_borrowed/ (user_info.total_deposits - amount)) * 100; 
            user_info.total_deposits = user_info.total_deposits - amount;
        };
        let pool_info = borrow_global_mut<PoolInfo>(@project);
        pool_info.total_deposits = pool_info.total_deposits + amount;

    }

}