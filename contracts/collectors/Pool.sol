// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "../interfaces/ISWDToken.sol";
import "../interfaces/ISettings.sol";
import "../interfaces/IValidatorRegistration.sol";
import "../interfaces/IOperators.sol";
import "../interfaces/IValidators.sol";

/**
 * @title Pool
 *
 * @dev Pool contract accumulates deposits from the users, mints tokens and register validators.
 */
contract Pool is Initializable {
    using SafeMath for uint256;
    using Address for address payable;

    // @dev Total amount collected.
    uint256 public collectedAmount;

    // @dev ID of the pool.
    bytes32 private poolId;

    // @dev Address of the VRC (deployed by Ethereum).
    IValidatorRegistration public validatorRegistration;

    // @dev Address of the SWDToken contract.
    ISWDToken private swdToken;

    // @dev Address of the Settings contract.
    ISettings private settings;

    // @dev Address of the Operators contract.
    IOperators private operators;

    // @dev Address of the Validators contract.
    IValidators private validators;

    /**
    * @dev Constructor for initializing the Pool contract.
    * @param _swdToken - address of the SWDToken contract.
    * @param _settings - address of the Settings contract.
    * @param _operators - address of the Operators contract.
    * @param _validatorRegistration - address of the VRC (deployed by Ethereum).
    * @param _validators - address of the Validators contract.
    */
    function initialize(
        ISWDToken _swdToken,
        ISettings _settings,
        IOperators _operators,
        IValidatorRegistration _validatorRegistration,
        IValidators _validators
    )
        public initializer
    {
        swdToken = _swdToken;
        settings = _settings;
        operators = _operators;
        validatorRegistration = _validatorRegistration;
        validators = _validators;
        // there is only one pool instance, the ID is static
        poolId = keccak256(abi.encodePacked(address(this)));
    }

    /**
    * @dev Function for adding deposits to the pool.
    * The depositing will be disallowed in case `Pool` contract is paused in `Settings` contract.
    */
    function addDeposit() external payable {
        require(msg.value > 0 && msg.value.mod(settings.minDepositUnit()) == 0, "Pool: invalid deposit amount");
        require(msg.value <= settings.maxDepositAmount(), "Pool: deposit amount is too large");
        require(!settings.pausedContracts(address(this)), "Pool: contract is disabled");

        // update pool collected amount
        collectedAmount = collectedAmount.add(msg.value);

        // mint new deposit tokens
        swdToken.mint(msg.sender, msg.value);
    }

    /**
    * @dev Function for withdrawing deposits.
    * The deposit can only be withdrawn if there is less than `validatorDepositAmount` in the pool.
    * @param _amount - amount to withdraw.
    */
    function withdrawDeposit(uint256 _amount) external {
        require(collectedAmount.mod(settings.validatorDepositAmount()) >= _amount, "Pool: insufficient collected amount");
        require(_amount > 0 && _amount.mod(settings.minDepositUnit()) == 0, "Pool: invalid withdrawal amount");
        require(!settings.pausedContracts(address(this)), "Pool: contract is disabled");

        // burn sender deposit tokens
        swdToken.burn(msg.sender, _amount);

        // update pool collected amount
        collectedAmount = collectedAmount.sub(_amount);

        // transfer ETH to the tokens owner
        msg.sender.sendValue(_amount);
    }

    /**
    * @dev Function for registering new validators.
    * @param _pubKey - BLS public key of the validator, generated by the operator.
    * @param _signature - BLS signature of the validator, generated by the operator.
    * @param _depositDataRoot - hash tree root of the deposit data, generated by the operator.
    */
    function registerValidator(bytes calldata _pubKey, bytes calldata _signature, bytes32 _depositDataRoot) external {
        require(operators.isOperator(msg.sender), "Pool: permission denied");

        // reduce pool collected amount
        uint256 depositAmount = settings.validatorDepositAmount();
        require(collectedAmount >= depositAmount, "Pool: insufficient collected amount");
        collectedAmount = collectedAmount.sub(depositAmount);

        // register validator
        validators.register(_pubKey, poolId);
        validatorRegistration.deposit{value : depositAmount}(
            _pubKey,
            settings.withdrawalCredentials(),
            _signature,
            _depositDataRoot
        );
    }
}
