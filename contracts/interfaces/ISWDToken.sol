// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the SWDToken contract.
 */
interface ISWDToken is IERC20 {
    /**
    * @dev Constructor for initializing the SWDToken contract.
    * @param _swrToken - address of the SWRToken contract.
    * @param _settings - address of the Settings contract.
    * @param _pool - address of the Pool contract.
    */
    function initialize(address _swrToken, address _settings, address _pool) external;

    /**
    * @dev Function for retrieving the total deposits amount.
    */
    function totalDeposits() external view returns (uint256);

    /**
    * @dev Function for retrieving total deposit amount of the account.
    * @param account - address of the account to retrieve the deposit for.
    */
    function depositOf(address account) external view returns (uint256);

    /**
    * @dev Function for creating `amount` tokens and assigning them to `account`.
    * Can only be called by Pool contract.
    * @param account - address of the account to assign tokens to.
    * @param amount - amount of tokens to assign.
    */
    function mint(address account, uint256 amount) external;

    /**
    * @dev Function for removing `amount` tokens from `account`.
    * Can only be called by Pool contract.
    * @param account - address of the account to burn tokens from.
    * @param amount - amount of tokens to burn.
    */
    function burn(address account, uint256 amount) external;
}
