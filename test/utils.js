const fs = require('fs');
const { expectEvent, constants } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const { BN, ether, balance } = require('@openzeppelin/test-helpers');
const { initialSettings } = require('../deployments/settings');

const Validators = artifacts.require('Validators');

function getDepositAmount({
  min = new BN(initialSettings.minDepositUnit),
  max = ether('320'),
} = {}) {
  let randomDeposit = ether(Math.random().toFixed(8))
    .mul(max.sub(min))
    .div(ether('1'))
    .add(min);

  return randomDeposit.sub(
    randomDeposit.mod(new BN(initialSettings.minDepositUnit))
  );
}

function removeNetworkFile(network) {
  if (fs.existsSync(`.openzeppelin/${network}.json`)) {
    fs.unlinkSync(`.openzeppelin/${network}.json`);
  }
}

async function checkSolo({
  solos,
  soloId,
  withdrawalCredentials = constants.ZERO_BYTES32,
  amount = new BN(0),
} = {}) {
  let solo = await solos.solos(soloId);
  expect(solo.amount).to.bignumber.equal(amount);
  expect(solo.withdrawalCredentials).equal(withdrawalCredentials);
}

async function checkCollectorBalance(
  collectorContract,
  correctBalance = new BN(0)
) {
  expect(
    await balance.current(collectorContract.address)
  ).to.be.bignumber.equal(correctBalance);
}

async function checkPoolCollectedAmount(
  poolContract,
  correctAmount = new BN(0)
) {
  let collectedAmount = await poolContract.collectedAmount();
  expect(collectedAmount).to.be.bignumber.equal(correctAmount);
}

async function checkSoloDepositAdded({
  receipt,
  solos,
  sender,
  withdrawalCredentials,
  addedAmount,
  totalAmount,
}) {
  let soloId = web3.utils.soliditySha3(
    solos.address,
    sender,
    withdrawalCredentials
  );

  expectEvent(receipt, 'DepositAdded', {
    soloId,
    sender: sender,
    amount: addedAmount,
    withdrawalCredentials,
  });

  await checkSolo({
    solos,
    soloId,
    withdrawalCredentials,
    amount: totalAmount,
  });
}

async function checkValidatorRegistered({
  vrc,
  transaction,
  pubKey,
  entityId,
  signature,
  withdrawalCredentials = initialSettings.withdrawalCredentials,
  validatorDepositAmount = new BN(initialSettings.validatorDepositAmount),
}) {
  // Check VRC record created
  await expectEvent.inTransaction(transaction, vrc, 'DepositEvent', {
    pubkey: pubKey,
    withdrawal_credentials: withdrawalCredentials,
    amount: web3.utils.bytesToHex(
      new BN(web3.utils.fromWei(validatorDepositAmount, 'gwei')).toArray(
        'le',
        8
      )
    ),
    signature: signature,
  });

  // Check ValidatorRegistered log emitted
  await expectEvent.inTransaction(
    transaction,
    Validators,
    'ValidatorRegistered',
    {
      pubKey: pubKey,
      entityId,
      price: initialSettings.validatorPrice,
    }
  );
}

async function checkSWDToken({
  swdToken,
  totalSupply,
  account,
  deposit,
  balance,
}) {
  if (totalSupply != null) {
    expect(await swdToken.totalSupply()).to.be.bignumber.equal(totalSupply);
  }

  if (account != null && deposit != null) {
    expect(await swdToken.depositOf(account)).to.be.bignumber.equal(deposit);
  }

  if (account != null && balance != null) {
    expect(await swdToken.balanceOf(account)).to.be.bignumber.equal(balance);
  }
}

async function checkSWRToken({
  swrToken,
  totalSupply,
  account,
  reward,
  balance,
}) {
  if (totalSupply != null) {
    expect(await swrToken.totalSupply()).to.be.bignumber.equal(totalSupply);
  }

  if (account != null && reward != null) {
    expect(await swrToken.rewardOf(account)).to.be.bignumber.equal(reward);
  }

  if (account != null && balance != null) {
    expect(await swrToken.balanceOf(account)).to.be.bignumber.equal(balance);
  }
}

module.exports = {
  checkCollectorBalance,
  checkSolo,
  checkSoloDepositAdded,
  checkValidatorRegistered,
  removeNetworkFile,
  getDepositAmount,
  checkPoolCollectedAmount,
  checkSWDToken,
  checkSWRToken,
};
